module HasKAL.SignalProcessingUtils.FilterType
where

data FilterType = Low | High | BandPass | BandStop
  deriving (Eq, Show, Read)
