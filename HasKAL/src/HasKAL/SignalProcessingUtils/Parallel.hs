


module HasKAL.SignalProcessingUtils.Parallel
( tf2cparallel
, tf2rparallel
) where


import Data.List
import Data.Maybe (fromJust)
import HasKAL.MathUtils.LinearAlgebra (polyval, toeplitz)
import Numeric.LinearAlgebra
import Numeric.GSL.Polynomials(polySolve)


tf2rparallel :: ([Double], [Double]) -> ([Double], [([Double], [Double])])
tf2rparallel (num, denom) =
  let (c, gain, alpha) = tf2cparallel (num, denom)
   in (c, func gain alpha)
   where
     func :: [Complex Double] -> [Complex Double] -> [([Double], [Double])]
     func _ [] = []
     func gain alpha =
       let hal = head alpha
           hA  = head gain
        in case (imagPart hal ==0) of
             False -> ([2*realPart hA, -2*realPart (hA * conjugate hal)]
               , [1, -2*realPart hal, realPart (abs hal)**2]) : func (drop 2 gain) (drop 2 alpha)
             True  -> ([realPart hA, 0], [1, -1*realPart hal, 0]) : func (tail gain) (tail alpha)


tf2cparallel :: ([Double], [Double]) -> ([Double], [Complex Double], [Complex Double])
tf2cparallel (num', denom') = do
  let num = map (/head denom') num'
      denom = map (/head denom') denom'
      p = length denom - 1
      q = length num - 1
      (c, d) = case (q >= p) of
        True ->
          let temp = toeplitz (denom ++ replicate (q-p) (0::Double))
                (head denom : replicate (q-p) (0::Double))
              tempM = fromColumns $ map fromList temp
              numM = ((q+1) >< 1) num
              denomM = ((p+1) >< 1) denom
              zeros = replicate (q-p+1) (fromList $ replicate p (0::Double))
              eye = ident p :: Matrix Double
              temp' = fromBlocks [[tempM, fromRows (toRows eye ++ zeros)]]
              temp''= temp' <\> numM
              c = toList . head . toColumns $ subMatrix (0, 0) (q-p+1, 1) temp''
              d' = toList . head . toColumns $ subMatrix (q-p+1, 0) (p, 1) temp''
           in (c, d2clist d')
        False ->
          let c = []
              d' = num ++ replicate (p-q-1) (0::Double)
           in (c, d2clist d')

  let alpha = polySolve $ reverse denom
      gpf = map go [0..length alpha -1]
        where
          go i =
            let scale = product [alpha!!i - x | x <- alpha, x /= alpha!!i]
             in polyval (reverse d) (alpha!!i) / scale
   in (c, gpf, alpha)


d2clist :: [Double] -> [Complex Double]
d2clist xs = map :+0 xs

