module HasKAL.DetectorUtils.Detector
--( Detector
--, LIGOLocation
--)
where

data Detector = DECIGO | ELISA | ET | GEO | INDIGO | KAGRA | LIGO | LIGO_Livingston | LIGO_Hanford | VIRGO | General
  deriving (Show, Eq, Read)

data LIGOLocation = Livingston | Hanford
  deriving (Show, Eq)





