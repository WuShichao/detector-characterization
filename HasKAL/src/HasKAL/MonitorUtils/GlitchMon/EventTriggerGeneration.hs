
{-# LANGUAGE BangPatterns #-}

module HasKAL.MonitorUtils.GlitchMon.EventTriggerGeneration
( part'EventTriggerGeneration
, section'TimeFrequencyExpression
, section'Clustering
) where



import Control.Monad.State (StateT, runStateT, execStateT, get, put, liftIO)
import Data.List (nub,  foldl',  elemIndices,  maximum,  minimum,  lookup, sortBy)
--import qualified Data.Matrix as M
--import Data.Packed.Matrix (buildMatrix)
import qualified Data.Set as Set
import qualified Data.Vector.Storable as V
import HasKAL.MathUtils.FFTW (dct2d, idct2d)
import HasKAL.SignalProcessingUtils.Interpolation
import HasKAL.SpectrumUtils.Function (updateMatrixElement,  updateSpectrogramSpec)
import HasKAL.SpectrumUtils.Signature (Spectrum,  Spectrogram)
import HasKAL.SpectrumUtils.SpectrumUtils (gwpsdV, gwOnesidedPSDV, gwOnesidedMedianAveragedPSDV)
import HasKAL.TimeUtils.Function (formatGPS,  deformatGPS)
import HasKAL.WaveUtils.Data hiding (detector, mean)
import Numeric.LinearAlgebra as NL
import Numeric.LinearAlgebra.Data --(saveMatrix, cols, rows)
import qualified HasKAL.MonitorUtils.GlitchMon.GlitchParam as GP
import HasKAL.MonitorUtils.GlitchMon.PipelineFunction
import HasKAL.MonitorUtils.GlitchMon.Signature
import qualified HasKAL.PlotUtils.HROOT.PlotGraph3D as H3
import qualified HasKAL.PlotUtils.HROOT.PlotGraph as H
import System.IO (hFlush, stdout)

import Control.DeepSeq (deepseq)

trans = NL.tr

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
  case wmethod of
    GP.TimeDomain -> do
      let refpsd = GP.refpsd param
          fs = samplingFrequency whnWaveData
          nfreq = floor $ GP.nfrequency param * fs
          nfreq2 = nfreq `div` 2
          ntimeSlide = floor $ GP.ntimeSlide param * fs
          ntime = ((V.length $ gwdata whnWaveData) - nfreq) `div` ntimeSlide
          snrMatF = V.map (*(fs/fromIntegral nfreq)) $ V.fromList [0.0, 1.0..fromIntegral nfreq2-1]
          snrMatT = V.map (*(fromIntegral ntimeSlide/fs)) $ V.fromList [0.0, 1.0..fromIntegral ntime -1]
          snrMatT' = V.map (+deformatGPS (startGPSTime whnWaveData)) snrMatT
          snrMatP = NL.fliprl $ trans $ NL.flipud $
                      (ntime><nfreq2) $ concatMap (take nfreq2 . toList . calcSpec) [0..ntime-1]
            where
              calcSpec tindx = V.zipWith (/)
                (snd $ gwOnesidedPSDV (V.slice (ntimeSlide*tindx) nfreq (gwdata whnWaveData)) nfreq fs)
                (snd $ refpsd)
          out = (snrMatT', snrMatF, snrMatP)
      liftIO $ out `deepseq` Prelude.return ()
      case GP.TF `elem` GP.debugmode param of
        True -> do
          let dir = GP.debugDir param
          liftIO $ H3.spectrogramM H3.LogY
                                   H3.COLZ
                                   "mag"
                                   "pixelSNR spectrogram"
                                   (dir++"/pixelSNR_spectrogram_WhnTD.png")
                                   ((0, 0), (0, 0))
                                   out
        _ -> liftIO $ Prelude.return ()
      return out
    GP.FrequencyDomain -> do
      --let refpsd = gwOnesidedMedianAveragedPSDV (gwdata whnWaveData) nfreq fs
      let fs = samplingFrequency whnWaveData
      let nfreq = floor $ GP.nfrequency param * fs
--      let refpsd = gwOnesidedPSDV (gwdata whnWaveData) nfreq fs
      let refpsd = gwOnesidedMedianAveragedPSDV (gwdata whnWaveData) nfreq fs
      liftIO $ refpsd `deepseq` Prelude.return()

      let nfreq2 = nfreq `div` 2
          ntimeSlide = floor $ GP.ntimeSlide param * fs
          ntime = ((V.length (gwdata whnWaveData)) - nfreq) `div` ntimeSlide
          snrMatF = V.map (*(fs/fromIntegral nfreq)) $ V.fromList [0.0, 1.0..fromIntegral nfreq2-1]
      let snrMatT = V.map (*(fromIntegral ntimeSlide/fs)) $ V.fromList [0.0, 1.0..fromIntegral ntime -1]
          snrMatT' = V.map (+deformatGPS (startGPSTime whnWaveData)) snrMatT
      let snrMatP = NL.fliprl $ trans $ NL.flipud $
                      (ntime><nfreq2) $ concatMap (take nfreq2 . toList . calcSpec) [0..ntime-1]
            where
              calcSpec tindx = V.zipWith (/)
                (snd $ gwOnesidedPSDV (V.slice (ntimeSlide*tindx) nfreq (gwdata whnWaveData)) nfreq fs)
                (snd $ refpsd)
      let out = (snrMatT', snrMatF, snrMatP)
          out' = (snrMatT, snrMatF, snrMatP)
      liftIO $ out `deepseq` return ()
      case GP.TF `elem` GP.debugmode param of
        True -> do
          let dir = GP.debugDir param
          liftIO $ H3.spectrogramM H3.LogY
                                   H3.COLZ
                                   "mag"
                                   "pixelSNR spectrogram"
                                   (dir++"/pixelSNR_spectrogram_WhnFD.png")
                                   ((0, 0), (0, 0))
                                   out'
        _ -> liftIO $ Prelude.return ()
      return out


section'Clustering :: Spectrogram
                   -> StateT GP.GlitchParam IO (Spectrogram,[[(Tile,ID)]])
section'Clustering (snrMatT, snrMatF, snrMatP') = do
  liftIO $ print "-- start seedless clustering" >> hFlush stdout
  param <- get
  let n = GP.nNeighbor param
      l = concat . toLists $ snrMatP'
      l' = (nrow><ncol) l
      ncol = cols snrMatP'
      nrow = rows snrMatP'
      dcted' = dct2d l'
      cutT = floor $ fromIntegral ncol * GP.cutoffFractionTFT param
      cutF = floor $ fromIntegral nrow * GP.cutoffFractionTFF param
      cfun = GP.celement param
      minN = GP.minimumClusterNum param
      m1 = ((nrow-cutF)><(ncol-cutT)) $ replicate ((nrow-cutF)*(ncol-cutT)) 1.0
      mc0 = (nrow><cutT) $ replicate (nrow*cutT) 0.0
      mr0 = (cutF><(ncol-cutT)) $ replicate (cutF*(ncol-cutT)) 0.0
      qM = NL.fromBlocks [[NL.fromBlocks [[m1],[mr0]],mc0]]
  let dcted = dcted' * qM
--  liftIO $ print "evaluating dcted"  >> hFlush stdout
  dcted `deepseq` Prelude.return ()
  let snrMatP = idct2d dcted
--  liftIO $ print "evaluating snrMatP" >> hFlush stdout
  snrMatP `deepseq` Prelude.return ()
  let thresIndex = V.head $ V.findIndices (>=GP.cutoffFreq param) snrMatF
--  liftIO $ print "evaluating thresIndex" >> hFlush stdout
  thresIndex `deepseq` Prelude.return ()
  let snrMat = ( snrMatT
               , V.fromList (drop (thresIndex+1) (V.toList snrMatF))
               , NL.fromRows (drop (thresIndex+1) (NL.toRows snrMatP))
               )
--  liftIO $ print "evaluating snrMat" >> hFlush stdout
  snrMat `deepseq` Prelude.return ()
  let (tt,ff,mg) = snrMat
      mg' = zip (NL.toList . NL.flatten $ mg) [0,1..]
--      thrsed'' = [i | (v,i)<-zip (V.toList snrMatF) [0,1..], v>=GP.clusterThres param]
--      thrsed' = map (vectorInd2MatrixInd_row rmg cmg) thrsed''
      thrsed' = NL.find (>=GP.clusterThres param) mg
      cmg = cols mg
      rmg = rows mg
  thrsed <- liftIO $ case length thrsed' >= GP.maxNtrigg param of
    True -> do
      print "---- too many islands detected. top maxNtrigg islands will be selected." >> hFlush stdout
      let ind = snd . unzip . take (GP.maxNtrigg param) . reverse .
            sortBy (\ x y -> compare (fst x) (fst y)) $ mg'
      return $ map (vectorInd2MatrixInd_row rmg cmg) ind
    False->
      return thrsed'

  let survivor' = nub' $ excludeOnePixelIsland cfun n thrsed
      survivor = [(a,b)| (a,b)<-survivor', a>=0&&a<rmg, b>=0&&b<cmg]
--  liftIO $ print "---- evaluating survivor" >> hFlush stdout
  survivor `deepseq` Prelude.return ()
  let survivorwID = taggingIsland cfun minN survivor
--  liftIO $ print "---- evaluating survivorwID" >> hFlush stdout
  survivorwID `deepseq` Prelude.return ()
  let zeroMatrix = (rmg><cmg) $ replicate (rmg*cmg) 0.0
  let survivorValues = map (\x->mg `atIndex` x) survivor
  let newM = updateSpectrogramSpec snrMat
        $ updateMatrixElement zeroMatrix survivor survivorValues
--  liftIO $ print "---- evaluating newM" >> hFlush stdout
  newM `deepseq` Prelude.return ()

  case GP.CL `elem` GP.debugmode param of
    True -> do
      let dir = GP.debugDir param
      liftIO $ print "clustered pixels :"
      liftIO $ print survivorwID
      let (etgT,etgF,etgM) = newM
      liftIO $ saveMatrix (dir++"/clustered_spectrogram.dat") "%lf" etgM
      liftIO $ H3.spectrogramM H3.LogY
                      H3.COLZ
                      "mag"
                      "clustered PixelSNR spectrogram"
                      (dir++"/clustered_spectrogram.png")
                      ((0, 0), (0, 0))
                      newM
      let retgM = rows etgM
          cetgM = cols etgM
      let zeroMatrix = (retgM >< cetgM) $ replicate (retgM*cetgM) 0.0
      let etgID' = concat survivorwID
      let tileValues = map (\(x,i)->x) etgID'
      let idValues = map (\(x,i)->fromIntegral i :: Double) etgID'
      let idM = updateSpectrogramSpec newM
            $updateMatrixElement zeroMatrix tileValues idValues
      let (idT,idF,idMM) = idM
      liftIO $ saveMatrix (dir++"/island_ID_map.dat") "%lf" idMM
      liftIO $ H3.spectrogramM H3.LogY
                      H3.COLZ
                      "mag"
                      "island ID map"
                      (dir++"/island_ID_map.png")
                      ((0, 0), (0, 0))
                      idM

      let thrsedValues = map (\x->mg `atIndex` x) thrsed
          thrsedM = updateSpectrogramSpec snrMat
            $ updateMatrixElement zeroMatrix thrsed thrsedValues
      liftIO $ H3.spectrogramM H3.LogY
                               H3.COLZ
                               "mag"
                               "thresholded PixelSNR spectrogram"
                               (dir++"/thresholded_spectrogram.png")
                                   ((0, 0), (0, 0))
                               thrsedM

    _ -> liftIO $ Prelude.return ()

  case length survivorwID of
    0 -> do liftIO $ print "# of detected islands is" >> hFlush stdout
            liftIO $ print "0" >> hFlush stdout
    _ -> do liftIO $ print "# of detected islands is" >> hFlush stdout
            liftIO $ print $ (snd . last . last $ survivorwID)

  return (newM, survivorwID)


-- quantizingMatrix :: Int
--                  -> Int
--                  -> ((Int,Int)->Double)
--               -> Matrix Double
-- quantizingMatrix r c fun = buildMatrix r c fun


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
