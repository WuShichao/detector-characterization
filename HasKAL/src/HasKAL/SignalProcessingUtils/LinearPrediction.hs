
module HasKAL.SignalProcessingUtils.LinearPrediction
( lpefCoeff
, lpefCoeffV
, levinson
, levinsonV
, whitening
, whiteningWaveData
, whiteningWaveData'
) where

import qualified Data.Array.CArray as CA
import qualified Data.Array.Unboxed as UV
import Data.Complex()
import qualified Data.Vector.Storable as VS
import qualified Data.Vector.Generic as G
import Data.Maybe
import Foreign.Storable (pokeElemOff)
import Numeric.LinearAlgebra
import Numeric.LinearAlgebra.Devel (zipVectorWith)
import Numeric.GSL.Fourier
import HasKAL.MathUtils.FFTW (dftRC1d,dftCR1d)
import HasKAL.SignalProcessingUtils.FilterX(filtfilt0)
import HasKAL.SignalProcessingUtils.WindowType
import HasKAL.SignalProcessingUtils.WindowFunction
import HasKAL.SignalProcessingUtils.Interpolation
import HasKAL.SignalProcessingUtils.InterpolationType
import HasKAL.SpectrumUtils.SpectrumUtils
import HasKAL.WaveUtils.Data
import System.IO.Unsafe (unsafePerformIO)

{- exposed functions -}
lpefCoeff :: Int -> [(Double,Double)] -> ([Double],Double)
lpefCoeff p psddat = (out,rho)
  where
    (out,rho) = levinson p r
    r = toList.fst.fromComplex.ifft.fromList
      $ [fs*nn*x/nn:+0|x<-(snd.unzip) psddat]
    fs = last.fst.unzip $ psddat
    nn = fromIntegral $ length psddat :: Double


levinson :: Int -> [Double] -> ([Double],Double)
levinson p r = do
    let r' = UV.listArray (0, nlen-1) r
        (tmpcoef, rho) = levinsonD r' p
    (1:UV.elems tmpcoef,rho)
    where nlen = length r


whitening :: ([Double],Double) -> [Double]-> [Double]
whitening (whnb,rho) x =
  let whnb' = map mysqrt whnb
   in map (/sqrt rho) $ toList $ filtfilt0 (whnb',(1.0:replicate (length whnb'-1) 0.0)) $ fromList x


--whiteningC :: ([Double],Double) -> [Double]-> [Double]
--whiteningC (whnb,rho) x = map (/sqrt rho) $ firFilter x whnb


whiteningWaveData :: ([Double],Double) -> WaveData -> WaveData
whiteningWaveData (whnb,rho) x = unsafePerformIO $ do
  let whnb' = map mysqrt whnb
--      initcoeff = calcInitCond (whnb',(1.0:replicate (length whnb'-1) 0.0))
--      y = G.map (/sqrt rho) $ firFiltfiltVInit whnb' initcoeff (gwdata x)
      y = G.map (/sqrt rho) $ filtfilt0 (whnb',(1.0:replicate (length whnb'-1) 0.0)) (gwdata x)
      -- y = gwdata x
  return $ fromJust $ updateWaveDatagwdata x y


whiteningWaveData' :: ([Double],Double) -> WaveData -> WaveData
whiteningWaveData' (whnb,rho) x = unsafePerformIO $ do
  let datlen = VS.length $ gwdata x
      datlen' = fromIntegral datlen  :: Double
      n = fromIntegral (length whnb) :: Double
      fp = [0,1/n..1]
      fa = [0,1/datlen'..1]
      whnb' = init $ interpV fp whnb fa Linear
--  print datlen
--  print $ length whnb'
  let fftwhnb' = dftRC1d $ fromList whnb'
      (fftwhnb'_r, fftwhnb'_i) = fromComplex fftwhnb'
--  print $ VS.length fftwhnb'_r
  let absfftwhnb' = sqrt $ (zipVectorWith (*) fftwhnb'_r fftwhnb'_r)
      fftdat = dftRC1d $ gwdata x
      (fftdat_r,fftdat_i) = fromComplex fftdat
--  print $ VS.length fftdat_r
--  print $ VS.length absfftwhnb'
  let  zerov = vector (replicate (VS.length absfftwhnb') 0)
       fftwhndat = dftCR1d $ zipVectorWith (*) (toComplex (absfftwhnb', zerov)) fftdat
--  print $ VS.length zerov
  let y = G.map (/sqrt rho) fftwhndat
--  print $ VS.length y
  case updateWaveDatagwdata x y of
    Nothing -> error "data not whitened"
    Just z -> return z


lpefCoeffV :: Int -> (Vector Double, Vector Double) -> ([Double], Double)
lpefCoeffV p psddat = (out,rho)
  where
    (out,rho) = levinsonV p r
    r = fst.fromComplex.ifft
      $ toComplex (G.map (fs*) (snd psddat), vector (replicate (G.length (snd psddat)) (0::Double)))
    fs = (G.last.fst) psddat



levinsonV :: Int -> Vector Double -> ([Double],Double)
levinsonV p r = do
--    let r' = unsafePerformIO $ CA.createCArray (0, nlen-1)
--          $ \ptr -> VS.zipWithM_ (pokeElemOff ptr) (VS.fromList [0, nlen-1]) r
  let r' = UV.listArray (0, nlen-1) $ VS.toList r
      (tmpcoef, rho) = levinsonD r' p
  (1:CA.elems tmpcoef,rho)
    where nlen = G.length r


{- internal functions -}
levinsonD :: (UV.Ix a, Integral a, RealFloat b)
  => UV.Array Int Double           -- ^ r
  -> Int                           -- ^ p
  -> (UV.Array Int Double, Double) -- ^ (coefficients,rho)
levinsonD r p = (UV.array (1,p) [ (k, a UV.!(p,k)) | k <- [1..p] ], rho UV.!p)
  where
    a = UV.array ((1,1),(p,p))
      [((k,i), ak k i) | k<-[1..p], i<-[1..k]]:: UV.Array (Int,Int) Double
    rho = UV.array (1,p) [ (k, rhok k) | k <- [1..p] ]:: UV.Array Int Double
    ak 1 1         = -r UV.!1 / r UV.!0
    ak k i | k==i  = -(r UV.!k+sum [a UV.!(k-1,l)*r UV.!(k-l)|l<-[1..(k-1)]])
                   / rho UV.!(k-1)
           | otherwise = a UV.!(k-1,i) + a UV.!(k,k) * a UV.!(k-1,k-i)
    rhok 1 = (1 - (abs (a UV.!(1,1)))^(2::Int)) * r UV.!0
    rhok k = (1 - (abs (a UV.!(k, k)))^(2::Int)) * rho UV.!(k-1)


levinsonDC :: (CA.Ix a, Integral a, RealFloat b)
  => CA.Array Int Double           -- ^ r
  -> Int                           -- ^ p
  -> (CA.Array Int Double, Double) -- ^ (coefficients,rho)
levinsonDC r p = (CA.array (1,p) [ (k, a CA.!(p,k)) | k <- [1..p] ], rho CA.!p)
  where
    a = CA.array ((1,1),(p,p))
      [((k,i), ak k i) | k<-[1..p], i<-[1..k]]:: CA.Array (Int,Int) Double
    rho = CA.array (1,p) [ (k, rhok k) | k <- [1..p] ]:: CA.Array Int Double
    ak 1 1         = -r CA.!1 / r CA.!0
    ak k i | k==i  = -(r CA.!k+sum [a CA.!(k-1,l)*r CA.!(k-l)|l<-[1..(k-1)]])
                   / rho CA.!(k-1)
           | otherwise = a CA.!(k-1,i) + a CA.!(k,k) * a CA.!(k-1,k-i)
    rhok 1 = (1 - (abs (a CA.!(1,1)))^(2::Int)) * r CA.!0
    rhok k = (1 - (abs (a CA.!(k, k)))^(2::Int)) * rho CA.!(k-1)


mysqrt x
  | x < 0 = (-1)*sqrt ((-1)*x)
  | x >= 0 =  sqrt x
  | otherwise = error "something wrong"
