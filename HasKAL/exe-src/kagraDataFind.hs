

import HasKAL.DataBaseUtils.Function (kagraDataFind)
import System.Environment (getArgs)
import Data.Int (Int32)
import System.IO (stdout,  hPutStrLn)

main = do
  args <- getArgs
  let gpsstrt = read (head args) :: Int32
      duration = read (args !! 1) :: Int32
      chname = args !! 2 :: String
  statement <- kagraDataFind gpsstrt duration chname
  case statement of
    Nothing -> print "Nothing"
    Just x -> mapM_ (hPutStrLn stdout) x





