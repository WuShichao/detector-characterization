{- |
Module      : ReadFiles
Description : This is documentation tests.
Copyright   : (c) WhoAmI, 2014
License     : ???
Maintainer  : Takahiro Yamamoto %mail%
Stability   : test
Portability : POSIX
GUI of Antenna Pattern
-}{-
  * Last Modified: 2015/02/19 17:03:11
-}


module ReadFiles (
  run007files
) where

run007files :: [String]
run007files = ["/data/RUN007/R0007F0000000003.gwf"
              ,"/data/RUN007/R0007F0000000004.gwf"
              ,"/data/RUN007/R0007F0000000005.gwf"
              ,"/data/RUN007/R0007F0000000006.gwf"
              ,"/data/RUN007/R0007F0000000007.gwf"
              ,"/data/RUN007/R0007F0000000008.gwf"
              ,"/data/RUN007/R0007F0000000009.gwf"
              ,"/data/RUN007/R0007F0000000010.gwf"
              ,"/data/RUN007/R0007F0000000011.gwf"
              ,"/data/RUN007/R0007F0000000012.gwf"
              ,"/data/RUN007/R0007F0000000013.gwf"
              ,"/data/RUN007/R0007F0000000014.gwf"
              ,"/data/RUN007/R0007F0000000015.gwf"
              ,"/data/RUN007/R0007F0000000016.gwf"
              ,"/data/RUN007/R0007F0000000017.gwf"
              ,"/data/RUN007/R0007F0000000018.gwf"
              ,"/data/RUN007/R0007F0000000019.gwf"
              ,"/data/RUN007/R0007F0000000020.gwf"
              ,"/data/RUN007/R0007F0000000021.gwf"
              ,"/data/RUN007/R0007F0000000022.gwf"
              ,"/data/RUN007/R0007F0000000023.gwf"
              ,"/data/RUN007/R0007F0000000024.gwf"
              ,"/data/RUN007/R0007F0000000025.gwf"
              ,"/data/RUN007/R0007F0000000026.gwf"
              ,"/data/RUN007/R0007F0000000027.gwf"
              ,"/data/RUN007/R0007F0000000028.gwf"
              ,"/data/RUN007/R0007F0000000029.gwf"
              ,"/data/RUN007/R0007F0000000030.gwf"
              ,"/data/RUN007/R0007F0000000031.gwf"
              ,"/data/RUN007/R0007F0000000032.gwf"
              ,"/data/RUN007/R0007F0000000033.gwf"
              ,"/data/RUN007/R0007F0000000034.gwf"
              ,"/data/RUN007/R0007F0000000035.gwf"
              ,"/data/RUN007/R0007F0000000036.gwf"
              ,"/data/RUN007/R0007F0000000037.gwf"
              ,"/data/RUN007/R0007F0000000038.gwf"
              ,"/data/RUN007/R0007F0000000039.gwf"
              ,"/data/RUN007/R0007F0000000040.gwf"
              ,"/data/RUN007/R0007F0000000041.gwf"
              ,"/data/RUN007/R0007F0000000042.gwf"
              ,"/data/RUN007/R0007F0000000043.gwf"
              ,"/data/RUN007/R0007F0000000044.gwf"
              ,"/data/RUN007/R0007F0000000045.gwf"
              ,"/data/RUN007/R0007F0000000046.gwf"
              ,"/data/RUN007/R0007F0000000047.gwf"
              ,"/data/RUN007/R0007F0000000048.gwf"
              ,"/data/RUN007/R0007F0000000049.gwf"
              ,"/data/RUN007/R0007F0000000050.gwf"
              ,"/data/RUN007/R0007F0000000051.gwf"
              ,"/data/RUN007/R0007F0000000052.gwf"
              ,"/data/RUN007/R0007F0000000053.gwf"
              ,"/data/RUN007/R0007F0000000054.gwf"
              ,"/data/RUN007/R0007F0000000055.gwf"
              ,"/data/RUN007/R0007F0000000056.gwf"
              ,"/data/RUN007/R0007F0000000057.gwf"
              ,"/data/RUN007/R0007F0000000058.gwf"
              ,"/data/RUN007/R0007F0000000059.gwf"
              ,"/data/RUN007/R0007F0000000060.gwf"
              ,"/data/RUN007/R0007F0000000061.gwf"
              ,"/data/RUN007/R0007F0000000062.gwf"
              ,"/data/RUN007/R0007F0000000063.gwf"
              ,"/data/RUN007/R0007F0000000064.gwf"
              ,"/data/RUN007/R0007F0000000065.gwf"
              ,"/data/RUN007/R0007F0000000066.gwf"
              ,"/data/RUN007/R0007F0000000067.gwf"
              ,"/data/RUN007/R0007F0000000068.gwf"
              ,"/data/RUN007/R0007F0000000069.gwf"
              ,"/data/RUN007/R0007F0000000070.gwf"
              ,"/data/RUN007/R0007F0000000071.gwf"
              ,"/data/RUN007/R0007F0000000072.gwf"
              ,"/data/RUN007/R0007F0000000073.gwf"
              ,"/data/RUN007/R0007F0000000074.gwf"
              ,"/data/RUN007/R0007F0000000075.gwf"
              ,"/data/RUN007/R0007F0000000076.gwf"
              ,"/data/RUN007/R0007F0000000077.gwf"
              ,"/data/RUN007/R0007F0000000078.gwf"
              ,"/data/RUN007/R0007F0000000079.gwf"
              ,"/data/RUN007/R0007F0000000080.gwf"
              ,"/data/RUN007/R0007F0000000081.gwf"
              ,"/data/RUN007/R0007F0000000082.gwf"
              ,"/data/RUN007/R0007F0000000083.gwf"
              ,"/data/RUN007/R0007F0000000084.gwf"
              ,"/data/RUN007/R0007F0000000085.gwf"
              ,"/data/RUN007/R0007F0000000086.gwf"
              ,"/data/RUN007/R0007F0000000087.gwf"
              ,"/data/RUN007/R0007F0000000088.gwf"
              ,"/data/RUN007/R0007F0000000089.gwf"
              ,"/data/RUN007/R0007F0000000090.gwf"
              ,"/data/RUN007/R0007F0000000091.gwf"
              ,"/data/RUN007/R0007F0000000092.gwf"
              ,"/data/RUN007/R0007F0000000093.gwf"
              ,"/data/RUN007/R0007F0000000094.gwf"
              ,"/data/RUN007/R0007F0000000095.gwf"
              ,"/data/RUN007/R0007F0000000096.gwf"
              ,"/data/RUN007/R0007F0000000097.gwf"
              ,"/data/RUN007/R0007F0000000098.gwf"
              ,"/data/RUN007/R0007F0000000099.gwf"
              ,"/data/RUN007/R0007F0000000100.gwf"
              ,"/data/RUN007/R0007F0000000101.gwf"
              ,"/data/RUN007/R0007F0000000102.gwf"
              ,"/data/RUN007/R0007F0000000103.gwf"
              ,"/data/RUN007/R0007F0000000104.gwf"
              ,"/data/RUN007/R0007F0000000105.gwf"
              ,"/data/RUN007/R0007F0000000106.gwf"
              ,"/data/RUN007/R0007F0000000107.gwf"
              ,"/data/RUN007/R0007F0000000108.gwf"
              ,"/data/RUN007/R0007F0000000109.gwf"
              ,"/data/RUN007/R0007F0000000110.gwf"
              ,"/data/RUN007/R0007F0000000111.gwf"
              ,"/data/RUN007/R0007F0000000112.gwf"
              ,"/data/RUN007/R0007F0000000113.gwf"
              ,"/data/RUN007/R0007F0000000114.gwf"
              ,"/data/RUN007/R0007F0000000115.gwf"
              ,"/data/RUN007/R0007F0000000116.gwf"
              ,"/data/RUN007/R0007F0000000117.gwf"
              ,"/data/RUN007/R0007F0000000118.gwf"
              ,"/data/RUN007/R0007F0000000119.gwf"
              ,"/data/RUN007/R0007F0000000120.gwf"
              ,"/data/RUN007/R0007F0000000121.gwf"
              ,"/data/RUN007/R0007F0000000122.gwf"
              ,"/data/RUN007/R0007F0000000123.gwf"
              ,"/data/RUN007/R0007F0000000124.gwf"
              ,"/data/RUN007/R0007F0000000125.gwf"
              ,"/data/RUN007/R0007F0000000126.gwf"
              ,"/data/RUN007/R0007F0000000127.gwf"
              ,"/data/RUN007/R0007F0000000128.gwf"
              ,"/data/RUN007/R0007F0000000129.gwf"
              ,"/data/RUN007/R0007F0000000130.gwf"
              ,"/data/RUN007/R0007F0000000131.gwf"
              ,"/data/RUN007/R0007F0000000132.gwf"
              ,"/data/RUN007/R0007F0000000133.gwf"
              ,"/data/RUN007/R0007F0000000134.gwf"
              ,"/data/RUN007/R0007F0000000135.gwf"
              ,"/data/RUN007/R0007F0000000136.gwf"
              ,"/data/RUN007/R0007F0000000137.gwf"
              ,"/data/RUN007/R0007F0000000138.gwf"
              ,"/data/RUN007/R0007F0000000139.gwf"
              ,"/data/RUN007/R0007F0000000140.gwf"
              ,"/data/RUN007/R0007F0000000141.gwf"
              ,"/data/RUN007/R0007F0000000142.gwf"
              ,"/data/RUN007/R0007F0000000143.gwf"
              ,"/data/RUN007/R0007F0000000144.gwf"
              ,"/data/RUN007/R0007F0000000145.gwf"
              ,"/data/RUN007/R0007F0000000146.gwf"
              ,"/data/RUN007/R0007F0000000147.gwf"
              ,"/data/RUN007/R0007F0000000148.gwf"
              ,"/data/RUN007/R0007F0000000149.gwf"
              ,"/data/RUN007/R0007F0000000150.gwf"
              ,"/data/RUN007/R0007F0000000151.gwf"
              ,"/data/RUN007/R0007F0000000152.gwf"
              ,"/data/RUN007/R0007F0000000153.gwf"
              ,"/data/RUN007/R0007F0000000154.gwf"
              ,"/data/RUN007/R0007F0000000155.gwf"
              ,"/data/RUN007/R0007F0000000156.gwf"
              ,"/data/RUN007/R0007F0000000157.gwf"
              ,"/data/RUN007/R0007F0000000158.gwf"
              ,"/data/RUN007/R0007F0000000159.gwf"
              ,"/data/RUN007/R0007F0000000160.gwf"
              ,"/data/RUN007/R0007F0000000161.gwf"
              ,"/data/RUN007/R0007F0000000162.gwf"
              ,"/data/RUN007/R0007F0000000163.gwf"
              ,"/data/RUN007/R0007F0000000164.gwf"
              ,"/data/RUN007/R0007F0000000165.gwf"
              ,"/data/RUN007/R0007F0000000166.gwf"
              ,"/data/RUN007/R0007F0000000167.gwf"
              ,"/data/RUN007/R0007F0000000168.gwf"
              ,"/data/RUN007/R0007F0000000169.gwf"
              ,"/data/RUN007/R0007F0000000170.gwf"
              ,"/data/RUN007/R0007F0000000171.gwf"
              ,"/data/RUN007/R0007F0000000172.gwf"
              ,"/data/RUN007/R0007F0000000173.gwf"
              ,"/data/RUN007/R0007F0000000174.gwf"
              ,"/data/RUN007/R0007F0000000175.gwf"
              ,"/data/RUN007/R0007F0000000176.gwf"
              ,"/data/RUN007/R0007F0000000177.gwf"
              ,"/data/RUN007/R0007F0000000178.gwf"
              ,"/data/RUN007/R0007F0000000179.gwf"
              ,"/data/RUN007/R0007F0000000180.gwf"
              ,"/data/RUN007/R0007F0000000181.gwf"
              ,"/data/RUN007/R0007F0000000182.gwf"
              ,"/data/RUN007/R0007F0000000183.gwf"
              ,"/data/RUN007/R0007F0000000184.gwf"
              ,"/data/RUN007/R0007F0000000185.gwf"
              ,"/data/RUN007/R0007F0000000186.gwf"
              ,"/data/RUN007/R0007F0000000187.gwf"
              ,"/data/RUN007/R0007F0000000188.gwf"
              ,"/data/RUN007/R0007F0000000189.gwf"
              ,"/data/RUN007/R0007F0000000190.gwf"
              ,"/data/RUN007/R0007F0000000191.gwf"
              ,"/data/RUN007/R0007F0000000192.gwf"
              ,"/data/RUN007/R0007F0000000193.gwf"
              ,"/data/RUN007/R0007F0000000194.gwf"
              ,"/data/RUN007/R0007F0000000195.gwf"
              ,"/data/RUN007/R0007F0000000196.gwf"
              ,"/data/RUN007/R0007F0000000197.gwf"
              ,"/data/RUN007/R0007F0000000198.gwf"
              ,"/data/RUN007/R0007F0000000199.gwf"
              ,"/data/RUN007/R0007F0000000200.gwf"
              ,"/data/RUN007/R0007F0000000201.gwf"
              ,"/data/RUN007/R0007F0000000202.gwf"
              ,"/data/RUN007/R0007F0000000203.gwf"
              ,"/data/RUN007/R0007F0000000204.gwf"
              ,"/data/RUN007/R0007F0000000205.gwf"
              ,"/data/RUN007/R0007F0000000206.gwf"
              ,"/data/RUN007/R0007F0000000207.gwf"
              ,"/data/RUN007/R0007F0000000208.gwf"
              ,"/data/RUN007/R0007F0000000209.gwf"
              ,"/data/RUN007/R0007F0000000210.gwf"
              ,"/data/RUN007/R0007F0000000211.gwf"
              ,"/data/RUN007/R0007F0000000212.gwf"
              ,"/data/RUN007/R0007F0000000213.gwf"
              ,"/data/RUN007/R0007F0000000214.gwf"
              ,"/data/RUN007/R0007F0000000215.gwf"
              ,"/data/RUN007/R0007F0000000216.gwf"
              ,"/data/RUN007/R0007F0000000217.gwf"
              ,"/data/RUN007/R0007F0000000218.gwf"
              ,"/data/RUN007/R0007F0000000219.gwf"
              ,"/data/RUN007/R0007F0000000220.gwf"
              ,"/data/RUN007/R0007F0000000221.gwf"
              ,"/data/RUN007/R0007F0000000222.gwf"
              ,"/data/RUN007/R0007F0000000223.gwf"
              ,"/data/RUN007/R0007F0000000224.gwf"
              ,"/data/RUN007/R0007F0000000225.gwf"
              ,"/data/RUN007/R0007F0000000226.gwf"
              ,"/data/RUN007/R0007F0000000227.gwf"
              ,"/data/RUN007/R0007F0000000228.gwf"
              ,"/data/RUN007/R0007F0000000229.gwf"
              ,"/data/RUN007/R0007F0000000230.gwf"
              ,"/data/RUN007/R0007F0000000231.gwf"
              ,"/data/RUN007/R0007F0000000232.gwf"
              ,"/data/RUN007/R0007F0000000233.gwf"
              ,"/data/RUN007/R0007F0000000234.gwf"
              ,"/data/RUN007/R0007F0000000235.gwf"
              ,"/data/RUN007/R0007F0000000236.gwf"
              ,"/data/RUN007/R0007F0000000237.gwf"
              ,"/data/RUN007/R0007F0000000238.gwf"
              ,"/data/RUN007/R0007F0000000239.gwf"
              ,"/data/RUN007/R0007F0000000240.gwf"
              ,"/data/RUN007/R0007F0000000241.gwf"
              ,"/data/RUN007/R0007F0000000242.gwf"
              ,"/data/RUN007/R0007F0000000243.gwf"
              ,"/data/RUN007/R0007F0000000244.gwf"
              ,"/data/RUN007/R0007F0000000245.gwf"
              ,"/data/RUN007/R0007F0000000246.gwf"
              ,"/data/RUN007/R0007F0000000247.gwf"
              ,"/data/RUN007/R0007F0000000248.gwf"
              ,"/data/RUN007/R0007F0000000249.gwf"
              ,"/data/RUN007/R0007F0000000250.gwf"
              ,"/data/RUN007/R0007F0000000251.gwf"
              ,"/data/RUN007/R0007F0000000252.gwf"
              ,"/data/RUN007/R0007F0000000253.gwf"
              ,"/data/RUN007/R0007F0000000254.gwf"
              ,"/data/RUN007/R0007F0000000255.gwf"
              ,"/data/RUN007/R0007F0000000256.gwf"
              ,"/data/RUN007/R0007F0000000257.gwf"
              ,"/data/RUN007/R0007F0000000258.gwf"
              ,"/data/RUN007/R0007F0000000259.gwf"
              ,"/data/RUN007/R0007F0000000260.gwf"
              ,"/data/RUN007/R0007F0000000261.gwf"
              ,"/data/RUN007/R0007F0000000262.gwf"
              ,"/data/RUN007/R0007F0000000263.gwf"
              ,"/data/RUN007/R0007F0000000264.gwf"
              ,"/data/RUN007/R0007F0000000265.gwf"
              ,"/data/RUN007/R0007F0000000266.gwf"
              ,"/data/RUN007/R0007F0000000267.gwf"
              ,"/data/RUN007/R0007F0000000268.gwf"
              ,"/data/RUN007/R0007F0000000269.gwf"
              ,"/data/RUN007/R0007F0000000270.gwf"
              ,"/data/RUN007/R0007F0000000271.gwf"
              ,"/data/RUN007/R0007F0000000272.gwf"
              ,"/data/RUN007/R0007F0000000273.gwf"
              ,"/data/RUN007/R0007F0000000274.gwf"
              ,"/data/RUN007/R0007F0000000275.gwf"
              ,"/data/RUN007/R0007F0000000276.gwf"
              ,"/data/RUN007/R0007F0000000277.gwf"
              ,"/data/RUN007/R0007F0000000278.gwf"
              ,"/data/RUN007/R0007F0000000279.gwf"
              ,"/data/RUN007/R0007F0000000280.gwf"
              ,"/data/RUN007/R0007F0000000281.gwf"
              ,"/data/RUN007/R0007F0000000282.gwf"
              ,"/data/RUN007/R0007F0000000283.gwf"
              ,"/data/RUN007/R0007F0000000284.gwf"
              ,"/data/RUN007/R0007F0000000285.gwf"
              ,"/data/RUN007/R0007F0000000286.gwf"
              ,"/data/RUN007/R0007F0000000287.gwf"
              ,"/data/RUN007/R0007F0000000288.gwf"
              ,"/data/RUN007/R0007F0000000289.gwf"
              ,"/data/RUN007/R0007F0000000290.gwf"
              ,"/data/RUN007/R0007F0000000291.gwf"
              ,"/data/RUN007/R0007F0000000292.gwf"
              ,"/data/RUN007/R0007F0000000293.gwf"
              ,"/data/RUN007/R0007F0000000294.gwf"
              ,"/data/RUN007/R0007F0000000295.gwf"
              ,"/data/RUN007/R0007F0000000296.gwf"
              ,"/data/RUN007/R0007F0000000297.gwf"
              ,"/data/RUN007/R0007F0000000298.gwf"
              ,"/data/RUN007/R0007F0000000299.gwf"
              ,"/data/RUN007/R0007F0000000300.gwf"
              ,"/data/RUN007/R0007F0000000301.gwf"
              ,"/data/RUN007/R0007F0000000302.gwf"
              ,"/data/RUN007/R0007F0000000303.gwf"
              ,"/data/RUN007/R0007F0000000304.gwf"
              ,"/data/RUN007/R0007F0000000305.gwf"
              ,"/data/RUN007/R0007F0000000306.gwf"
              ,"/data/RUN007/R0007F0000000307.gwf"
              ,"/data/RUN007/R0007F0000000308.gwf"
              ,"/data/RUN007/R0007F0000000309.gwf"
              ,"/data/RUN007/R0007F0000000310.gwf"
              ,"/data/RUN007/R0007F0000000311.gwf"
              ,"/data/RUN007/R0007F0000000312.gwf"
              ,"/data/RUN007/R0007F0000000313.gwf"
              ,"/data/RUN007/R0007F0000000314.gwf"
              ,"/data/RUN007/R0007F0000000315.gwf"
              ,"/data/RUN007/R0007F0000000316.gwf"
              ,"/data/RUN007/R0007F0000000317.gwf"
              ,"/data/RUN007/R0007F0000000318.gwf"
              ,"/data/RUN007/R0007F0000000319.gwf"
              ,"/data/RUN007/R0007F0000000320.gwf"
              ,"/data/RUN007/R0007F0000000321.gwf"
              ,"/data/RUN007/R0007F0000000322.gwf"
              ,"/data/RUN007/R0007F0000000323.gwf"
              ,"/data/RUN007/R0007F0000000324.gwf"
              ,"/data/RUN007/R0007F0000000325.gwf"
              ,"/data/RUN007/R0007F0000000326.gwf"
              ,"/data/RUN007/R0007F0000000327.gwf"
              ,"/data/RUN007/R0007F0000000328.gwf"
              ,"/data/RUN007/R0007F0000000329.gwf"
              ,"/data/RUN007/R0007F0000000330.gwf"
              ,"/data/RUN007/R0007F0000000331.gwf"
              ,"/data/RUN007/R0007F0000000332.gwf"
              ,"/data/RUN007/R0007F0000000333.gwf"
              ,"/data/RUN007/R0007F0000000334.gwf"
              ,"/data/RUN007/R0007F0000000335.gwf"
              ,"/data/RUN007/R0007F0000000336.gwf"
              ,"/data/RUN007/R0007F0000000337.gwf"
              ,"/data/RUN007/R0007F0000000338.gwf"
              ,"/data/RUN007/R0007F0000000339.gwf"
              ,"/data/RUN007/R0007F0000000340.gwf"
              ,"/data/RUN007/R0007F0000000341.gwf"
              ,"/data/RUN007/R0007F0000000342.gwf"
              ,"/data/RUN007/R0007F0000000343.gwf"
              ,"/data/RUN007/R0007F0000000344.gwf"
              ,"/data/RUN007/R0007F0000000345.gwf"
              ,"/data/RUN007/R0007F0000000346.gwf"
              ,"/data/RUN007/R0007F0000000347.gwf"
              ,"/data/RUN007/R0007F0000000348.gwf"
              ,"/data/RUN007/R0007F0000000349.gwf"
              ,"/data/RUN007/R0007F0000000350.gwf"
              ,"/data/RUN007/R0007F0000000351.gwf"
              ,"/data/RUN007/R0007F0000000352.gwf"
              ,"/data/RUN007/R0007F0000000353.gwf"
              ,"/data/RUN007/R0007F0000000354.gwf"
              ,"/data/RUN007/R0007F0000000355.gwf"
              ,"/data/RUN007/R0007F0000000356.gwf"
              ,"/data/RUN007/R0007F0000000357.gwf"
              ,"/data/RUN007/R0007F0000000358.gwf"
              ,"/data/RUN007/R0007F0000000359.gwf"
              ,"/data/RUN007/R0007F0000000360.gwf"
              ,"/data/RUN007/R0007F0000000361.gwf"
              ,"/data/RUN007/R0007F0000000362.gwf"
              ,"/data/RUN007/R0007F0000000363.gwf"
              ,"/data/RUN007/R0007F0000000364.gwf"
              ,"/data/RUN007/R0007F0000000365.gwf"
              ,"/data/RUN007/R0007F0000000366.gwf"
              ,"/data/RUN007/R0007F0000000367.gwf"
              ,"/data/RUN007/R0007F0000000368.gwf"
              ,"/data/RUN007/R0007F0000000369.gwf"
              ,"/data/RUN007/R0007F0000000370.gwf"
              ,"/data/RUN007/R0007F0000000371.gwf"
              ,"/data/RUN007/R0007F0000000372.gwf"
              ,"/data/RUN007/R0007F0000000373.gwf"
              ,"/data/RUN007/R0007F0000000374.gwf"
              ,"/data/RUN007/R0007F0000000375.gwf"
              ,"/data/RUN007/R0007F0000000376.gwf"
              ,"/data/RUN007/R0007F0000000377.gwf"
              ,"/data/RUN007/R0007F0000000378.gwf"
              ,"/data/RUN007/R0007F0000000379.gwf"
              ,"/data/RUN007/R0007F0000000380.gwf"
              ,"/data/RUN007/R0007F0000000381.gwf"
              ,"/data/RUN007/R0007F0000000382.gwf"
              ,"/data/RUN007/R0007F0000000383.gwf"
              ,"/data/RUN007/R0007F0000000384.gwf"
              ,"/data/RUN007/R0007F0000000385.gwf"
              ,"/data/RUN007/R0007F0000000386.gwf"
              ,"/data/RUN007/R0007F0000000387.gwf"
              ,"/data/RUN007/R0007F0000000388.gwf"
              ,"/data/RUN007/R0007F0000000389.gwf"
              ,"/data/RUN007/R0007F0000000390.gwf"
              ,"/data/RUN007/R0007F0000000391.gwf"
              ,"/data/RUN007/R0007F0000000392.gwf"
              ,"/data/RUN007/R0007F0000000393.gwf"
              ,"/data/RUN007/R0007F0000000394.gwf"
              ,"/data/RUN007/R0007F0000000395.gwf"
              ,"/data/RUN007/R0007F0000000396.gwf"
              ,"/data/RUN007/R0007F0000000397.gwf"
              ,"/data/RUN007/R0007F0000000398.gwf"
              ,"/data/RUN007/R0007F0000000399.gwf"
              ,"/data/RUN007/R0007F0000000400.gwf"
              ,"/data/RUN007/R0007F0000000401.gwf"
              ,"/data/RUN007/R0007F0000000402.gwf"
              ,"/data/RUN007/R0007F0000000403.gwf"
              ,"/data/RUN007/R0007F0000000404.gwf"
              ,"/data/RUN007/R0007F0000000405.gwf"
              ,"/data/RUN007/R0007F0000000406.gwf"
              ,"/data/RUN007/R0007F0000000407.gwf"
              ,"/data/RUN007/R0007F0000000408.gwf"
              ,"/data/RUN007/R0007F0000000409.gwf"
              ,"/data/RUN007/R0007F0000000410.gwf"
              ,"/data/RUN007/R0007F0000000411.gwf"
              ,"/data/RUN007/R0007F0000000412.gwf"
              ,"/data/RUN007/R0007F0000000413.gwf"
              ,"/data/RUN007/R0007F0000000414.gwf"
              ,"/data/RUN007/R0007F0000000415.gwf"
              ,"/data/RUN007/R0007F0000000416.gwf"
              ,"/data/RUN007/R0007F0000000417.gwf"
              ,"/data/RUN007/R0007F0000000418.gwf"
              ,"/data/RUN007/R0007F0000000419.gwf"
              ,"/data/RUN007/R0007F0000000420.gwf"
              ,"/data/RUN007/R0007F0000000421.gwf"
              ,"/data/RUN007/R0007F0000000422.gwf"
              ,"/data/RUN007/R0007F0000000423.gwf"
              ,"/data/RUN007/R0007F0000000424.gwf"
              ,"/data/RUN007/R0007F0000000425.gwf"
              ,"/data/RUN007/R0007F0000000426.gwf"
              ,"/data/RUN007/R0007F0000000427.gwf"
              ,"/data/RUN007/R0007F0000000428.gwf"
              ,"/data/RUN007/R0007F0000000429.gwf"
              ,"/data/RUN007/R0007F0000000430.gwf"
              ,"/data/RUN007/R0007F0000000431.gwf"
              ,"/data/RUN007/R0007F0000000432.gwf"
              ,"/data/RUN007/R0007F0000000433.gwf"
              ,"/data/RUN007/R0007F0000000434.gwf"
              ,"/data/RUN007/R0007F0000000435.gwf"
              ,"/data/RUN007/R0007F0000000436.gwf"
              ,"/data/RUN007/R0007F0000000437.gwf"
              ,"/data/RUN007/R0007F0000000438.gwf"
              ,"/data/RUN007/R0007F0000000439.gwf"
              ,"/data/RUN007/R0007F0000000440.gwf"
              ,"/data/RUN007/R0007F0000000441.gwf"
              ,"/data/RUN007/R0007F0000000442.gwf"
              ,"/data/RUN007/R0007F0000000443.gwf"
              ,"/data/RUN007/R0007F0000000444.gwf"
              ,"/data/RUN007/R0007F0000000445.gwf"
              ,"/data/RUN007/R0007F0000000446.gwf"
              ,"/data/RUN007/R0007F0000000447.gwf"
              ] -- 解析するデータ