#******************************************#
#     File Name: Makefile
#        Author: Takahiro Yamamoto
# Last Modified: 2015/09/03 21:34:27
#******************************************#

# compiler option
CC = gcc -O2 -Wall -Wextra
HC = ghc -O2 --make

# use library
USELIB=libframe

# program
TAR1=main.cgi
TAR2=main2.cgi
TAR3=main3.cgi
TAR4=main4.cgi
TARs= ${TAR4} ${TAR3} ${TAR2} ${TAR1}

DEP1=./HasKAL/PlotUtils/HROOT/AppendFunction.cc
DEPs= ${DEP1}

# link path
ifneq (${USELIB},)
CFLAGS=`pkg-config --cflags ${USELIB}`
LDFLAGS=`pkg-config --libs-only-L ${USELIB}`
LIBS=`pkg-config --libs-only-l ${USELIB}`
endif

# compile rule
all: ${TARs}

${TAR1}: ${TAR1}.hs ${DEPs}
	${HC} -o $@ $^ ${CFLAGS} ${LDFLAGS} ${LIBS}

${TAR2}: ${TAR2}.hs ${DEPs}
	${HC} -o $@ $^ ${CFLAGS} ${LDFLAGS} ${LIBS}

${TAR3}: ${TAR3}.hs 
	${HC} -o $@ $^ ${CFLAGS} ${LDFLAGS} ${LIBS}

${TAR4}: ${TAR4}.hs 
	${HC} -o $@ $^ ${CFLAGS} ${LDFLAGS} ${LIBS}

clean:
	rm -f ./*~ ./*.o ./*.hi ./*.dyn_o ./*.dyn_hi 

cleanall: clean
	rm -f ${TARs}

