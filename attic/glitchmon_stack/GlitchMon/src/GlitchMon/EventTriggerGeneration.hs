
{-# LANGUAGE BangPatterns #-}

module GlitchMon.EventTriggerGeneration
( part'EventTriggerGeneration
) where



import Control.Monad.State (StateT, runStateT, execStateT, get, put, liftIO)
import Data.List (nub,  foldl',  elemIndices,  maximum,  minimum,  lookup, sortBy)
import Data.Packed.Matrix (buildMatrix)
import qualified Data.Set as Set
import HasKAL.MathUtils.FFTW (dct2d, idct2d)
import HasKAL.SignalProcessingUtils.Interpolation
import HasKAL.SpectrumUtils.Function (updateMatrixElement,  updateSpectrogramSpec)
import HasKAL.SpectrumUtils.Signature (Spectrum,  Spectrogram)
import HasKAL.SpectrumUtils.SpectrumUtils (gwpsdV, gwOnesidedPSDV, gwOnesidedMedianAveragedPSDV)
import HasKAL.TimeUtils.Function (formatGPS,  deformatGPS)
import HasKAL.WaveUtils.Data hiding (detector, mean)
import Numeric.LinearAlgebra as NL
import qualified GlitchMon.GlitchParam as GP
import GlitchMon.PipelineFunction
import GlitchMon.Signature
import qualified HasKAL.PlotUtils.HROOT.PlotGraph3D as H3
import qualified HasKAL.PlotUtils.HROOT.PlotGraph as H
import System.IO (hFlush, stdout)

import Control.DeepSeq (deepseq)


part'EventTriggerGeneration :: WaveData
                            -> StateT GP.GlitchParam IO (Spectrogram, [[(Tile,ID)]])
part'EventTriggerGeneration wave = do
  liftIO $ print "start event trigger generation" >> hFlush stdout
  param <- get
  (a, s) <- liftIO $ runStateT (section'TimeFrequencyExpression wave) param
  section'Clustering a


section'TimeFrequencyExpression :: WaveData
                                -> StateT GP.GlitchParam IO Spectrogram
section'TimeFrequencyExpression whnWaveData = do
  liftIO $ print "-- start time-frequency expansion" >> hFlush stdout
  param <- get
  let wmethod   = GP.whnMethod param
      dir = GP.debugDir param
  case wmethod of
    GP.TimeDomain -> do
      let refpsd = GP.refpsd param
          fs = samplingFrequency whnWaveData
          nfreq = floor $ GP.nfrequency param * fs
          nfreq2 = nfreq `div` 2
          ntimeSlide = floor $ GP.ntimeSlide param * fs
          ntime = ((NL.dim $ gwdata whnWaveData) - nfreq) `div` ntimeSlide
          snrMatF = scale (fs/fromIntegral nfreq) $ fromList [0.0, 1.0..fromIntegral nfreq2-1]
          snrMatT = scale (fromIntegral ntimeSlide/fs) $ fromList [0.0, 1.0..fromIntegral ntime -1]
          snrMatT' = mapVector (+deformatGPS (startGPSTime whnWaveData)) snrMatT
          snrMatP = NL.fliprl $ NL.trans $ NL.flipud $ 
                      (ntime><nfreq2) $ concatMap (take nfreq2 . toList . calcSpec) [0..ntime-1]
            where 
              calcSpec tindx = NL.zipVectorWith (/) 
                (snd $ gwOnesidedPSDV (NL.subVector (ntimeSlide*tindx) nfreq (gwdata whnWaveData)) nfreq fs)
                (snd $ refpsd)
          out = (snrMatT', snrMatF, snrMatP)
      case GP.TF `elem` GP.debugmode param of
        True -> do
          liftIO $ H3.spectrogramM H3.LogY
                                   H3.COLZ
                                   "mag"
                                   "pixelSNR spectrogram"
                                   (dir++"/pixelSNR_spectrogram_WhnTD.png")
                                       ((0, 0), (20, 400))
                                   out
        _ -> liftIO $ Prelude.return () 
      out `deepseq` return out
    GP.FrequencyDomain -> do
      --let refpsd = gwOnesidedMedianAveragedPSDV (gwdata whnWaveData) nfreq fs
      let refpsd = gwOnesidedPSDV (gwdata whnWaveData) nfreq fs
          fs = samplingFrequency whnWaveData
          nfreq = floor $ GP.nfrequency param * fs
          nfreq2 = nfreq `div` 2
          ntimeSlide = floor $ GP.ntimeSlide param * fs
          ntime = ((NL.dim $ gwdata whnWaveData) - nfreq) `div` ntimeSlide
          snrMatF = scale (fs/fromIntegral nfreq) $ fromList [0.0, 1.0..fromIntegral nfreq2-1]
          snrMatT = scale (fromIntegral ntimeSlide/fs) $ fromList [0.0, 1.0..fromIntegral ntime -1]
          snrMatT' = mapVector (+deformatGPS (startGPSTime whnWaveData)) snrMatT
          snrMatP = NL.fliprl $ NL.trans $ NL.flipud $ 
                      (ntime><nfreq2) $ concatMap (take nfreq2 . toList . calcSpec) [0..ntime-1]
            where 
              calcSpec tindx = NL.zipVectorWith (/) 
                (snd $ gwOnesidedPSDV (NL.subVector (ntimeSlide*tindx) nfreq (gwdata whnWaveData)) nfreq fs)
                (snd $ refpsd)
          out = (snrMatT', snrMatF, snrMatP)
      case GP.TF `elem` GP.debugmode param of
        True -> do
          liftIO $ H3.spectrogramM H3.LogY
                                   H3.COLZ
                                   "mag"
                                   "pixelSNR spectrogram"
                                   (dir++"/pixelSNR_spectrogram_WhnFD.png")
                                       ((0, 0), (20, 400))
                                   out
        _ -> liftIO $ Prelude.return () 
      out `deepseq` return out


section'Clustering :: Spectrogram
                   -> StateT GP.GlitchParam IO (Spectrogram,[[(Tile,ID)]])
section'Clustering (snrMatT, snrMatF, snrMatP') = do
  liftIO $ print "-- start seedless clustering" >> hFlush stdout
  param <- get
  let n = GP.nNeighbor param
      l = NL.toList $ NL.flatten snrMatP'
      l' = (NL.dim snrMatF><NL.dim snrMatT) l
      dcted' = dct2d l'
      ncol = cols l'
      nrow = rows l'
      cutT = floor $ fromIntegral ncol * GP.cutoffFractionTFT param
      cutF = floor $ fromIntegral nrow * GP.cutoffFractionTFF param
      cfun = GP.celement param
      minN = GP.minimumClusterNum param
      m1 = ((nrow-cutF)><(ncol-cutT)) $ replicate ((nrow-cutF)*(ncol-cutT)) 1.0
      mc0 = (nrow><cutT) $ replicate (nrow*cutT) 0.0
      mr0 = (cutF><(ncol-cutT)) $ replicate (cutF*(ncol-cutT)) 0.0
      qM = NL.fromBlocks [[NL.fromBlocks [[m1],[mr0]],mc0]]
  let dcted = NL.mul dcted' qM
--  liftIO $ print "evaluating dcted"  >> hFlush stdout
  dcted `deepseq` Prelude.return ()
  let snrMatP = idct2d dcted
--  liftIO $ print "evaluating snrMatP" >> hFlush stdout
  snrMatP `deepseq` Prelude.return ()
  let thresIndex = head $ NL.find (>=GP.cutoffFreq param) snrMatF
--  liftIO $ print "evaluating thresIndex" >> hFlush stdout
  thresIndex `deepseq` Prelude.return ()
  let snrMat = ( snrMatT
               , NL.subVector thresIndex (nrow-thresIndex-1) snrMatF
               , NL.dropRows (thresIndex+1) snrMatP
                 )
--  liftIO $ print "evaluating snrMat" >> hFlush stdout
  snrMat `deepseq` Prelude.return ()
  let (tt,ff,mg) = snrMat
      thrsed' = NL.find (>=GP.clusterThres param) mg
      cmg = cols mg
      rmg = rows mg
  thrsed <- liftIO $ case length thrsed' >= GP.maxNtrigg param of
    True -> do 
      print "---- too many islands detected. top maxNtrigg islands will be selected."
      let mg' = zip (NL.toList . NL.flatten $ mg) [0,1..]
          ind = snd . unzip . take (GP.maxNtrigg param) . reverse . sortBy (\ x y -> compare (fst x) (fst y)) $ mg'
      return $ map (vectorInd2MatrixInd_row rmg cmg) ind
    False-> 
      return thrsed'

  let survivor = nub' $ excludeOnePixelIsland cfun n thrsed
  liftIO $ print "---- evaluating survivor" >> hFlush stdout
  survivor `deepseq` Prelude.return ()
  let survivorwID = taggingIsland cfun minN survivor
  liftIO $ print "---- evaluating survivorwID" >> hFlush stdout
  survivorwID `deepseq` Prelude.return ()
  let zeroMatrix = (nrow><ncol) $ replicate (ncol*nrow) 0.0
--  liftIO $ print "evaluating zeroMatrix" >> hFlush stdout
  let survivorValues = map (\x->mg@@>x) survivor
--  liftIO $ print "evaluating survivorValues" >> hFlush stdout
  survivorValues `deepseq` Prelude.return ()
  let newM = updateSpectrogramSpec snrMat
        $ updateMatrixElement zeroMatrix survivor survivorValues
  liftIO $ print "---- evaluating newM" >> hFlush stdout
  newM `deepseq` Prelude.return ()

  case GP.CL `elem` GP.debugmode param of
    True -> do
--      liftIO $ print ncol
      liftIO $ H3.spectrogramM H3.LogY
                               H3.COLZ
                               "mag"
                               "clustered PixelSNR spectrogram"
                               "production/cluster_spectrogram.png"
                               ((0, 0), (20, 400))
                               newM
--      liftIO $ print "clustered pixels :"
--      liftIO $ print survivorwID          
    _ -> liftIO $ Prelude.return () 

  case length survivorwID of 
    0 -> do liftIO $ print "# of detected islands is" >> hFlush stdout
            liftIO $ print "0" >> hFlush stdout
    _ -> do liftIO $ print "# of detected islands is" >> hFlush stdout
            liftIO $ print $ (snd . last . last $ survivorwID)
  let out_clustering = (newM, survivorwID)
  out_clustering `deepseq` return out_clustering


quantizingMatrix :: Int 
                 -> Int 
                 -> ((Int,Int)->Double) 
                 -> Matrix Double
quantizingMatrix r c fun = buildMatrix r c fun


vectorInd2MatrixInd_row r c m = (a, b)
  where
    a | m `mod` c == 0 = m `div` c -1
      | otherwise      = m `div` c
    b | m `mod` c == 0 = c-1
      | otherwise      = m `mod` c - 1

-- | O (nlog n) nub 
-- | lent from http://d.hatena.ne.jp/jeneshicc/20090908/1252413541
nub' :: (Ord a) => [a] -> [a]
nub' l = nub'' l Set.empty
   where nub'' [] _ = []
         nub'' (x:xs) s
           | x `Set.member` s = nub'' xs s
           | otherwise    = x : nub'' xs (x `Set.insert` s)

{--------------------
- Helper Functions  -
--------------------}


mean :: Floating a => [a] -> a
mean x = fst $ foldl' (\(!m,  !n) x -> (m+(x-m)/(n+1), n+1)) (0, 0) x


var :: (Fractional a, Floating a) => [a] -> a
var xs = Prelude.sum (map (\x -> (x - mu)^(2::Int)) xs)  / (n - 1)
    where mu = mean xs
          n = fromIntegral $ length xs

std :: (RealFloat a) => [a] -> a
std x = sqrt $ var x


