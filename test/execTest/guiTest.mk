#******************************************#
#     File Name: guiTest.mk
#        Author: Takahiro Yamamoto
# Last Modified: 2014/10/03 17:42:44
#******************************************#

# compiler/option
HC = ghc -O2
LDFLAGS = -L/opt/work/gsl/lib
LIBS = -lstdc++ -lFrame -lgsl -lgslcblas

# program
TAR1 = guiTest
TARs = ${TAR1}

# dependency
PREF = ./HasKAL/GUI_Utils/GUI
DEPs = ${PREF}_Utils.hs \
       ${PREF}_Supplement.hs \
       ${PREF}_RangeRingDown.hs \
       ${PREF}_RangeInspiral.hs \
       ${PREF}_RangeIMBH.hs \
       ${PREF}_GlitchKleineWelle.hs \
       ${PREF}_GaussianityRayleighMon.hs

CSRC = ./HasKAL/PlotUtils/HROOT/AppendFunction.cc

# temp file
TEMP = ./*~ ${PREF}*~ \
       ./*.o ${PREF}*.o \
       ./*.hi ${PREF}*.hi

# compile rule
all: ${TARs}

${TAR1}: ${TAR1}.hs ${DEPs}
	${HC} -o $@ $< ${CSRC} ${LDFLAGS} ${LIBS}

clean:
	rm -f ${TEMP}

cleanall: clean
	rm -f ./optKW_* ${TARs} ./*.lst
	rm -fR ./KW_*

