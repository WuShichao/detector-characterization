import qualified Data.Vector.Generic as DVG
import qualified Numeric.LinearAlgebra as NLA
import Data.Maybe (fromMaybe, fromJust)

import System.Environment (getArgs)

import HasKAL.MonitorUtils.CorrelationMon.CalCorrelation
import HasKAL.MonitorUtils.CorrelationMon.CorrelationMethod

main = do

 let data1 = NLA.fromList [1..10] :: NLA.Vector Double
     data2 = NLA.fromList [5,2,3,1,57,4,2,4,5,7] :: NLA.Vector Double
     data3 = NLA.fromList [2,3,1,57,4,2,4,5,7,8,20] :: NLA.Vector Double
--     data3 = NLA.fromList [1,2..] :: NLA.Vector Double
-- problem : if input data is infinite, this functioin does not work. 

 let rValue1 = takeCorrelationV Pearson data1 data2 2
 print rValue1

 let rValue2 = takeCorrelationV Pearson data2 data1 2
 print rValue2

 let rValue3 = takeCorrelationV Pearson data2 data3 2
 print rValue3

 let rValue4 = takeCorrelationV Pearson data3 data2 2
 print rValue4
