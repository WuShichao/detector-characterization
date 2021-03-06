{-
 - unit test of whitening filter based on linear prediction error filter
 - for compilation
 - ghc -O2 --make testLPEF.hs
 - HasKAL/SignalProcessingUtils/filterFunctions.c
 - -LHasKAL/ExternalUtils/NumericalRecipes -ltoeplz -lFrame
 -}

--import HasKAL.ExternalUtils.NumericalRecipes.Functions
--import HasKAL.SignalProcessingUtils.Levinson
import HasKAL.SignalProcessingUtils.ButterWorth
import HasKAL.SignalProcessingUtils.Filter
import HasKAL.SignalProcessingUtils.FilterType
import HasKAL.SignalProcessingUtils.LinearPrediction
import HasKAL.SpectrumUtils.SpectrumUtils
import HasKAL.SpectrumUtils.GwPsdMethod
import HasKAL.FrameUtils.FrameUtils
import qualified HasKAL.PlotUtils.HROOT.PlotGraph as HR
import Data.List

main = do
  let nC = 1500
  let fname = "H-H2_RDS_C03_L2-877201786-128.gwf"
  ch <- getChannelList fname
  let [(chname,  _)]=ch
  fdata <- readFrame chname fname
  let x = take (16384*5) $ map realToFrac (eval fdata)
      (lpfNum,lpfDen) = butter 6 16384 50 High
      --x = drop (6*3) $ take (length x' - 6*3) $ iirFilter x' lpfNum lpfDen
--  let x = map (\m->(!!m) (map realToFrac (eval fdata))) [1,5..2097152]
      t = [y/16384 |y<-[0.0..(realToFrac (length x) -1.0)]] :: [Double]
      psddat = gwpsd x 16384 16384
      (whnNum, whnDenom) = lpefCoeff nC $ map ((16384*16384)*) (snd.unzip $ psddat)

      whitenedx = drop (nC*3) $ take (length x - nC*3) $ firFilter x whnDenom
--      whitenedx = drop (nC*3) $ take (length x - nC*3) $ iirFilter x whnNum whnDenom
--      whitenedx = map (\i -> sum [whnDenom!!j * x!!(i-1-j) | j<-[0..nC-1]]) [nC..((length x)-nC)]
--      whitenedx = iirFilter whitenedx' whnNum whnDenom
      newpsd = gwpsd whitenedx 16384 16384
  print $ findIndices isNaN whitenedx
  print $ findIndices isInfinite whitenedx
--  print $ whitenedx!!128904
--  print $ length x'
--  HR.oPlot HR.LogXY HR.Line ("frequency", "Spectrum") ["before", "after"] "whiteningTest.eps" [psddat, zip (fst.unzip $ psddat) whitenedx]
  HR.plot HR.Linear HR.Line ("time", "amplitude") "after" "whiteningTest.png" $ zip t  whitenedx
  HR.plot HR.LogXY HR.Line ("frequency", "Spectrum") "before" "whiteningTestbefore.png" $ psddat --gwpsd whitenedx 16384 16384
  HR.plot HR.LogXY HR.Line ("frequency", "Spectrum") "after" "whiteningTestbafter.png" $ newpsd --gwpsd whitenedx 16384 16384



