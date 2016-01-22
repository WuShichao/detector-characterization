
import Data.Maybe (fromJust)
import System.Environment (getArgs)
import Data.Packed.Vector (subVector)
-- import Data.Packed.Matrix (cols, rows, toRows, fromColumns) {-- for nu hist --}

-- import HasKAL.SpectrumUtils.Signature {-- for nu hist --}
import HasKAL.TimeUtils.GPSfunction (time2gps)
import HasKAL.FrameUtils.FrameUtils (getSamplingFrequency)
import HasKAL.DataBaseUtils.XEndEnv.Function (kagraDataGet, kagraDataFind)
import HasKAL.SpectrumUtils.SpectrumUtils (gwOnesidedPSDV, gwspectrogramV)
import HasKAL.MonitorUtils.SRMon.StudentRayleighMon
import HasKAL.PlotUtils.HROOT.PlotGraph3D


main = do
  args <- getArgs
  (year, month, day, ch) <- case length args of
                             4 -> return (args!!0, show0 2 (args!!1), show0 2 (args!!2), args!!3)
                             _ -> error "Usage: SRMon yyyy mm dd channel"

  {-- parameters --}
  let gps = read $ time2gps $ year++"-"++month++"-"++day++" 00:00:00 JST"
      duration = 86400 -- seconds
      -- for SRMon
      fftLength = 1    -- seconds
      srmLength = 3600 -- seconds
      timeShift = 3600 -- seconds
      freqResol = 16   -- Hz
      quantile  = 0.99 -- 0 < quantile < 1
      -- for Plot
      oFile = ch++"-"++year++"-"++month++"-"++day++"_SRMon.png"
      title = "StudentRayleighMon: " ++ ch
      xlabel = "Date: "++year++"/"++month

  {-- read data --}
  mbFiles <- kagraDataFind (fromIntegral gps) (fromIntegral duration) ch
  let file = case mbFiles of
              Nothing -> error $ "Can't find file: "++year++"/"++month++"/"++day
              _ -> head $ fromJust mbFiles
  mbDat <- kagraDataGet gps duration ch
  mbFs <- getSamplingFrequency file ch
  let (dat, fs) = case (mbDat, mbFs) of
                   (Just a, Just b) -> (a, b)
                   (Nothing, _) -> error $ "Can't read data: "++ch++"-"++year++"/"++month++"/"++day
                   (_, Nothing) -> error $ "Can't read sampling frequency: "++ch++"-"++year++"/"++month++"/"++day

  {-- main --}
  let snf = gwOnesidedPSDV (subVector 0 (truncate $ fftLength * fs * 1024) dat) (truncate $ fftLength * fs) fs
      hf  = gwspectrogramV 0 (truncate $ fftLength * fs) fs dat
      nu = studentRayleighMonV (QUANT quantile) fs (truncate $ fftLength * fs) srmLength timeShift (truncate $ freqResol/fftLength) snf hf
  histgram2dDateM Linear COLZ (xlabel, "frequency [Hz]", "nu") title oFile ((0,0),(0,0)) gps nu

  -- histgram2dM LogZ COLZ (xlabel, "nu", "yield") title oFile ((0,0),(0,0)) $ srMonNuHist nu {-- for nu hist --}

{-- Internal Functions --}
show0 :: Int -> String -> String
show0 digit number
  | len < digit = (concat $ replicate (digit-len) "0") ++ number
  | otherwise   = number
  where len = length number

