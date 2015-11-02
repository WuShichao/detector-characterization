
import Network.CGI
import Data.Maybe (fromJust)
import qualified Data.Vector.Storable as V (maximum)
import Control.Monad (forM, liftM)

import HasKAL.TimeUtils.GPSfunction (getCurrentGps)
import HasKAL.DataBaseUtils.Function (kagraDataGet, kagraDataFind)
import HasKAL.FrameUtils.FrameUtils (getSamplingFrequency)
import HasKAL.MonitorUtils.CorrelationMon.CalCorrelation (takeCorrelationV) 
import HasKAL.WebUtils.CGI.Function


main :: IO ()
main = runCGI $ handleErrors cgiMain

cgiMain :: CGI CGIResult
cgiMain = do
  params <- getInputParams
  str <- liftIO $ fork params
  output $ str

fork :: ParamCGI -> IO String
fork params = do
  nowGps <- return $ show 1120543424 -- getCurrentGps
  case (gps params, channel1 params, monitors params) of
   (Nothing, _, _) -> return $ inputDateForm $ updateMsg "" $ updateGps nowGps params
   (Just "", _, _) -> return $ inputDateForm $ updateMsg "" $ updateGps nowGps params
   (_, [], []) -> do
     let params' = defaultMon ["Peason"] $ defaultChs ["K1:PEM-EX_ACC_NO2_X_FLOOR","K1:PEM-EX_ACC_NO2_Y_FLOOR"] params
     fnames <- process params'
     return $ resultPage params' fnames
   (_, [], _) -> do
     let params' = defaultChs ["K1:PEM-EX_ACC_NO2_X_FLOOR","K1:PEM-EX_ACC_NO2_Y_FLOOR"] params
     fnames <- process params'
     return $ resultPage params' fnames
   (_, _, []) ->  do
     let params' = defaultMon ["Peason"] params
     fnames <- process params'
     return $ resultPage params' fnames
   (Just x,  _, _) -> do
     fnames <- process params
     return $ resultPage params fnames

defaultChs :: [String] -> ParamCGI -> ParamCGI
defaultChs defch params =
  ParamCGI { script = script params
           , message = message params
           , files = files params
           , lstfile = lstfile params
           , chlist = chlist params
           , gps = gps params
           , locale = locale params
           , channel1 = defch
           , channel2 = channel2 params
           , monitors = monitors params
           , duration = duration params
           , fmin = fmin params
           , fmax = fmax params
           }

defaultMon :: [String] -> ParamCGI -> ParamCGI
defaultMon defmon params =
  ParamCGI { script = script params
           , message = message params
           , files = files params
           , lstfile = lstfile params
           , chlist = chlist params
           , gps = gps params
           , locale = locale params
           , channel1 = channel1 params
           , channel2 = channel2 params
           , monitors = defmon
           , duration = duration params
           , fmin = fmin params
           , fmax = fmax params
           } 

process :: ParamCGI -> IO [(Message, String, [String])]
process params = do
  let gps' = fromJust $ gps params
      duration' = duration params
      fmin' = fmin params
      fmax' = fmax params
      chs = channel1 params
      mon = head $ monitors params
  forM chs $ \ch1 -> do
    datMaybe <- kagraDataGet (read gps') (read duration') ch1
    case datMaybe of
     Nothing -> return ("Can't find channel", ch1, [""])
     _       -> do
       fs1 <- liftM fromJust $ (`getSamplingFrequency` ch1) =<< liftM (head.fromJust) (kagraDataFind (read gps') (read duration') ch1)
       vals <- forM chs $ \ch2 -> do
         datMaybe2 <- kagraDataGet (read gps') (read duration') ch2
         case (datMaybe2, ch1/=ch2) of
          (Nothing, _) -> return "0"
          (_, False)   -> return "1"
          (_, True)    -> do
            fs2 <- liftM fromJust $ (`getSamplingFrequency` ch2) =<< liftM (head.fromJust) (kagraDataFind (read gps') (read duration') ch2)
            return $ show $ V.maximum $ takeCorrelationV (read $ mon) (fromJust datMaybe) (fromJust datMaybe2) 16
       return ("", ch1, vals)

inputDateForm :: ParamCGI -> String
inputDateForm params = inputDateHeader dateformbody
  where dateformbody = concat [
          "<form action=\"", (script params), "\" method=\"GET\" target=\"plotframe\">",
          (dateForm'' params),
          "<div><input type=\"submit\" value=\"plot view\" /></div>",
          "</form>"
          ]
        inputDateHeader x = concat [
          "<html><head><title>Date</title></head>",
          "<body><h1>Date</h1>",x,"</body></html>"
          ]

resultPage :: ParamCGI -> [(Message, String, [String])] -> String
resultPage params result = resultFrame' params (geneChMap params result) (inputForm params)

inputForm :: ParamCGI -> String
inputForm params = inputFrame params formbody
  where formbody = concat [
          "<br><form action=\"", (script params), "\" method=\"GET\" target=\"plotframe\">",
          "<div style=\"background: #EFEFEF; border: 1px solid #CC0000; height:100％;",
          "padding-left:10px; padding-right:10px; padding-top:10px; padding-bottom:10px;\">",
          timeForm' params,
          "<div style=\"float:left; margin-right:50\">", channelForm params [Multi], "</div>",
          "<div style=\"float:left;\">", paramForm [], "</div>",
          "<div style=\"clear:both;\"></div><br>",
          monitorForm Single [(True, Peason, "Peason Correlation"),
                              (False, MIC, "<s>MIC</s>")
                             ],
          "<div><input type=\"submit\" value=\"plot view\" /></div>",
          "</div></form>"]

