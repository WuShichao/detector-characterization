{-# LANGUAGE MonadComprehensions, ScopedTypeVariables, MultiParamTypeClasses, FlexibleInstances #-}

module GlitchMon.RegisterGlitchEvent
( registGlitchEvent2DB
)
where


import Control.Monad (forM)
import Data.Int (Int32)
import Data.List (isInfixOf,  (!!))
import Database.HDBC.Session (withConnectionIO, handleSqlError')
import Database.HDBC.Record.Query (runQuery')
import Database.HDBC (quickQuery', runRaw, fromSql, rollback, commit)
import Database.HDBC.Record (runInsertQuery, runInsert)
import Database.HDBC.Query.TH
import Database.Relational.Query ( relation
                                 , value
                                 , InsertQuery
                                 , derivedInsertQuery
                                 , (|$|)
                                 , (|*|)
                                 , Pi
                                 , typedInsert
                                 , Insert
                                 )

import qualified HasKAL.DataBaseUtils.FrameFull.Table as Framedb
import HasKAL.DataBaseUtils.KAGRADataSource (connect)
import HasKAL.FrameUtils.FrameUtils (getGPSTime, getChannelList, getSamplingFrequency)

import System.Environment (getArgs)
import System.Process (rawSystem)

import qualified GlitchMon.Data as D
import GlitchMon.PipelineFunction
import qualified GlitchMon.Table as Glitchdb
import GlitchMon.Table (Glitchtbl(..), insertGlitchtbl)


registGlitchEvent2DB :: D.TrigParam -> IO()
registGlitchEvent2DB p = handleSqlError' $ withConnectionIO connect $ \conn -> do
  runInsert conn insertGlitchtbl $
    Glitchtbl
      0
      (D.detector p)
      (D.event_gpsstarts p)
      (D.event_gpsstartn p)
      (D.event_gpsstops p)
      (D.event_gpsstopn p)
      (D.event_cgpss p)
      (D.event_cgpsn p)
      (D.duration p)
      (D.energy p)
      (D.central_frequency p)
      (D.snr p)
      (D.significance p)
      (D.latitude p)
      (D.longitude p)
      (D.channel p)
      (D.sampling_rate p)
      (D.segment_gpsstarts p)
      (D.segment_gpsstartn p)
      (D.segment_gpsstops p)
      (D.segment_gpsstopn p)
      (D.dq_flag p)
      (D.pipeline p)
  commit conn


setSqlMode conn = do
  mode <- quickQuery' conn "SELECT @@SESSION.sql_mode" []
  newmode <- case mode of
      [[sqlval]] ->
          let val = fromSql sqlval in
              if "IGNORE_SPACE" `isInfixOf` val
                  then return val
                  else return $ val ++ ",IGNORE_SPACE"
      _          ->
          error "failed to get 'sql_mode'"
  runRaw conn $ "SET SESSION sql_mode = '" ++ newmode ++ "'"

