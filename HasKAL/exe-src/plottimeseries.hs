
import Data.List.Split
import Data.Maybe (fromMaybe)
import qualified Data.Vector.Storable as V
import HasKAL.FrameUtils.Function (readFrameV)
import HasKAL.IOUtils.Function
import HasKAL.PlotUtils.HROOT.PlotGraph
import HasKAL.SignalProcessingUtils.Resampling (resampleSV)
import System.Console.GetOpt
import System.Environment (getArgs)
import System.IO (stdout, hPutStrLn)
import System.IO.Unsafe (unsafePerformIO)


main = do
  {-- parameters --}
  (varOpt, varArgs) <- getArgs >>= \optargs -> 
    case getOpt Permute options optargs of
      (opt, args, []) -> return (Prelude.foldl (flip id) defaultOptions opt, args)
  print varOpt
  print varArgs
  let ch = head varArgs
      fs = read (varArgs !! 1) :: Double
      t0 = read (varArgs !! 2) :: Double
  let resamplePart x | optResample varOpt == "1/1" = x
                     | otherwise = let (p,q) = getPQ (optResample varOpt) 
                                       fs = read (varArgs !! 1) :: Double
                                    in resampleSV (p,q) fs x
      inputPart = case optInput varOpt of
                    Just "stdin" -> unsafePerformIO $ stdin2vec
                    Just f -> let ch = Prelude.head varArgs
                               in fromMaybe (error "cannot read data.") (unsafePerformIO $ readFrameV ch f)
                    Nothing -> error "cannot read data."
      outputPart x = case optOutput varOpt of
                       Just "stdout" -> mapM_ (\y -> hPutStrLn stdout $ show y) (V.toList x) 
                       Just f -> mapM_ (\y -> hPutStrLn stdout $ show y) (V.toList x)
                       Nothing -> error "cannot output."
      xplotPart x = case optXPlot varOpt of
                      False -> return x
                      True -> do
                        let title = ch
                            tv = (V.fromList [t0,t0+1/fs..t0+(fromIntegral (V.length x-1))/fs], x)
                        plotXV Linear Line 1 BLUE ("x", "y") 0.05 title ((0,0),(0,0)) tv
                        return x 
      plotPart x = case optPlot varOpt of
                     [] -> return x
                     f  -> do 
                       let title = ch
                           tv = (V.fromList [t0,t0+1/fs..t0+(fromIntegral (V.length x-1))/fs], x)
                       plotV Linear Line 1 BLUE ("x", "y") 0.05 title f ((0,0),(0,0)) tv 
                       return x
  x1 <- xplotPart . resamplePart $ inputPart
  x2 <- plotPart x1
  outputPart x2

--  outputPart $ inputPart

getPQ x = let a = take 2 $ map (\y-> read y :: Int) $ splitOn "/" x
           in (head a,a!!1)


type RSfactor = String


data Options = Options
 { optResample :: RSfactor
 , optOutput   :: Maybe FilePath
 , optInput    :: Maybe FilePath
 , optXPlot    :: Bool
 , optPlot     :: FilePath
 } deriving (Show)


defaultOptions  = Options
  { optResample = []
  , optOutput   = Nothing
  , optInput    = Nothing
  , optXPlot    = False
  , optPlot     = []
  }


options :: [OptDescr (Options -> Options)]
options = 
  [ Option ['r'] ["resample"]
      ( ReqArg (\ pq opts -> opts { optResample = pq}) "P/Q" )
      "resampling factor P/Q"
  , Option ['o'] ["output"]
      ( OptArg ((\ f opts -> opts {optOutput = Just f}) . fromMaybe "stdout") "FILE" )
      "output FILE"
  , Option ['i'] ["input"]
      ( OptArg ((\ f opts -> opts {optInput = Just f}) . fromMaybe "stdin") "FILE" )
      "input FILE"
  , Option ['X'] ["Xplot"]
      ( NoArg (\ opts -> opts {optXPlot = True}))
      "X plot"
  , Option ['p'] ["plot"]
      ( ReqArg (\p opts -> opts {optPlot = p}) "FILE")
      "plot file"
  ]



