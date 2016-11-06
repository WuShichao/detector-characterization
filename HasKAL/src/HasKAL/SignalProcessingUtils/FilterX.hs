
{-# LANGUAGE ForeignFunctionInterface #-}

module HasKAL.SignalProcessingUtils.FilterX
  ( calcInitCond
  , filterX
  , filterX1d
  , filtfiltX
  , filtfiltX1d
  ) where

import qualified Data.Vector.Storable as VS (Vector, concat, drop, length, slice, unsafeWith, unsafeFromForeignPtr0,map, fromList, toList, unsafeToForeignPtr0)
import Data.Word
import Foreign.C.Types
import Foreign.C.String
import Foreign.ForeignPtr (ForeignPtr, newForeignPtr_, newForeignPtr, withForeignPtr, mallocForeignPtrArray0, touchForeignPtr)
import Foreign.Ptr
import Foreign.Marshal.Alloc(finalizerFree, free)
import Foreign.Marshal.Array
import HasKAL.Misc.Function (mkChunksV,mkChunksL)
import Numeric.LinearAlgebra (flipud, fromBlocks, fromList, fromColumns, toColumns, fromRows, toRows, ident, scale, toLists, (><), (<\>), dropRows, rows, takeRows, asRow, trans)
import qualified Numeric.LinearAlgebra.Data as ND
import System.IO.Unsafe
import Control.DeepSeq (deepseq, NFData)


data FilterDirection = Reverse | Forward deriving (Show, Eq, Ord)

-- | filtfiltX (num, denom) inputV 
filtfiltX :: ([Double], [Double]) -> [VS.Vector Double] -> [VS.Vector Double]
filtfiltX (num, denom) inputV = 
  let nb = length num
      na = length denom
      order = max nb na
      inputM = fromColumns inputV
      -- Use a reflection to extrapolate signal at beginning and end to reduce edge effects
      nEdge = 3 * (order - 1)
      x1_2 = VS.map (*2) $ head . toRows $ inputM
      xf_2 = VS.map (*2) $ last . toRows $ inputM
      xi''   = fromRows (replicate nEdge x1_2) - (flipud . takeRows nEdge . dropRows 1 $ inputM)
      xi'    = toColumns xi''
      xi    = map VS.toList xi'
      xf''   = fromRows (replicate nEdge xf_2)
               - (flipud . takeRows nEdge . dropRows (rows inputM-nEdge) $ inputM)
      xf'   = toColumns xf''
      xf    = map VS.toList xf'
      -- Filter initial reflected signal:
      ic = ((order-1)><1) $ calcInitCond (num,denom)
      (dum,zi) = filterX (num, denom) (map VS.toList (toColumns (ic * takeRows 1 xi''))) Forward xi'
      -- Use the final conditions of the initial part for the actual signal:
      (ys,zs) = filterX (num, denom) zi Forward inputV -- "s"teady state
      (yf,zdum) = filterX (num, denom) zs Forward xf'  -- "f"inal conditions
      -- Filter signal again in reverse order:
      yEdge = asRow $ (fromColumns yf) ND.! (nEdge-1)
      (dum',zf) = filterX (num, denom) (map VS.toList (toColumns (ic * yEdge))) Reverse yf
   in fst $ filterX (num, denom) zf Reverse ys


filtfiltX1d :: ([Double], [Double]) -> VS.Vector Double -> VS.Vector Double
filtfiltX1d (num, denom) inputV = head $ filtfiltX (num, denom) [inputV]


filterX1d :: ([Double], [Double]) -> [Double] -> FilterDirection -> VS.Vector Double -> (VS.Vector Double,[Double])
filterX1d (num, denom) z dir inputV = let a = filterX (num, denom) [z] dir [inputV]
                                       in (head . fst $ a, head . snd $ a)      


-- | filterX (num, denom) z dir inputV
filterX :: ([Double], [Double]) -> [[Double]] -> FilterDirection -> [VS.Vector Double] -> ([VS.Vector Double], [[Double]])
filterX (num, denom) z dir inputV = unsafePerformIO $ do
  let inputV' = VS.concat $ map d2cdV inputV :: VS.Vector CDouble
      n = length inputV
      m = VS.length . head $ inputV
      mz= length . head $ z
      num' = d2cd num
      denom' = d2cd denom
      blen = length num'
      alen = length denom'
      z' = d2cd . concat $ z
      dir' | dir==Forward = 1 :: Int
           | dir==Reverse = 0 :: Int
  let(vv,zz) = filterXCore num' blen denom' alen z' dir' m n inputV'
  return $(flip mkChunksV m $ cd2dV vv, flip mkChunksL mz $ cd2d zz)


filterXCore :: [CDouble] ->  Int -> [CDouble] ->  Int -> [CDouble] ->  Int -> Int -> Int -> VS.Vector CDouble -> (VS.Vector CDouble, [CDouble])
filterXCore b blen a alen z d m n input
 = unsafePerformIO $ do
   let (fptrInput, ilen) = VS.unsafeToForeignPtr0 input 
   withForeignPtr fptrInput $ \ptrInput ->
    withArray b $ \ptrb ->
    withArray a $ \ptra ->
    withArray z $ \ptrZin -> do
    mallocForeignPtrArray0 ilen >>= \fptrOutput -> withForeignPtr fptrOutput $ \ptrOutput ->
     mallocForeignPtrArray0 zlen >>= \fptrZout -> withForeignPtr fptrZout $ \ptrZout -> do
      c'filter ptrOutput ptrZout ptrb cblen ptra calen ptrInput cm cn ptrZin cd
      a <- return $ VS.unsafeFromForeignPtr0 fptrOutput ilen
      a `deepseq` return ()
      b <- peekArray zlen ptrZout
      b `deepseq` return ()
      return $ (a, b)
       where ilen = m * n
             calen = fromIntegral alen :: CInt
             cblen = fromIntegral blen :: CInt
             cd    = fromIntegral d    :: CInt
             cm    = fromIntegral m    :: CInt
             cn    = fromIntegral n    :: CInt
             zlen  = ((max blen alen)-1) * n


instance NFData CDouble

calcInitCond :: ([Double],[Double]) -> [Double]
calcInitCond (num,denom) =
  let n = length num
      k = ident (n-1)
      kcv= toColumns k
      a = fromList (tail num)
      k' = fromColumns (a:(tail kcv))
      k0 = ((n-1)><(n-1)) (1:replicate ((n-1)*(n-1)-1) 0)
      k''= k' + k0
      y = zip (VS.toList (ND.flatten . trans $ k'')) [0,1..]
      y'= [if i `elem` [(n-1),2*n-1..(n-1)*(n-1)] then -1.0 else x |(x,i)<-y]
   in concat $ toLists $ trans $(trans $ ((n-1)><(n-1)) y') 
        <\> ((((n-1)><1) (tail denom)) - scale (head denom) (((n-1)><1) (tail num))) 


d2cd :: [Double] -> [CDouble]
d2cd = map realToFrac

cd2d :: [CDouble] -> [Double]
cd2d = map realToFrac

d2cdV :: VS.Vector Double -> VS.Vector CDouble
d2cdV = VS.map realToFrac

cd2dV :: VS.Vector CDouble -> VS.Vector Double
cd2dV = VS.map realToFrac


foreign import ccall "filterX.h filter" c'filter :: Ptr CDouble -> Ptr CDouble -> Ptr CDouble -> CInt -> Ptr CDouble -> CInt -> Ptr CDouble -> CInt -> CInt -> Ptr CDouble -> CInt -> IO()

