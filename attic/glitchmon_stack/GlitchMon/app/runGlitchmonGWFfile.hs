

import Data.Maybe (fromMaybe)
import GlitchMon.GlitchMonFile
import GlitchMon.GlitchParam
import GlitchMon.PipelineFunction
import HasKAL.DataBaseUtils.FrameFull.Data
import HasKAL.FrameUtils.FrameUtils (getSamplingFrequency)
import System.Environment ( getArgs)

main = do
  (chname, fname) <- getArgs >>= \args -> case (length args) of
    2 -> return (head args, args!!1)
    _ -> error "Usage runGlitchMonFile chname fname"
  fsorig <- fmap (fromMaybe (error "fs not found.")) $ getSamplingFrequency fname chname
  let dfactor = 1
  let fs = fromIntegral $ floor (fsorig / dfactor)
  let param = GlitchParam
               { segmentLength = 32
--               , channel = "K1:LSC-MICH_CTRL_CAL_OUT_DQ"
               , channel = chname --"H1:LOSC-STRAIN"
               , samplingFrequency = fs
             -- * whitening
               , traindatlen = 30 :: Double -- [s] must be > 2 * fs/whnFrequencyResolution
               , whnFrequencyResolution = 4 :: Double -- [Hz]
               , whtCoeff = []
               , whnMethod = FrequencyDomain
             -- * t-f expression
               , nfrequency = 0.2
               , ntimeSlide = 0.03
             -- * clustering             
               , cutoffFractionTFT = 0.5
               , cutoffFractionTFF = 0.5
               , cutoffFreq = 30
               , clusterThres = 6.0
               , celement = basePixel9
               , minimumClusterNum = 6
               , nNeighbor = 3
               , maxNtrigg = 50
             -- * clean data finder
               , cdfInterval = 32
               , cdfparameter = cdfp
               , cgps = Nothing
               , reftime = 0
             -- * for debug
               , debugmode = []
               , debugDir = "debug"
               }                                 
      cdfp = CDFParam
              { cdf'samplingFrequency = fs
              , cdf'cutoffFrequencyLow = 10
              , cdf'cutoffFrequencyHigh = 500
              , cdf'blockSize = 50
              , cdf'fftSize = nfrequency param
              , cdf'chunkSize = traindatlen param
              }


  runGlitchMonFile param (channel param) fname
--"/home/kazu/work/data/gw150914/H-H1_LOSC_4_V1-1126259446-32.gwf"
--  runGlitchMonFile param (channel param) "/data/kagra/raw/full/K-K1_C-1144374208-32.gwf"


