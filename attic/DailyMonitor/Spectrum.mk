#******************************************#
#     File Name: dailySpectrum.mk
#        Author: Takahiro Yamamoto
# Last Modified: 2016/01/26 11:43:09
#******************************************#

# compiler option
HC = ghc -O2

# use library
USELIB= libframe

# program
TAR1= Spectrum
TARs= ${TAR1} 

# dependency
DEP1= ./HasKAL/PlotUtils/HROOT/AppendFunction.cc
DEP2= ./HasKAL/LineUtils/LineRemoval/rng_median.c
DEPs= ${DEP1} ${DEP2}

#########################################
# link path
ifneq (${USELIB},)
CFLAGS=`pkg-config --cflags ${USELIB}`
LDFLAGS=`pkg-config --libs-only-L ${USELIB}`
LIBS=`pkg-config --libs-only-l ${USELIB}`
endif

# compile rule
all: ${TARs}

${TAR1}: ${TAR1}.hs ${DEPs}
	-${HC} -o $@ $< ${CFLAGS} ${LDFLAGS} ${LIBS}
	${HC} -o $@ $^ ${CFLAGS} ${LDFLAGS} ${LIBS}

clean:
	rm -f ./*~ ./*.o ./*.hi ./*.dyn_o ./*.dyn_hi

cleanall: clean
	rm -f ${TARs}

