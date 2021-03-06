
import Network.CGI
import Data.Maybe (fromJust)
import qualified Data.Vector.Storable as V (fromList, length, take)
import Control.Monad (liftM, forM)
import System.Directory (doesFileExist)

import HasKAL.TimeUtils.GPSfunction (getCurrentGps)
import HasKAL.DataBaseUtils.Function (kagraDataGet, kagraDataFind)
import HasKAL.FrameUtils.FrameUtils (getSamplingFrequency)
import HasKAL.SpectrumUtils.SpectrumUtils (gwpsdV)
import HasKAL.MonitorUtils.CoherenceMon.Function (coherenceMon)
import HasKAL.MonitorUtils.CorrelationMon.CalCorrelation (takeCorrelationV)
import HasKAL.PlotUtils.HROOT.PlotGraph (LogOption(..), PlotTypeOption(..), ColorOpt(..), plotV)
import Function

main :: IO ()
main = runCGI $ handleErrors cgiMain

cgiMain :: CGI CGIResult
cgiMain = do
  params <- getInputParams
  str <- liftIO $ fork params
  output $ str

fork :: ParamCGI -> IO String
fork params = do
  nowGps <- getCurrentGps
  case (gps params, channel1 params, channel2 params, monitors params) of
   (Nothing, _, _, _) -> return $ inputForm $ updateMsg "" $ updateGps nowGps params
   (Just "", _, _, _) -> return $ inputForm $ updateMsg "" $ updateGps nowGps params
   (_, [], _, _)      -> return $ inputForm $ updateMsg "unselected channel1" params
   (_, _, [], _)      -> return $ inputForm $ updateMsg "unselected channel2" params   
   (_, _, _, [])      -> return $ inputForm $ updateMsg "unselected monitor" params
   (Just x,  _, _, _)  -> do
     fnames <- process params
     return $ resultPage params fnames

process :: ParamCGI -> IO [(Message, String, [String])]
process params = do
  let gps' = fromJust $ gps params
      duration' = duration params
      fmin' = fmin params
      fmax' = fmax params
      ch1 = head $ channel1 params
      chs = channel2 params
      monitors' = monitors params
  datMaybe <- kagraDataGet (read gps') (read duration') ch1
  case datMaybe of
   Nothing -> return [("Can't find file or channel1", ch1, [])] -- データが無ければメッセージを返す
   _ -> do
     fs1 <- liftM fromJust $ (`getSamplingFrequency` ch1) =<< liftM (head.fromJust) (kagraDataFind (read gps') (read duration') ch1)
     let dat1 = fromJust datMaybe
         snf1 = gwpsdV dat1 (truncate fs1) fs1
         refpng = pngDir++ch1++"_"++gps'++"_"++"REFSPE"++"_"++duration'++"_fl"++fmin'++"_fh"++fmax'++".png"
     refExist <- doesFileExist refpng
     case refExist of
      True -> return ()
      False -> plotV LogY Line 1 BLUE ("Hz", "/Hz") 0.05 ("Spectrum: "++ch1++" GPS="++gps') refpng
               ((read fmin',read fmax'),(0,0)) $ (\(x, y) -> (V.take (V.length x `div`2) x, V.take (V.length x `div`2) y)) snf1
     result <- forM chs $ \ch2 -> do
       datMaybe2 <- kagraDataGet (read gps') (read duration') ch2
       case datMaybe2 of
        Nothing -> return ("Can't find file or channel", ch2, []) -- データが無ければメッセージを返す
        _ -> do
          fs2 <- liftM fromJust $ (`getSamplingFrequency` ch2) =<< liftM (head.fromJust) (kagraDataFind (read gps') (read duration') ch2)
          let dat2 = fromJust datMaybe2
              tvec = V.fromList [0,1/fs1..(fromIntegral $ V.length dat2-1)/fs1]
              snf2 = gwpsdV dat1 (truncate fs2) fs2
              refpng2 = pngDir++ch2++"_"++gps'++"_"++"REFSPE"++"_"++duration'++"_fl"++fmin'++"_fh"++fmax'++".png"
          refExist2 <- doesFileExist refpng2
          case refExist2 of
           True -> return () -- 既にPNGがあれば何もしない
           False -> plotV LogY Line 1 BLUE ("Hz", "/Hz") 0.05 ("Spectrum: "++ch2++" GPS="++gps') refpng2
                    ((read fmin',read fmax'),(0,0)) $ (\(x, y) -> (V.take (V.length x `div`2) x, V.take (V.length x `div`2) y)) snf2
          files <- forM monitors' $ \mon -> do
            let pngfile = pngDir++ch2++"_"++gps'++"_"++mon++"_"++duration'++"_fl"++fmin'++"_fh"++fmax'++".png"
            pngExist <- doesFileExist pngfile
            case pngExist of
             True -> return () -- 既にPNGがあれば何もしない
             False -> do
               case mon of
                "COH" -> do
                  let coh = coherenceMon (truncate fs1) fs1 dat1 dat2
                  plotV Linear Line 1 BLUE ("Hz", "|Coh(f)|^2") 0.05 ("Coherence: "++ch1++" vs "++ch2++" GPS="++gps')
                    pngfile ((read fmin',read fmax'),(-0.05,1.05)) coh
                "Peason" -> do
                  let cor = takeCorrelationV (read mon) dat1 dat2 16
                  plotV Linear LinePoint 1 BLUE ("s", "correlation") 0.05 ("Peason: "++ch1++" vs "++ch2++" GPS="++gps')
                    pngfile ((0,0),(0,0)) (tvec, cor)
                "MIC" -> do
                  return () -- 未実装
                  -- let cor = takeCorrelationV (read mon) dat1 dat2 16
                  -- plotV Linear LinePoint 1 BLUE ("s", "correlation") 0.05 ("MIC: "++ch1++" vs "++ch2++" GPS="++gps')
                  --   pngfile ((0,0),(0,0)) (tvec, cor)
            return pngfile
          return ("", ch2, refpng2:files)
     return $ ("", "Reference: "++ch1, [refpng]):result

inputForm :: ParamCGI -> String
inputForm params = inputFrame params formbody
  where formbody = concat [
          "<form action=\"", (script params), "\" method=\"GET\">",
          dateForm params,
          channelForm params [Single, Multi],
          paramForm,
          monitorForm Multi [(True, "COH", "CoherenceMon")
                            ,(False, "Peason", "Peason Correlation")
                            ,(False, "MIC", "<s>MIC</s>")
                            ],
          "<div><input type=\"submit\" value=\"plot view\" /></div>",
          "</form>"]


resultPage :: ParamCGI -> [(Message, String, [String])] -> String
resultPage params filenames = resultFrame params $ genePngTable filenames
