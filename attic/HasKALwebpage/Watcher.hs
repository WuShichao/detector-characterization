
module Watcher (watch) where

import Control.Concurrent
import Filesystem (getWorkingDirectory)
import System.FSNotify
import System.Exit
import System.IO.Error
import Filesystem.Path
import Filesystem.Path.CurrentOS (decodeString, encodeString)
import EventDisplayXend
import Data
import System.Process (rawSystem)
watch :: Param -> String -> IO ()
watch param dir = do
--  dir <- getWorkingDirectory
  withManager $ \manager -> do
    watchDir manager (decodeString dir) (const True)
      $ \event -> do rawSystem "./envDisplay" [encodeString $ eventPath event]
                     print "updating webpage"
--      $ \event -> channelPlot' param (encodeString $ eventPath event) >>= genWebPage'

    waitBreak
  where
    waitBreak = do
      _ <- catchIOError getLine (\e -> if isEOFError e then exitSuccess else exitFailure)
      waitBreak

