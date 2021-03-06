{-# LANGUAGE BangPatterns #-}

module GlitchMon.GlitchMonTime
( runGlitchMonTime
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
import qualified Data.Vector.Storable as V
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

import qualified GlitchMon.GlitchParam as GP
import GlitchMon.PipelineFunction
import GlitchMon.Data (TrigParam (..))
import GlitchMon.RegisterGlitchEvent (registGlitchEvent2DB)
import GlitchMon.Signature
import GlitchMon.DataConditioning
import GlitchMon.EventTriggerGeneration
import GlitchMon.ParameterEstimation
import GlitchMon.RegisterEventtoDB

import System.IO (hFlush, stdout)


-- for debug --
import qualified HasKAL.PlotUtils.HROOT.PlotGraph3D as H3
import qualified HasKAL.PlotUtils.HROOT.PlotGraph as H
import HasKAL.SpectrumUtils.SpectrumUtils (gwOnesidedPSDWaveData, gwOnesidedMedianAveragedPSDWaveData, gwspectrogramWaveData)
import Control.DeepSeq (deepseq) 

{--------------------
- Main Functions    -
--------------------}
type Channel = String


runGlitchMonTime :: GP.GlitchParam
                 -> Channel
                 -> FilePath
                 -> IO()
runGlitchMonTime param chname cachefile = source param cachefile $$ sink param chname


source :: GP.GlitchParam
       -> FilePath
       -> Source IO (Int,Int)
source param f =
  let gpslist = selectSegment (GP.segmentLength param) f
   in CL.sourceList gpslist


sink :: GP.GlitchParam
     -> Channel
     -> Sink (Int,Int) IO ()
sink param chname = do
  c <- await
  case c of
    Nothing -> return ()
    Just (gps, dt) -> do
      liftIO $ print "============================================================" >> hFlush stdout
      liftIO $ print ["analyzing data of GPS"++show gps++"-"++show dt++"."] >> hFlush stdout
      let n = 0
      maybewave <- liftIO $ kagraWaveDataGet gps dt chname
      case maybewave of
        Nothing -> do liftIO $ print "Missing data found. writing GPS info in missingData.lst."
                      liftIO $ appendFile "./missingData.lst" $ show gps ++ " " ++ show dt
                      sink param chname
        Just wave -> do let param' = GP.updateGlitchParam'channel param chname
                            fs = GP.samplingFrequency param'
                            fsorig = samplingFrequency wave
                        if (fs /= fsorig)
                          then do liftIO $ print "start downsampling" >> hFlush stdout
                                  let wave' = downsampleWaveData fs wave
                                      wv = gwdata wave'
                                  --liftIO $ print $ "["++show (wv V.!0)++", "++show (wv V.!1)++", "
                                  --  ++show (wv V.!2)++", "++show (wv V.!3)++"...]"
                                  liftIO $ wv `deepseq` return ()
                                  let dataGps = (fst (startGPSTime wave'),n)
                                      param'2 = GP.updateGlitchParam'cgps param' (Just dataGps)
                                  case GP.DS `elem` GP.debugmode param of 
                                       True -> do
                                        let dir = GP.debugDir param 
--                                        liftIO $ H.plot H.Linear
--                                                        H.Line
--                                                            1
--                                                        H.RED
--                                                       ("time","amplitude")
--                                                            0.05
--                                                        "whitened data"
--                                                        "production/timeseries_DS.png"
--                                                            ((16.05,16.2),(0,0))
--                                                        $ zip [0,1/4096..] (NL.toList $ gwdata wave')
                                        liftIO $ H.plotV H.LogXY
                                                         H.Line
                                                             1
                                                         H.RED
                                                         ("frequency [Hz]","ASD [Hz^-1/2]")
                                                              0.05
                                                         "downsampled data spectrum"
                                                         (dir++"/spectrum_DS.png")
                                                             ((0,0),(0,0))
                                                         $ gwOnesidedPSDWaveData 0.2 wave'
                                        liftIO $ H.plotV H.LogXY
                                                         H.Line
                                                             1
                                                         H.RED
                                                         ("frequency [Hz]","ASD [Hz^-1/2]")
                                                              0.05
                                                         "downsampeld data median averaged spectrum"
                                                         (dir++"/spectrumMA_DS.png")
                                                             ((0,0),(0,0))
                                                         $ gwOnesidedMedianAveragedPSDWaveData 0.2 wave'

                                       _ -> liftIO $ Prelude.return ()
                                  s <- liftIO $ fileRun wave' param'2
                                  -- [TEST] parameter reseted
                                  sink param chname
                          else do let dataGps = (fst (startGPSTime wave),n)
                                      param'2 = GP.updateGlitchParam'cgps param' (Just dataGps)
                                  s <- liftIO $ fileRun wave param'2
                                  -- [TEST] parameter reseted
                                  sink param chname


fileRun w param = do
   let dataGps = deformatGPS $ fromJust $ GP.cgps param
       traindatlen = GP.traindatlen param ::Double
       fs = GP.samplingFrequency param ::Double
       param' = GP.updateGlitchParam'refwave param (takeWaveData (floor (traindatlen*fs)) w)
   liftIO $ glitchMon param' w


timeRun :: Channel
        -> WaveData
        -> GP.GlitchParam
        -> IO GP.GlitchParam
timeRun chname w param = do
  let maybegps = GP.cgps param
  case maybegps of
    Nothing -> do
      error "cgps not found. something wrong. please check it out."
    Just strtGps -> do
          let cdfp = GP.cdfparameter param
              seglen = fromIntegral $ GP.segmentLength param
          !maybecdlist <- liftIO $ 
            cleanDataFinder cdfp chname (formatGPS (deformatGPS strtGps + seglen), seglen)
          case maybecdlist of
            Nothing -> do 
              liftIO $ print "Warning: no clean data in the given gps interval."
              liftIO $ print " Instead,last part of the segment will be used."
              let traindatlen = GP.traindatlen param
                  startcgps = fromIntegral $ truncate $(deformatGPS strtGps) 
                    + seglen - traindatlen
                  param'2 = GP.updateGlitchParam'cgps param (Just (formatGPS startcgps))
              maybew <- liftIO $ kagraWaveDataGet (truncate startcgps) (floor traindatlen) chname
              case maybew of
                Just x -> do 
                  let fs = samplingFrequency w
                      fsorig = samplingFrequency x
                  if (fs /= fsorig)
                    then do
                      let x' = downsampleWaveData fs x
                          param'3 = GP.updateGlitchParam'refwave param'2 x'
                      glitchMon param'3 w
                    else do 
                      let param'3 = GP.updateGlitchParam'refwave param'2 x
                      glitchMon param'3 w
                Nothing -> error "something wrong in clean data finder"
            Just cdlist -> do
             let cleandata = [(t,b)|(t,b)<-cdlist,b==True]
             case cleandata of
              [] -> do
                liftIO $ print "Warning: all data is not clean in the given gps interval." 
                liftIO $ print "Instead,last part of the segment will be used."
                let traindatlen = GP.traindatlen param
                    startcgps = fromIntegral $ truncate $(deformatGPS strtGps)
                      + seglen - traindatlen
                    param'2 = GP.updateGlitchParam'cgps param (Just (formatGPS startcgps))
                maybew <- liftIO $ kagraWaveDataGet (truncate startcgps) (floor traindatlen) chname
                case maybew of
                  Just x -> do
                    let fs = samplingFrequency w
                        fsorig = samplingFrequency x
                    if (fs /= fsorig)
                      then do
                        let x' = downsampleWaveData fs x
                            param'3 = GP.updateGlitchParam'refwave param'2 x'
                        glitchMon param'3 w
                      else do
                        let param'3 = GP.updateGlitchParam'refwave param'2 x
                        glitchMon param'3 w
                  Nothing -> error "something wrong in clean data finder"
              _ -> do
                let cdgps' = fst . last $ cleandata
                    cdgps = fst cdgps'
                    param'2 = GP.updateGlitchParam'cgps param (Just cdgps')
                    traindatlen = GP.traindatlen param
                maybew <- liftIO $ kagraWaveDataGet cdgps (floor traindatlen) chname
                case maybew of 
                  Just x -> do
                    let fs = samplingFrequency w
                        fsorig = samplingFrequency x
                    if (fs /= fsorig)
                      then do
                        let x' = downsampleWaveData fs x
                            param'3 = GP.updateGlitchParam'refwave param'2 x'
                        glitchMon param'3 w
                      else do
                        let param'3 = GP.updateGlitchParam'refwave param'2 x
                        glitchMon param'3 w
                  Nothing -> error "no data found!"


glitchMon :: GP.GlitchParam
          -> WaveData
          -> IO GP.GlitchParam
glitchMon param w =
  runStateT (part'DataConditioning w) param >>= \(a, s) -> 
    runStateT (part'EventTriggerGeneration a) s >>= \(a', s') ->
      runStateT (part'ParameterEstimation a') s' >>= \(a'', s'') ->
        case a'' of
          Just t -> do part'RegisterEventtoDB t 
                       print "finishing glitchmon" >> return s''
          Nothing -> do print "No event from glitchmon"
                        return s''


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

toTuple :: [String] 
        -> (Int,Int)
toTuple x = (read (head x) :: Int,read (x!!1) :: Int)

