#!/bin/bash
#
#
# This script will build a general program, and get performance numbers, for all the currently released versions of HDF5.
#
# Example:
# Download and Build all the versions of hdf5, parallel program. Don't build the program or run it
#
#./run_prog.sh --enable-parallel --notest --prog_nobuild
#
# Build different versions of the general program. Don't build the hdf5 versions. Assumes hdf5 versions already compiled
#
#./run_prog.sh --enable-parallel --hdf5_nobuild --notest --src source
#
# Build both HDF5 and the program, don't run the program
#
# ./run_prog.sh --enable-parallel --notest --src source
#
# run the tests only, don't compile the HDF5 library or the program. Assumes those are already built.
# ./run_prog.sh --enable-parallel 4 --hdf5_nobuild --prog_nobuild  --src source --args <ARGS>
#
# ./run_prog.sh --enable-parallel --notest --prog_nobuild --src Sample_hdf5_measure_time.c
# ./run_prog.sh --enable-parallel --hdf5_nobuild --notest --src Sample_hdf5_measure_time.c
# ./run_prog.sh --enable-parallel --hdf5_nobuild --prog_nobuild --src Sample_hdf5_measure_time.c
#
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
nc='\033[0m' # No Color

export H5_LDFLAGS=""

H5CC=h5cc
H5FC=h5fc
PARALLEL=0
HDF5BUILD=1
PROGBUILD=1
TEST=1
SRC2=0
HDF5=""
PREFIX=""
PRE="1."
NPROCS=1
TOPDIR=$PWD
POSITIONAL=()
MPIEXEC=""
LIBS=""
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --enable-parallel)
    if ! [[ "$2" =~ ^[0-9]+$ ]];then
        printf "%bUnknown integer value for %s: val= %d \n%b" "$red" "$key" "$2" "$nc"
        exit 1
    fi
    NPROCS="$2" # Number of processes
    PARALLEL=1
    H5CC=h5pcc
    H5FC=h5pfc
    shift # past argument
    shift # past value
    ;;
    --hdf5)
    HDF5="$2" # root install directory
    shift # past argument
    shift # past value
    ;;
    --src)
    SRC="$2"
    EXEC=`echo $SRC | sed -e 's/\.[^\.]*$//'`
    shift # past argument
    shift # past value
    ;;
    --src2) # A second program should be compiled and run after SRC has run
    SRC2="$2"
    EXEC2=`echo $SRC2 | sed -e 's/\.[^\.]*$//'`
    shift # past argument
    shift # past value
    ;;
    --hdf5_nobuild)
    HDF5BUILD=0
    shift
    ;;
    --prog_nobuild)
    PROGBUILD=0
    shift
    ;;
    --notest)
    TEST=0
    shift
    ;;
    --args)
    ARGS="$2"
    shift # past argument
    shift # past value
    ;;
    --default)
    shift
    ;;
    --help | -h)
    printf "OPTIONS:\n"
    printf " --enable-parallel int    enabled building parallel HDF5, and executing the program using n processes\n"
    printf " --src string             program name \n"              
    printf " --src2 string            optional second program name to be run after src \n" 
    printf " --hdf5_nobuild           don't build hdf5 libraries\n"
    printf " --prog_nobuild           don't build the program\n"
    printf " --notest                 don't run the program\n"
    printf " --args \"options\"         program arguments, quoted\n\n"
    exit 0
    ;;
    *)    # unknown option
    printf "%bUnknown option %s \n%b" "$red" "$key" "$nc"
    exit 1
    ;;
esac
done

HOSTNAME=`hostname -d`
host=$HOSTNAME
OPTS=""
#OPTS="--enable-using-memchecker"
if [[ $PARALLEL != 1 ]]; then
   echo -e "${red}Enabled Parallel: FALSE${nc}"
   export CC="gcc"
   export FC="gfortran"
   export F77="gfortran"
   export CXX="g++"
   export CFLAGS="-std=c99"
else
   echo -e "${grn}Enabled Parallel: TRUE${nc}"
   OPTS="--enable-parallel $OPTS"

# ANL
   if [[ "$host" == *"cetus"* || "$host" == *"mira"* ]]; then
       export MPIEXEC="runjob -n $NPROCS -p 16 --block $COBALT_PARTNAME :"
       export CC="mpicc"
       export FC="mpif90"
       export F77="mpif90"
   fi
#LBNL
   if [[ "$host" == *"cori"* || "$host" == *"edison"* || "$host" == *"nid"* ]]; then
       export MPIEXEC="srun -n $NPROCS"
       export CC="cc"
       export FC="ftn"
       export F77="ftn"
   fi
#ORNL
   if [[ "$host" == *"summit"* ]]; then
       export MPIEXEC="jsrun -n $NPROCS"
       export CC="mpicc"
       export FC="mpif90"
       export F77="mpif90"
       DEF="-DSUMMIT"
   fi

#DEFAULT
   if [[ -z "$MPIEXEC" ]]; then
       export MPIEXEC="mpiexec -n $NPROCS"
       export CC="mpicc"
       export FC="mpif90"
       export F77="mpif90"
       export CFLAGS="-std=c99"
   fi

fi

# Output all the results in the prog-timings file.
#

# List of all the HDF5 versions to run through

# Note "hdf5-" represents a tagged version, otherwise it is a branch

VER_HDF5_1_6="6_0 6_1 6_2 6_3 6_4 6_5 6_6 6_7 6_8 6_9 6_10"
VER_HDF5_1_8a="8_0 8_1 8_2 8_3-patched 8_4-patch1 8_5-patch1 8_6"
VER_HDF5_1_8a="8_0 8_1 8_2 8_3-patched 8_4-patch1 8_5-patch1 8_6"
VER_HDF5_1_8b="8_3-patched 8_4-patch1 8_5-patch1 8_6 8_7 8_8 8_9 8_10-patch1"
VER_HDF5_1_8c="8_11 8_12 8_13 8_14 8_15-patch1 8_16 8_17 8_18 8_19" 
VER_HDF5_1_8d="8_20 8_21 8_22 8"
VER_HDF5_1_10="10_0-patch1 10_1 10_3 10_4 10_5 10_6 10_7 10"
VER_HDF5_1_12="12_0 12_1 12"
VER_HDF5_MISC="develop"
VER_HDF5="$VER_HDF5_1_8a $VER_HDF5_1_8b $VER_HDF5_1_8c $VER_HDF5_1_8d $VER_HDF5_1_10 $VER_HDF5_1_12 $VER_HDF5_MISC"
VER_HDF5="$VER_HDF5_1_6 $VER_HDF5_1_8b $VER_HDF5_1_8c $VER_HDF5_1_8d $VER_HDF5_1_10 $VER_HDF5_1_12 $VER_HDF5_MISC"
VER_HDF5="6_0 6_1 6_2 6_3"
#VER_HDF5="$VER_HDF5_1_6"
export LIBS="-ldl"
export FLIBS="-ldl"

if [  $HDF5BUILD = 1 ]; then
    if [ -d "hdf5" ]; then
        rm -fr hdf5
    fi
    git clone https://github.com/HDFGroup/hdf5.git 
fi

j=0
for i in ${VER_HDF5}
do
    status=0
    j=$[j + 1]
# Build HDF5
    PRE="1_$i"
    ONE="1."
    if [  $HDF5BUILD = 1 ]; then

        printf "$yel"
        printf "   __ _____  ________ \n"
        printf "  / // / _ \/ __/ __/ \n"
        printf " / _  / // / _//__ \  \n"
        printf "/_//_/____/_/ /____/  \n"
        printf "$nc"

	cd hdf5
        git checkout -f .

        if [[ $i =~ ^[0-9].* ]]; then

            if git show-ref --tags | grep "tags/hdf5-1_$i$"; then
                # found tag
                git checkout -f tags/hdf5-1_$i
                status=$?
                if [[ $status != 0 ]]; then
                    printf "\n%bgit checkout tags/hdf5-1_$i #FAILED%b \n\n" "$red" "$nc"
                    exit $status
                fi
            else
                # tag not found, must be a branch
                git checkout -f hdf5_1_$i
                status=$?
                if [[ $status != 0 ]]; then
                    printf "\n%bgit checkout hdf5_1_$i #FAILED%b \n\n" "$red " "$nc"
                    exit $status
                fi
            fi
            BUILD_DIR=build_1_$i
	else
	    git checkout -f $i
            BUILD_DIR=build_$i
            ONE=""
	fi

        rm -fr $BUILD_DIR
        mkdir $BUILD_DIR
        if test -f "autogen.sh"; then
           ./autogen.sh
        fi
        cd $BUILD_DIR

        CXXFLAGS=""
	if [[ $i == 8*  || $i == 6* ]]; then
	    HDF5_OPTS="--enable-production $OPTS"
            if [[ $i == 6* ]]; then
                HDF5_OPTS="$HDF5_OPTS --prefix $PWD/hdf5"
                CXXFLAGS="-DHDF5_1_6"
            fi
            if [[ $HOSTNAME == summit* ]]; then
                if  [[ $i =~ 8_[0-9].* || $i == 8 ]]; then
                    # wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O bin/config.guess
                    # wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O bin/config.sub
                    git clone git://git.savannah.gnu.org/config.git
                    cp config/config.guess ../bin/
                    cp config/config.sub ../bin/
                    rm -fr config
                fi
            fi
	else
	    HDF5_OPTS="--enable-build-mode=production $OPTS"
            if ../configure -h | grep -q "enable-tests"; then
               HDF5_OPTS="--disable-tests --disable-tools $HDF5_OPTS" 
            fi
	fi

	HDF5=$PWD
        CONFIG_CMD="../configure --disable-fortran --disable-hl --without-zlib --without-szlib $HDF5_OPTS"
        printf "\n%b$CONFIG_CMD %b \n\n" "$mag" "$nc"

        $CONFIG_CMD
        status=$?
        if [[ $status != 0 ]]; then
            echo "HDF5 configure #FAILED"
            exit $status
        fi

	make -i -j 16
	status=$?
	if [[ $status != 0 ]]; then
	    echo "HDF5 make #FAILED"
	    exit $status
	fi
	make -i -j 16 install
	status=$?
	if [[ $status != 0 ]]; then
	    echo "HDF5 make install #FAILED"
	    exit $status
        fi
	cd ../../ || exit
    else
        if [[ $i =~ ^[0-9].* ]]; then
            BUILD_DIR=build_1_$i
	else
            BUILD_DIR=build_$i
            ONE=""
	fi
        HDF5="$TOPDIR"/hdf5/$BUILD_DIR
    fi

# Build EXAMPLE
    if [ $PROGBUILD = 1 ]; then
        printf "$yel"
        printf "    ____                                       \n"
        printf "   / __ \_________  ____ __________ _____ ___  \n"
        printf "  / /_/ / ___/ __ \/ __  / ___/ __ \ / __ \__\ \n"
        printf " / ____/ /  / /_/ / /_/ / /  / /_/ / / / / / / \n"
        printf "/_/   /_/   \____/\__, /_/   \__,_/_/ /_/ /_/  \n"
        printf "                 /____/                        \n"
        printf "${EXEC} ${ARGS}                                \n"
        printf "$nc"

        EXT="${SRC##*.}"
        if [[ $EXT == "cpp" || $EXT == "cxx" || $EXT == ".cc" ]]; then
            LIBS="-lstdc++ -I$HDF5/hdf5/include"
        fi
        CFLAGS="-U__STRICT_ANSI__"
        printf " $yel $HDF5/hdf5/bin/${H5CC} $CFLAGS -o ${EXEC}_${BUILD_DIR} $DEF $SRC $LIBS $nc \n"
        $HDF5/hdf5/bin/${H5CC} $CFLAGS -o ${EXEC}_${BUILD_DIR} $DEF $SRC $LIBS
	status=$?
	if [[ $status != 0 ]]; then
            printf "%bFAILED TO COMPILE ${SRC}%b/n" "$red" "$nc"
            rm -f ${EXEC}_${BUILD_DIR}
	    exit $status
	fi
        if [ $SRC2 != 0 ]; then
          echo "$HDF5/hdf5/bin/${H5CC} -o ${EXEC2}_${BUILD_DIR} $DEF ${SRC2}"
          $HDF5/hdf5/bin/${H5CC} $CFLAGS -o ${EXEC2}_${BUILD_DIR} $DEF $SRC2 $LIBS
	  status=$?
	  if [[ $status != 0 ]]; then
              printf "%bFAILED TO COMPILE ${SRC2}%b/n" "$red" "$nc"
              rm -f ${EXEC2}_${BUILD_DIR}
	      exit $status
   	  fi
        fi
            

    fi
    if [ $TEST = 1 ]; then
        j0=$(printf "%02d" $j)
        NTIMES=10
        VAL=""
        rm -f $TOPDIR/${EXEC}_$j0
        printf "%b$MPIEXEC ./${EXEC}_${BUILD_DIR} $ARGS %b\n" "$mag" "$nc"
        for ((n=1;n<=${NTIMES};n++));do
            cmd="/usr/bin/time -v -f \"%e real\" -o \"results\"  $MPIEXEC ./${EXEC}_${BUILD_DIR} $ARGS"
            eval $cmd
            #/usr/bin/time -v -f "%e real" -o "results_${EXEC}_${BUILD_DIR}" $MPIEXEC ./${EXEC}_${BUILD_DIR} $ARGS
            ETIME=`grep "Elapsed" results | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'`
            VAL+=${ETIME}","
        done 
        VAL2=`echo $VAL | sed 's/\,/\n/g'`
        VALS=`echo "$VAL2" | awk '{if(min==""){min=max=$1}; if($1>max) {max=$1}; if($1<min) {min=$1}; total+=$1; count+=1} END {print total/count, min, max}'`
        echo "$ONE$i $VALS" > $TOPDIR/${EXEC}__$j0
        if [ $SRC2 != 0 ]; then
            /usr/bin/time -v -f "%e real" -o "results_${EXEC2}_${BUILD_DIR}" $MPIEXEC ./${EXEC2}_${BUILD_DIR} $ARGS
        fi
        rm -fr *.h5
        
        #{ echo -n "$ONE$i " & grep "Elapsed" "results_${EXEC}_${BUILD_DIR}" | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'; } > $TOPDIR/prog_time_$j0
        #{ echo -n "$ONE$i " & grep "Maximum resident" "results_${EXEC}_${BUILD_DIR}" | sed -n -e 's/^.*bytes): //p'; } > $TOPDIR/prog_mem_$j0
    fi
    if [ $PROGBUILD = 1 ]; then
        if [ $TEST = 1 ]; then
            rm -fr $TOPDIR/${EXEC}.$i
        fi
    fi
    cd $TOPDIR
done

# Combine the timing numbers to a single file
if [ $TEST = 1 ]; then

    i=1
    FILE_T=${PREFIX}PROG_${EXEC}.${i}
    until [ ! -f "${FILE_T}" ]
      do
        ((i=i+1))
        FILE_T=${PREFIX}PROG_${EXEC}.${i}
      done
    echo "# $cmd" > ${FILE_T}
    echo "#nprocs=$NPROCS, ntim=$NTIMES" >> ${FILE_T}
    #echo "#nprocs=$NPROCS, nelem=$NELEM, ntim=$NTIMES" > ${FILE_M}
    cat ${EXEC}__* >> ${FILE_T}
    #cat cgns_mem_* >> ${FILE_M}
    sed -i 's/_/./g' ${FILE_T}
    #sed -i 's/_/./g' ${FILE_M}

# Add extra spaces for gnuplot formating
    sed -i 's/\(1.6\|1.8\|1.10\|1.12\|1.14\) [0-9].*/&\n\n/g' ${FILE_T}
    #sed -i 's/\(1.8\|1.10\|1.12\|1.14\) [0-9].*/&\n\n/g' ${FILE_M}

    #rm -f ${EXEC}_*
fi

