
import Network.CGI
import Data.Maybe (fromJust)
import qualified Data.Vector.Storable as V (maximum)
import Control.Monad (forM, liftM)

import HasKAL.TimeUtils.GPSfunction (getCurrentGps)
import HasKAL.DataBaseUtils.FrameFull.Function (kagraWaveDataGetC)
import HasKAL.MonitorUtils.CorrelationMon.CalCorrelation (takeCorrelationV) 
import HasKAL.WebUtils.CGI.Function
import HasKAL.WaveUtils.Data (WaveData(..))
import SampleChannel

main :: IO ()
main = runCGI $ handleErrors cgiMain

cgiMain :: CGI CGIResult
cgiMain = do
  params <- getInputParams defaultChs
  str <- liftIO $ fork params
  output $ str

fork :: ParamCGI -> IO String
fork params = do
  nowGps <- getCurrentGps
  case (gps params, channel1 params, monitors params) of
   (Nothing, _, _) -> return $ inputForm $ updateMsg "" $ updateGps nowGps params
   (Just "", _, _) -> return $ inputForm $ updateMsg "" $ updateGps nowGps params
   (_, [], _)      -> return $ "<html><body><h1>Any channel is not selected</h1></body></html>"
   (_, _, [])      -> return $ "<html><body><h1>Any monitor is not selected</h1></body></html>"
   (Just x,  _, _)  -> do
     fnames <- process params
     return $ resultPage params fnames
   -- (_, [], []) -> do
   --   let params' = defaultChs ["K1:PEM-EX_ACC_NO2_X_FLOOR","K1:PEM-EX_ACC_NO2_Y_FLOOR"] [] $ defaultMon ["Pearson"] params
   --   fnames <- process params'
   --   return $ resultPage params' fnames
   -- (_, [], _) -> do
   --   let params' = defaultChs ["K1:PEM-EX_ACC_NO2_X_FLOOR","K1:PEM-EX_ACC_NO2_Y_FLOOR"] [] params
   --   fnames <- process params'
   --   return $ resultPage params' fnames
   -- (_, _, []) ->  do
   --   let params' = defaultMon ["Pearson"] params
   --   fnames <- process params'
   --   return $ resultPage params' fnames
   -- (Just x,  _, _) -> do
   --   fnames <- process params
   --   return $ resultPage params fnames

process :: ParamCGI -> IO [(Message, String, [String])]
process params = do
  let gps' = fromJust $ gps params
      duration' = duration params
      fmin' = fmin params
      fmax' = fmax params
      chs = channel1 params
      mon = head $ monitors params
  forM chs $ \ch1 -> do
    mbWd1 <- kagraWaveDataGetC (read gps') (read duration') ch1
    case mbWd1 of
     Nothing -> return ("Can't find channel", ch1, [""])
     Just (wd1:_) -> do
       vals <- forM chs $ \ch2 -> do
         mbWd2 <- kagraWaveDataGetC (read gps') (read duration') ch2
         case (mbWd2, ch1/=ch2) of
          (Nothing, _)         -> return "0"
          (_, False)           -> return "1"
          (Just (wd2:_), True) -> do
            return $ show $ V.maximum $ takeCorrelationV (read mon) (gwdata wd1) (gwdata wd2) 16
       return ("", ch1, vals)

inputForm :: ParamCGI -> String
inputForm params = inputFrame params formbody
  where formbody = concat [
          "<form action=\"", (script params), "\" method=\"GET\" target=\"plotframe\">",
          (dateForm params),
          channelForm params [Multi],
          paramForm [],
          monitorForm Single [(True, Pearson, "Pearson Correlation"),
                              (False, MIC, "<s>MIC</s>")
                             ],
          "<br><center>",
          "<div style=\"padding:15px 15px;",
          "background-color:coral;width:80px;border-radius:20px;\">",
          "<input type=\"submit\" value=\"plot view\" style=\"font-size:16px\"></div>",
          "</center>",
          "</form>"]

resultPage :: ParamCGI -> [(Message, String, [String])] -> String
resultPage params result = resultFrame params (geneChMap params result) 
