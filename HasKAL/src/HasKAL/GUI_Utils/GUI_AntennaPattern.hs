


module HasKAL.GUI_Utils.GUI_AntennaPattern (
   hasKalGuiAntennaPattern
) where

import Graphics.UI.Gtk
import qualified System.IO.Unsafe as SIOU
import qualified Control.Monad as CM

import qualified HasKAL.GUI_Utils.GUI_Supplement as HGGS
import qualified HasKAL.DetectorUtils.Detector as HDD
import qualified HasKAL.DetectorUtils.DetectorParam as DDP
import qualified HasKAL.DetectorUtils.Function as DUF
import qualified HasKAL.DetectorUtils.Signature as HDS
import qualified HasKAL.PlotUtils.HROOT.PlotGraph3D as RPG3

{-- Test Code --}
-- main = hasKalGuiAntennaPattern

{-- External Functions --}
hasKalGuiAntennaPattern :: IO ()
hasKalGuiAntennaPattern = do
  initGUI
  putStrLn "Open AntennaPattern Window"
  
  {--  Create new object  --}
  window <- windowNew
  vBox <- vBoxNew True 5
  hBoxDetector <- hBoxNew True 5
  hBoxPsi <- hBoxNew True 5
  hBoxPhi <- hBoxNew True 5
  hBoxTheta <- hBoxNew True 5
  hBoxButtons <- hBoxNew True 5

  let detectorList = map show [HDD.KAGRA, HDD.LIGO_Hanford, HDD.LIGO_Livingston, HDD.VIRGO, HDD.GEO]
  detectorCombo <- HGGS.comboBoxNewLabelAppendTexts "Detector" detectorList 0
  psiEntry <- HGGS.entryNewWithLabelDefault "polarization angle [deg.]" "0.0"
  phiEntry <- HGGS.entryNewWithLabelDefault "delta phi [deg.]" "1.0"
  thetaEntry <- HGGS.entryNewWithLabelDefault "delta theta [deg.]" "1.0"
  closeButton <- buttonNewWithLabel "Close"
  executeButton <- buttonNewWithLabel "Execute"

  {--  set parameter of the objects --}
  set window [windowTitle := "Antenna Pattern",
              windowDefaultWidth := 200,
              windowDefaultHeight := 300,
              containerChild := vBox,
              containerBorderWidth := 20 ]

  {--  Arrange object in window  --}
  boxPackStart vBox hBoxDetector PackGrow 0
  HGGS.boxPackStartDefaultsPair hBoxDetector detectorCombo
  boxPackStart vBox hBoxPsi PackGrow 0
  HGGS.boxPackStartDefaultsPair hBoxPsi psiEntry
  boxPackStart vBox hBoxPhi PackGrow 0
  HGGS.boxPackStartDefaultsPair hBoxPhi phiEntry
  boxPackStart vBox hBoxTheta PackGrow 0
  HGGS.boxPackStartDefaultsPair hBoxTheta thetaEntry
  boxPackStart vBox hBoxButtons PackGrow 0
  mapM (\x -> boxPackStart hBoxButtons x PackGrow 0) [closeButton, executeButton]

  {--  Execute  --}
  onClicked closeButton $ do
    putStrLn "Closed AntennaPattern Window"
    widgetDestroy window
  onClicked executeButton $ do
    putStrLn "Execute"
    detectorStr <- HGGS.comboBoxGetActiveString detectorCombo
    let psiD = abs.read.SIOU.unsafePerformIO.entryGetText.snd $ psiEntry :: Double
        dPhiD = abs.read.SIOU.unsafePerformIO.entryGetText.snd $ phiEntry :: Double
        dThetaD = abs.read.SIOU.unsafePerformIO.entryGetText.snd $ thetaEntry :: Double
    putStrLn $ "   Detector: " ++ detectorStr
    putStrLn $ "        Psi: " ++ show psiD
    putStrLn $ "  delta Phi: " ++ show dPhiD
    putStrLn $ "delta Theta: " ++ show dThetaD
    let phiV = [-180.0, (-180.0+dPhiD)..180.0]
        thetaV = [-90.0, (-90.0+dThetaD)..90.0]
    skymap <- CM.forM phiV $ \phi ->
      CM.forM thetaV $ \theta -> do
        let fpfc = DUF.fplusfcrossts (detStr2Param $ read detectorStr) phi theta psiD
        return $ sqrt $ (fst (fst fpfc))**2 + (snd (fst fpfc))**2
    RPG3.skyMapX RPG3.Linear RPG3.COLZ "Z" ("Antenna Pattern Skymap at "++detectorStr) ((0.0,0.0),(0.0,0.0))$ genSkymapData phiV thetaV skymap

  {--  Exit Process  --}
  onDestroy window mainQuit
  widgetShowAll window
  mainGUI

{--  Internal Functions  --}
detStr2Param :: HDD.Detector -> DDP.DetectorParam
detStr2Param detector 
  | detector == HDD.KAGRA = DDP.kagra
  | detector == HDD.LIGO_Hanford = DDP.ligoHanford
  | detector == HDD.LIGO_Livingston = DDP.ligoLivingston
  | detector == HDD.VIRGO = DDP.virgo
  | detector == HDD.GEO = DDP.geo600
  | otherwise = DDP.kagra

genSkymapData :: [Double] -> [Double] -> [[Double]] -> [(Double,  Double,  Double)]
genSkymapData phiV thetaV skymap = do
  let phiV' = concat [ replicate (length thetaV) x | x <- phiV]
      thetaV'=take (length phiV * length thetaV) $ cycle thetaV
  zip3 phiV' thetaV' (concat skymap)
