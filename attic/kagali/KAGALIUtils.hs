
module KAGALIUtils
 ( dKGLInferenceSamplefn
  , dKGLIterativeLeastSquare2DNewton
  , nha
  , formatNHA
 ) where

import qualified Data.Vector.Storable as VS (Vector,  length,  unsafeWith,  unsafeFromForeignPtr0, map, slice, fromList)
import Foreign.ForeignPtr (newForeignPtr_)
import Foreign.Ptr
import Foreign.Marshal.Array
import Foreign.C.Types
import System.IO.Unsafe (unsafePerformIO)
import Data.Packed.Matrix (toColumns, fromRows)

{- exposed functions -}
dKGLInferenceSamplefn :: VS.Vector Double  -- ^ Input Vector
                      -> VS.Vector Double  -- ^ Output Vector
dKGLInferenceSamplefn vIn = do
  let vIn' = d2cdV vIn
      ilen = VS.length vIn :: Int
      olen = ilen
  cd2dV $ dKGLInferenceSamplefnCore vIn' ilen olen


dKGLIterativeLeastSquare2DNewton :: VS.Vector Double    -- ^ Input Vector (frame)
                                 -> Double              -- ^ Sampling frequency (fs)
                                 -> Int                 -- ^ # of elements in Onput Vector (nsig)
                                 -> ( VS.Vector Double  -- ^ Output Vector (Afit)
                                    , VS.Vector Double  -- ^ Output Vector (ffit)
                                    , VS.Vector Double) -- ^ Output Vector (pfit)
dKGLIterativeLeastSquare2DNewton frame fs nsig = do 
  let frame' = d2cdV frame
      nframe = VS.length frame :: Int
      fs' = realToFrac fs
  let (out1,out2,out3) = dKGLIterativeLeastSquare2DNewtonCore frame' nframe nsig fs'
   in (cd2dV out1, cd2dV out2, cd2dV out3)


nha :: VS.Vector Double->Double->Double->Double->Int->Int->Int->Int->Int->[(Double, VS.Vector Double, VS.Vector Double, VS.Vector Double)]
nha datV fs fmin fmax nsig nframe nshift nstart nend = retVal
  where retVal = zipWith3 (\v w (x, y, z) -> ((v+w)/2, x, y, z)) tstart tend result
        tstart = map ( (/fs) . fromIntegral ) nIdx
        tend = map ( (/fs) . fromIntegral . (+nframe) ) nIdx
        nIdx = [nstart, nstart + nshift .. nstop]
        nstop = min (VS.length datV - nframe) nend
        result =
          map ( (\frameV -> dKGLIterativeLeastSquare2DNewton frameV fs nsig) . (\kstart -> VS.slice kstart nframe datV) ) nIdx

formatNHA :: [(Double, VS.Vector Double, VS.Vector Double, VS.Vector Double)] -> [[(VS.Vector Double, VS.Vector Double)]]
formatNHA input = output
  where tVec = VS.fromList $ map (\(x, _, _, _) -> x) input
        aVecL = toColumns.fromRows $ map (\(_, y, _, _) -> y) input
        fVecL = toColumns.fromRows $ map (\(_, _, z, _) -> z) input
        pVecL = toColumns.fromRows $ map (\(_, _, _, w) -> w) input
        output = map (map (\vl -> (tVec, vl)) ) [aVecL, fVecL, pVecL]


{- internal functions -}
dKGLInferenceSamplefnCore :: VS.Vector CDouble  -- ^ Input Vector
                          -> Int                -- ^ # of elements in Input Vector
                          -> Int                -- ^ # of elements in Onput Vector
                          -> VS.Vector CDouble  -- ^ Output Vector
dKGLInferenceSamplefnCore input ilen olen
  = unsafePerformIO $ VS.unsafeWith input $ \ptrIn ->
   allocaArray olen $ \ptrOut ->
   do c_DKGLInferenceSamplefn ptrOut (fromIntegral olen) ptrIn (fromIntegral ilen)
      newForeignPtr_ ptrOut >>= \foreignptrOutput ->
         return $ VS.unsafeFromForeignPtr0 foreignptrOutput olen


dKGLIterativeLeastSquare2DNewtonCore :: VS.Vector CDouble       -- ^ Input Vector (frame)
                                     -> Int                     -- ^ # of elements in Input Vector (nframe)
                                     -> Int                     -- ^ # of elements in Output Vector (nsig)
                                     -> CDouble                 -- ^ fs
                                     -> ( VS.Vector CDouble     -- ^ Output Vector (Afit)
                                        , VS.Vector CDouble     -- ^ Output Vector (ffit)
                                        , VS.Vector CDouble)    -- ^ Output Vector (pfit)
dKGLIterativeLeastSquare2DNewtonCore frame' nframe nsig fs'
  = unsafePerformIO $ VS.unsafeWith frame' $ \ptrIn ->
   allocaArray nsig $ \ptrOut1 ->
     allocaArray nsig $ \ptrOut2 ->
       allocaArray nsig $ \ptrOut3 ->
         do c_DKGLIterativeLeastSquare2DNewton ptrOut1 ptrOut2 ptrOut3 ptrIn fs' (fromIntegral nframe) (fromIntegral nsig)
            newForeignPtr_ ptrOut1 >>= \foreignptrOutput1 ->
              newForeignPtr_ ptrOut2 >>= \foreignptrOutput2 ->
                newForeignPtr_ ptrOut3 >>= \foreignptrOutput3 ->
                return $ ( VS.unsafeFromForeignPtr0 foreignptrOutput1 nsig
                         , VS.unsafeFromForeignPtr0 foreignptrOutput2 nsig
                         , VS.unsafeFromForeignPtr0 foreignptrOutput3 nsig)

{-
itow32 :: Int -> CInt
itow32 = fromIntegral
-}


d2cdV :: VS.Vector Double -> VS.Vector CDouble
d2cdV = VS.map realToFrac

cd2dV :: VS.Vector CDouble -> VS.Vector Double
cd2dV = VS.map realToFrac


foreign import ccall "DKGLInferenceSamplefn.h DKGLInferenceSamplefn" c_DKGLInferenceSamplefn :: Ptr CDouble -- ^ input pointer
                                                                                -> CInt        -- ^ # of elements in input
                                                                                -> Ptr CDouble -- ^ output pointer
                                                                                -> CInt        -- ^ # of elements in output
                                                                                -> IO()

foreign import ccall "DKGLIterativeLeastSquare2DNewton.h DKGLIterativeLeastSquare2DNewton" c_DKGLIterativeLeastSquare2DNewton :: Ptr CDouble -- ^ input pointer (frame)
                                                                                -> Ptr CDouble -- ^ output pointer (Afit)
                                                                                -> Ptr CDouble -- ^ output pointer (ffit)
                                                                                -> Ptr CDouble -- ^ output pointer (pfit)
                                                                                -> CDouble     -- ^ fs
                                                                                -> CInt        -- ^ # of elements in input (nframe)
                                                                                -> CInt        -- ^ # of elements in output (nsig)
                                                                                -> IO()
