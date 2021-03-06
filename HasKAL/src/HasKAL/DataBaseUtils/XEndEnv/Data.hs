
module HasKAL.DataBaseUtils.XEndEnv.Data
where


data CDFParam = CDFParam { cdf'samplingFrequency :: Double
                         , cdf'cutoffFrequencyLow :: Double
                         , cdf'cutoffFrequencyHigh :: Double
                         , cdf'blockSize :: Int
                         , cdf'fftSize :: Double
                         , cdf'chunkSize :: Double
                         }

