{-# LANGUAGE BangPatterns #-}

module HasKAL.MonitorUtils.GlitchMon.GlitchMon
( runGlitchMon
, eventDisplay
, eventDisplayF
)
where


import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.MVar (MVar, newEmptyMVar, putMVar, takeMVar)
import Control.Monad.Trans.Resource (runResourceT)
import Control.Monad ((>>=), mapM_)
import Control.Monad.State ( StateT
                           , runStateT
                           , execStateT
                           , get
                           , put
                           , liftIO
                           )
import Data.Conduit ( bracketP
                    , yield
                    , await
                    , ($$)
                    , Source
                    , Sink
                    , Conduit
                    )
import qualified Data.Conduit.List as CL
import Data.Int (Int32)
import Data.List (nub, foldl', elemIndices, maximum, minimum, lookup)
import Data.Maybe (fromJust)
import qualified Data.Set as Set
import Data.Text ( pack )
import Filesystem.Path (extension, (</>))
import Filesystem.Path.CurrentOS (decodeString, encodeString)
import HasKAL.DataBaseUtils.FrameFull.Data
import HasKAL.DataBaseUtils.FrameFull.Function (cleanDataFinder, kagraWaveDataGet)
import HasKAL.DetectorUtils.Detector(Detector(..))
import HasKAL.FrameUtils.FrameUtils (getGPSTime)
import HasKAL.FrameUtils.Function (readFrameWaveData')
import HasKAL.MathUtils.FFTW (dct2d, idct2d)
import HasKAL.SpectrumUtils.Function (updateMatrixElement, updateSpectrogramSpec)
import HasKAL.SpectrumUtils.Signature (Spectrum, Spectrogram)
import HasKAL.SpectrumUtils.SpectrumUtils (gwpsdV, gwOnesidedPSDV)
import HasKAL.SignalProcessingUtils.LinearPrediction (lpefCoeffV, whiteningWaveData)
import HasKAL.SignalProcessingUtils.Resampling (downsampleWaveData)
import HasKAL.TimeUtils.Function (formatGPS, deformatGPS)
import HasKAL.TimeUtils.GPSfunction (getCurrentGps)
import HasKAL.TimeUtils.Signature (GPSTIME)
import qualified HasKAL.WaveUtils.Data as WD
import HasKAL.WaveUtils.Data hiding (detector, mean)
import HasKAL.WaveUtils.Signature
import Numeric.LinearAlgebra as NL
import System.Directory (doesDirectoryExist, getDirectoryContents)
import System.FilePath.Posix (takeExtension, takeFileName)
import System.FSNotify ( Debounce(..)
                       , Event(..)
                       , WatchConfig(..)
                       , withManagerConf
                       , watchDir
                       , eventPath
                       )
import System.IO (hFlush, stdout)
import System.IO.Unsafe (unsafePerformIO)
import System.Timeout.Lifted (timeout)

import qualified HasKAL.MonitorUtils.GlitchMon.GlitchParam as GP
import HasKAL.MonitorUtils.GlitchMon.PipelineFunction
import HasKAL.MonitorUtils.GlitchMon.Data (TrigParam (..))
import HasKAL.MonitorUtils.GlitchMon.RegisterGlitchEvent (registGlitchEvent2DB)
import HasKAL.MonitorUtils.GlitchMon.Signature
import HasKAL.MonitorUtils.GlitchMon.DataConditioning
import HasKAL.MonitorUtils.GlitchMon.EventTriggerGeneration
import HasKAL.MonitorUtils.GlitchMon.ParameterEstimation
import HasKAL.MonitorUtils.GlitchMon.RegisterEventtoDB


{--------------------
- Main Functions    -
--------------------}


runGlitchMon watchdir param chname = do
  gps <- liftIO getCurrentGps
  let cdir = getCurrentDir gps
  source param chname watchdir cdir

source :: GP.GlitchParam
       -> String
       -> FilePath
       -> FilePath
       -> IO FilePath
source param chname topDir watchdir = do
  gps <- liftIO getCurrentGps
  let ndir = getNextDir gps
      ndirabs = getAbsPath topDir ndir
--  liftIO $ putStrLn ("start watching "++watchdir++".") >> hFlush stdout
  x <- doesDirectoryExist (getAbsPath topDir watchdir)
  case x of
    False -> do threadDelay 1000000
                gps2 <- getCurrentGps
                let cdir2 = getCurrentDir gps2
                source param chname topDir cdir2    
    True -> do !maybeT <- timeout (breakTime 20) $ watchFile topDir watchdir $$ sink param chname
               case maybeT of
                Nothing -> do putStrLn ("Watching Timeout: going to next dir "++ndir++" to watch.") >> hFlush stdout
                              gowatch ndirabs (source param chname topDir ndir) (source param chname topDir)
                Just _  -> do putStrLn ("going to next dir "++ndir++" to watch.") >> hFlush stdout
                              gowatch ndirabs (source param chname topDir ndir) (source param chname topDir)


watchFile :: FilePath
          -> FilePath
          -> Source IO FilePath
watchFile topDir watchdir = do
  let absPath = getAbsPath topDir watchdir
      predicate event' = case event' of
        Added path _ -> chekingFile path
        _            -> False
      config = WatchConfig
                 { confDebounce = NoDebounce
                 , confPollInterval = 1000000 -- 1seconds
                 , confUsePolling = True
                 }
  gwfname <- liftIO $ withManagerConf config $ \manager -> do
    fname <- newEmptyMVar
    watchDir manager absPath predicate
      $ \event -> case event of
        Added path _ -> putMVar fname path
    takeMVar fname
  yield gwfname >> watchFile topDir watchdir


sink :: GP.GlitchParam
     -> String
     -> Sink String IO ()
sink param chname = do
  c <- await
  case c of
    Nothing -> sink param chname
    Just fname -> do
      maybegps <- liftIO $ getGPSTime fname
      case maybegps of
        Nothing -> sink param chname
        Just (s, n, dt') -> do
          maybewave <- liftIO $ readFrameWaveData' General chname fname
          case maybewave of
            Nothing -> sink param chname
            Just wave -> do let param' = GP.updateGlitchParam'channel param chname
                                fs = GP.samplingFrequency param'
                                fsorig = samplingFrequency wave
                            if (fs /= fsorig)
                              then do let wave' = downsampleWaveData fs wave
                                      go wave' param'
                              else go wave param'
  where 
    go w param' = do
      let maybegps = GP.cgps param'
      case maybegps of
        Nothing -> do
          currGps' <- liftIO $ getCurrentGps
          let currGps = formatGPS (read currGps')
              param'2 = GP.updateGlitchParam'cgps param' (Just currGps)
              chunklen = GP.chunklen param'2
              fs = GP.samplingFrequency param'2
              param'3 = GP.updateGlitchParam'refwave param'2 (takeWaveData (floor (chunklen*fs)) w)
          s <- liftIO $ glitchMon param'3 w
          sink s chname
        Just gpsold -> do
          currGps' <- liftIO $ getCurrentGps
          let currGps = formatGPS (read currGps')
              difft = (deformatGPS currGps) - (deformatGPS gpsold)
              cdfIntvl = GP.cdfInterval param' 
          case difft >= (fromIntegral cdfIntvl) of  -- ^ clean data update every 10 minutes
            True -> do
              let cdfp = GP.cdfparameter param'
              maybecdlist <- liftIO $ cleanDataFinder cdfp chname (currGps, 600.0)
              case maybecdlist of
                Nothing -> error "no clean data in the given gps interval"
                Just cdlist -> do
                  let cdgps' = fst . last $ [(t,b)|(t,b)<-cdlist,b==True]
                      cdgps = fst cdgps'
                      param'2 = GP.updateGlitchParam'cgps param' (Just cdgps')
                      chunklen = GP.chunklen param'2
                      fs = GP.samplingFrequency param'2
                  maybew <- liftIO $ kagraWaveDataGet cdgps (floor (chunklen*fs)) chname (WD.detector w)
                  let param'3 = GP.updateGlitchParam'refwave param'2 (fromJust maybew)
                  s <- liftIO $ glitchMon param'3 w
                  sink s chname
            False -> do
              s <- liftIO $ glitchMon param' w
              sink s chname


glitchMon :: GP.GlitchParam
          -> WaveData
          -> IO GP.GlitchParam
glitchMon param w =
  runStateT (part'DataConditioning w) param >>= \(a, s) ->
    runStateT (part'EventTriggerGeneration a) s >>= \(a', s') ->
      runStateT (part'ParameterEstimation a') s' >>= \(a'', s'') ->
         case a'' of
           Just t -> part'RegisterEventtoDB t >> return s''
           Nothing -> return s''


eventDisplay :: GP.GlitchParam
             -> WaveData
             -> IO (Maybe [(TrigParam,ID)], GP.GlitchParam, (Spectrogram, [[(Tile,ID)]]))
eventDisplay param w =
  runStateT (part'DataConditioning w) param >>= \(a, s) ->
    runStateT (part'EventTriggerGeneration a) s >>= \(a', s') ->
       do (trigparam, param') <- runStateT (part'ParameterEstimation a') s'
          return (trigparam, param',a')


eventDisplayF :: GP.GlitchParam
              -> FilePath
              -> String
              -> IO (Maybe [(TrigParam,ID)], GP.GlitchParam, (Spectrogram, [[(Tile,ID)]]))
eventDisplayF param fname chname = do
  maybegps <- getGPSTime fname
  case maybegps of
    Nothing -> error "file broken"
    Just (s, n, dt') -> do
      maybewave <- readFrameWaveData' General chname fname
      case maybewave of
        Nothing -> error "file broken"
        Just w -> runStateT (part'DataConditioning w) param >>= \(a, s) ->
                    runStateT (part'EventTriggerGeneration a) s >>= \(a', s') ->
                       do (trigparam, param') <- runStateT (part'ParameterEstimation a') s'
                          return (trigparam, param',a')


{- internal functions -}

chekingFile path = takeExtension path `elem` [".gwf"] && head (takeFileName path) /= '.'


getAbsPath dir1 dir2 = encodeString $ decodeString dir1 </> decodeString dir2


breakTime margin = unsafePerformIO $ do
  dt <- getCurrentGps >>= \gps-> return $ timeToNextDir gps
  return $ (dt+margin)*1000000


getCurrentDir :: String -> String
getCurrentDir gps = take 5 gps


getNextDir :: String -> String
getNextDir gps =
  let gpsHead' = take 5 gps
      gpsHead = read gpsHead' :: Int
   in take 5 $ show (gpsHead+1)


timeToNextDir :: String -> Int
timeToNextDir gps =
  let currentGps = read gps :: Int
      (gpsHead', gpsTail') = (take 5 gps, drop 5 gps)
      gpsHead = read gpsHead' :: Int
      gpsTail = replicate (length gpsTail') '0'
      nextGps = read (show (gpsHead+1) ++ gpsTail) :: Int
   in nextGps - currentGps


gowatch dname f g =  do b <- liftIO $ doesDirectoryExist dname
                        case b of
                          False -> do gps <- liftIO getCurrentGps
                                      let cdir' = getCurrentDir gps
                                          cdir  = drop (length dname -5) dname
                                      case cdir' > cdir of
                                        True -> do let dname' = (take (length dname -5) dname)++cdir'
                                                   liftIO $ threadDelay 1000000
                                                   gowatch dname' (g cdir') g
                                        False -> do liftIO $ threadDelay 1000000
                                                    gowatch dname f g
                          True  -> f


