--module HasKAL.MonitorUtils.RangeMon.StochMon.StochMon(
module StochMon(
       h2omega_sens_allf,
       h2omega_sens,
       h2omega_sens_fband,
       h2omega_sens_gui,
       h2omega_psd_kagra,
       orf_detectors,
       ifonoisepsd_stoch
       ) where

import System.IO
import System.IO.Unsafe
import HasKAL.DetectorUtils.Detector
import Control.Concurrent
import HasKAL.ExternalUtils.GSL.RandomNumberDistributions



--Calculation of h2omega for GUI tools --
--give one GPS time and show frequency dependence of h2omega--
-- input  :
-- output :
h2omega_sens_gui :: Detector->(Double, Double)->Double
h2omega_sens_gui det_a (psdin, fin) = (h2omega_factor (3.0*365.25*86400.0))*(h2omega_erfc 0.05 0.95)*((h2omega_psd_kagra det_a (psdin, fin))**(-0.5))

--Calculation of h2omega for given frequency list[..]
--input  : ttot(observation time[s]) det_a(Detector A) det_b(Detector B) far(False Alarm Rate) df(Detection probility) xs[give frequency]
--output : [Double] := h2omega for each frequency
h2omega_sens_allf :: Double->Detector->Detector->Double->Double->[Double]->[Double]
h2omega_sens_allf ttot det_a det_b far df xs = map (h2omega_sens ttot det_a det_b far df) xs

--Calculation of h2omega for sensitivity curve with given frequency band [fmin:fmax]
--input	: ttot(observation time[s]) det_a(Detector A) det_b(Detector B) far(False Alarm Rate) df(Detection probility) fmin(minimum frequency[Hz]) fmax(maximum frequency[Hz])
--output ; Double := h2omega for given frequency band(fmin:fmax)
h2omega_sens_fband :: Double->Detector->Detector->Double->Double->Double->Double->Double
h2omega_sens_fband ttot det_a det_b far df fmin fmax= (h2omega_factor ttot)*(h2omega_erfc far df)*((h2omega_psd_fband det_a det_b fmin fmax)**(-0.5))

--One paragraph	of h2omega_sens_fband
h2omega_psd_fband :: Detector->Detector->Double->Double->Double
h2omega_psd_fband det_a det_b fmin fmax = sumarray $ map (h2omega_psd det_a det_b) [fmin..fmax]

--function for getting sum value of list
sumarray :: [Double]->Double
sumarray [] = 0
sumarray (x:xs) = x + sumarray xs

--Calculation of h2omega for sensitivity curve
--input : ttot(observation time[s]) det_a(Detector A) det_b(Detector B) far(False Alarm Rate) df(Detection probility) fin(target frequency[Hz])
--output ; Double := h2omega for given frequency(fin)
h2omega_sens :: Double->Detector->Detector->Double->Double->Double->Double
h2omega_sens ttot det_a det_b far df fin= (h2omega_factor ttot)*(h2omega_erfc far df)*((h2omega_psd det_a det_b fin)**(-0.5))

--One paragraph of h2omega_sens
h2omega_factor :: Double->Double
h2omega_factor ttot = 1/(sqrt(ttot))*10.0*(pi**2)/3.0/((3.2*1.0E-18)**2)*(sqrt(2.0))

--One paragraph of h2omega_sens
h2omega_erfc :: Double->Double->Double
h2omega_erfc far df = (erfc_inv (2.0*far))-(erfc_inv (2.0*df))

--One paragraph of h2omega_sens
h2omega_psd :: Detector->Detector->Double->Double
h2omega_psd det_a det_b fin = ((orf_detectors det_a det_b fin)**2)/(fin**6)/(ifonoisepsd_stoch det_a fin)/(ifonoisepsd_stoch det_b fin)

h2omega_psd_kagra :: Detector->(Double, Double)->Double
h2omega_psd_kagra det_a (psdin, fin) = ((orf_detectors det_a KAGRA fin)**2)/(fin**6)/(ifonoisepsd_stoch det_a fin)/(psdin)

--Detector sensitivity curve of KAGRA, VIRGO, LIGO_Hanford, LIGO_Livingston
--Only for StochMon, input/output are slightly different from HasKAL.SpectrumUtils.DetectorSensitivity
ifonoisepsd_stoch :: Detector -> Double -> Double
ifonoisepsd_stoch ifo fin = case ifo of
  LIGO  -> aligoPsd_stoch fin
  LIGO_Livingston -> aligoPsd_stoch fin
  LIGO_Hanford -> aligoPsd_stoch fin
  KAGRA -> kagraPsd_stoch fin
  VIRGO -> advirgoPsd_stoch fin

aligoPsd_stoch :: Double -> Double
aligoPsd_stoch fin = (psdmodel x)
  where
    f0 = 245.4 :: Double
    psd_scale = 1.0E-48 :: Double
    x  = fin / f0
    psdmodel y = psd_scale * (0.0152*y**(-4) + 0.2935*y**(9.0/4.0) + 2.7951*y**(3.0/2.0) - 6.5080*y**(3.0/4.0) + 17.7622)

kagraPsd_stoch :: Double -> Double
kagraPsd_stoch fin = (psdmodel x)
  where
    f0 = 100 :: Double
    x  = toLog fin
    toLog z = log (z/f0)
    psdmodel y = (6.499*1.0E-25*(9.72*10e-9*(exp (-1.43-9.88*y-0.23*y**2))+1.17*(exp (0.14-3.10*y-0.26*y**2))+1.70*(exp (0.14+1.09*y-0.013*y**2))+1.25*(exp (0.071+2.83*y-4.91*y**2))))**2

advirgoPsd_stoch :: Double -> Double
advirgoPsd_stoch fin = (psdmodel x)
  where
    f0 = 300 :: Double
    x  = toLog fin
    toLog z = log (z/f0)
    psdmodel y = (1.259*1.0E-24*(0.07*(exp (-0.142-1.437*y+0.407*y**2))+3.10*(exp (-0.466-1.043*y-0.548*y**2))+0.40*(exp (-0.304+2.896*y-0.293*y**2))+0.09*(exp (1.466+3.722*y-0.984*y**2))))**2
----------------------------------------------

--Function for error function
erfc_inv ::Double->Double
erfc_inv par = gslCdfGaussianQinv (par/2.0) sigma
  where sigma = 1/sqrt(2.0)

erfc_inv' par = last $ last $ filter (\xs -> (head xs) == par) read_erfc_inv

--Function for overlap reduction function
orf_detectors :: Detector->Detector->Double->Double
orf_detectors det_a det_b ff
   | ((det_a == (LIGO_Livingston)) && (det_b == (LIGO_Hanford))) || ((det_a == (LIGO_Hanford)) && (det_b == (LIGO_Livingston))) = (giveorf 1 ff)
   | ((det_a == (LIGO_Livingston)) && (det_b == VIRGO))          || ((det_a == VIRGO)          && (det_b == (LIGO_Livingston))) = (giveorf 2 ff)
   | ((det_a == (LIGO_Livingston)) && (det_b == KAGRA))          || ((det_a == KAGRA)          && (det_b == (LIGO_Livingston))) = (giveorf 3 ff)
   | ((det_a == (LIGO_Hanford))    && (det_b == VIRGO))          || ((det_a == VIRGO)          && (det_b == (LIGO_Hanford)))    = (giveorf 4 ff)
   | ((det_a == (LIGO_Hanford))    && (det_b == KAGRA))          || ((det_a == KAGRA)          && (det_b == (LIGO_Hanford)))    = (giveorf 5 ff)
   | ((det_a == VIRGO)             && (det_b == KAGRA))          || ((det_a == KAGRA)          && (det_b == VIRGO))             = (giveorf 6 ff)
   | otherwise                                                                                                                  = 0.0

giveorf :: Int -> Double -> Double
giveorf id ff = (last $ filter (\xs -> (head xs) == ff) read_ORF) !! id

read_erfc_inv :: [[Double]]
read_erfc_inv = readMultiColumn (unsafePerformIO $ readFile "HasKAL/MonitorUtils/RangeMon/StochMon/erfc_inv.dat")

read_ORF :: [[Double]]
read_ORF = readMultiColumn (unsafePerformIO $ readFile "HasKAL/MonitorUtils/RangeMon/StochMon/orf_data_1.txt")

readMultiColumn :: String -> [[Double]]
readMultiColumn = map (map read.words).lines

