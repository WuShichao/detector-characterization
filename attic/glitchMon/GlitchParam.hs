

module GlitchMon.GlitchParam
where

--import qualified Data.Vector.Storable as V
import HasKAL.DataBaseUtils.FrameFull.Data
import HasKAL.SpectrumUtils.Signature (Spectrum)
import HasKAL.TimeUtils.Signature (GPSTIME)
import HasKAL.WaveUtils.Data(WaveData)


data GlitchParam = GlitchParam
  { channel :: String
  , chunklen :: Int 
  , samplingFrequency :: Double
-- * whitening
  , refpsdlen       :: Int
  , whtfiltordr  :: Int
  , whtCoeff :: [([Double],  Double)]
-- * t-f expression
  , nfrequency :: Int
  , ntimeSlide :: Int
-- * clustering
  , resolvTime :: Int
  , resolvFreq :: Int
  , cutoffFreq :: Double
  , clusterThres :: Double
-- * clean data finder
  , cdfInterval :: Int -- ^ interval[s] to run clean data finder (default 600[s])
  , cdfparameter :: CDFParam
  , cgps  :: Maybe GPSTIME
-- * temporary data
  , refpsd :: Spectrum
  , refwave :: WaveData
  , reftime :: Double
  }


updateGlitchParam'channel :: GlitchParam -> String -> GlitchParam
updateGlitchParam'channel x n = x {channel = n}

updateGlitchParam'chunklen :: GlitchParam -> Int -> GlitchParam
updateGlitchParam'chunklen x n = x {chunklen = n}

updateGlitchParam'samplingFrequency :: GlitchParam -> Double -> GlitchParam
updateGlitchParam'samplingFrequency x fs = x {samplingFrequency = fs}

updateGlitchParam'refpsdlen :: GlitchParam -> Int -> GlitchParam
updateGlitchParam'refpsdlen x n = x {refpsdlen = n}

updateGlitchParam'whtfiltordr :: GlitchParam -> Int -> GlitchParam
updateGlitchParam'whtfiltordr x n = x {whtfiltordr = n}

updateGlitchParam'whtCoeff :: GlitchParam -> [([Double],  Double)] -> GlitchParam
updateGlitchParam'whtCoeff x p = x {whtCoeff = p}

updateGlitchParam'nfrequency :: GlitchParam -> Int -> GlitchParam
updateGlitchParam'nfrequency x n = x {nfrequency = n}

updateGlitchParam'ntimeSlide :: GlitchParam -> Int -> GlitchParam
updateGlitchParam'ntimeSlide x n = x {ntimeSlide = n}

updateGlitchParam'resolvTime :: GlitchParam -> Int -> GlitchParam
updateGlitchParam'resolvTime x n = x {resolvTime = n}

updateGlitchParam'resolvFreq :: GlitchParam -> Int -> GlitchParam
updateGlitchParam'resolvFreq x n = x {resolvFreq = n}

updateGlitchParam'cutoffFreq :: GlitchParam -> Double -> GlitchParam
updateGlitchParam'cutoffFreq x f = x {cutoffFreq = f}

updateGlitchParam'clusterThres :: GlitchParam -> Double -> GlitchParam
updateGlitchParam'clusterThres x thres = x {clusterThres = thres}

updateGlitchParam'cdfInterval :: GlitchParam -> Int -> GlitchParam
updateGlitchParam'cdfInterval x param = x {cdfInterval = param}

updateGlitchParam'cdfparameter :: GlitchParam -> CDFParam -> GlitchParam
updateGlitchParam'cdfparameter x param = x {cdfparameter = param}

updateGlitchParam'cgps :: GlitchParam -> Maybe GPSTIME -> GlitchParam
updateGlitchParam'cgps x param = x {cgps =  param}

updateGlitchParam'refpsd :: GlitchParam -> Spectrum -> GlitchParam
updateGlitchParam'refpsd x psd = x {refpsd = psd}

updateGlitchParam'refwave :: GlitchParam -> WaveData -> GlitchParam
updateGlitchParam'refwave x w = x {refwave = w}

updateGlitchParam'reftime :: GlitchParam -> Double -> GlitchParam
updateGlitchParam'reftime x t = x {reftime = t}


