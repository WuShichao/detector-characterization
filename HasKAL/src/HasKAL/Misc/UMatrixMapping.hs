{-******************************************
  *     File Name: UMatrixMapping.hs
  *        Author: Takahiro Yamamoto
  * Last Modified: 2014/12/05 16:35:12
  *******************************************-}

-- map functions for Unboxed Matrix
module HasKAL.Misc.UMatrixMapping (
   convertS2U
  ,convertU2S
  ,mapRows0
  ,mapCols0
  ,mapRows1
  ,mapCols1
) where


import qualified Control.Monad as CM (forM)
import System.IO.Unsafe (unsafePerformIO)

{-- Unbox type --}
import Data.Vector.Unboxed
import Data.Matrix.Unboxed

{-- Storable type --}
import qualified Data.Packed.Matrix as M


{-- matrix type converter --}
convertS2U :: (M.Element a, Unbox a) => M.Matrix a -> Matrix a
convertS2U mat = fromVector rowNum colNum $ convert $ M.flatten mat
  where rowNum = M.rows mat
        colNum = M.cols mat

convertU2S :: (Unbox a, M.Element a) => Matrix a -> M.Matrix a
convertU2S mat = M.reshape colNum $ convert $ flatten mat
  where colNum = cols mat


{-- map functions --}
mapRows0 :: (Unbox a) => (Vector a -> a) -> Matrix a -> Vector a
mapRows0 fx mat = unsafePerformIO $ forM idxV $ \idx -> return $ fx $ takeRow idx mat
  where idxV = fromList [0..(rows mat)-1]

mapCols0 :: (Unbox a) => (Vector a -> a) -> Matrix a -> Vector a
mapCols0 fx mat = unsafePerformIO $ forM idxV $ \idx -> return $ fx $ takeColumn idx mat
  where idxV = fromList [0..(cols mat)-1]

mapRows1 :: (Unbox a) => (Vector a -> Vector a -> Vector a) -> Vector a -> Matrix a -> Matrix a
mapRows1 fx vec mat = fromRows $ unsafePerformIO $ CM.forM idxL $ \idx -> return $ fx vec $ takeRow idx mat
  where idxL = [0..(rows mat)-1]

mapCols1 :: (Unbox a) => (Vector a -> Vector a -> Vector a) -> Vector a -> Matrix a -> Matrix a
mapCols1 fx vec mat = fromColumns $ unsafePerformIO $ CM.forM idxL $ \idx -> return $ fx vec $ takeColumn idx mat
  where idxL = [0..(cols mat)-1]
        
        
