#!/bin/bash
#
#
# This script will build a general program, and get performance numbers, for all the currently released versions of HDF5.
#
# Download and Build all the versions of hdf5
#
#./run_gen.sh --enable-parallel --notest --gen_nobuild
#
# Build different versions of the general program
#
#./run_gen.sh --enable-parallel --hdf5_nobuild --notest --src source
#
# Build both, no testing
#
# ./run_gen.sh --enable-parallel --notest --src source
#
# run the tests
# ./run_gen.sh --enable-parallel --hdf5_nobuild --gen_nobuild --ptest 4 <ARGS> --src source
#
# ./run_gen.sh --enable-parallel --notest --gen_nobuild --src Sample_hdf5_measure_time.c
# ./run_gen.sh --enable-parallel --hdf5_nobuild --notest --src Sample_hdf5_measure_time.c
# ./run_gen.sh --enable-parallel --hdf5_nobuild --gen_nobuild --ptest 336 -t --src Sample_hdf5_measure_time.c
#
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
nc='\033[0m' # No Color

PARALLEL=0
HDF5BUILD=1
GENBUILD=1
TEST=1
HDF5=""
PREFIX=""
PRE="1."
NPROCS=8
TOPDIR=$PWD
NELEM=65536
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --enable-parallel)
    PARALLEL=1
    shift
    ;;
    --hdf5)
    HDF5="$2" # root install directory
    shift # past argument
    shift # past value
    ;;
    --src)
    SRC="$2" # root install directory
    EXEC=`echo $SRC | sed -e 's/\.[^\.]*$//'`
    shift # past argument
    shift # past value
    ;;
    --hdf5_nobuild)
    HDF5BUILD=0
    shift
    ;;
    --gen_nobuild)
    GENBUILD=0
    shift
    ;;
    --notest)
    TEST=0
    shift
    ;;
    --ptest)
    NPROCS="$2" # Number of processes
    ARGS="$3" # Size of parallel problem
    shift # past argument
    shift # past value
    shift # past value
    ;;
    --default)
    shift
    ;;
    *)    # unknown option
    ;;
esac
done
HOSTNAME=`hostname -d`
host=$HOSTNAME
OPTS=""
if [[ $PARALLEL != 1 ]]; then
   echo -e "${red}Enabled Parallel: FALSE${nc}"
   export CC="gcc"
   export FC="gfortran"
   export F77="gfortran"
else
   echo -e "${grn}Enabled Parallel: TRUE${nc}"
   OPTS="--enable-parallel"

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
   fi

fi

# Output all the results in the gen-timings file.
#

# List of all the HDF5 versions to run through
#VER_HDF5_0="6_0 6_1 6_2 6_5 6_6 6_7 6_8 6_9 6_10"
VER_HDF5_1="$VER_HDF5_0 8_5-patch1 8_6 8_7 8_8 8_9 8_10-patch1"
VER_HDF5_2="8_11 8_12 8_13 8_14 8_15-patch1 8_16 8_17 8_18 8_19 8_20 8_21"
VER_HDF5_3="10_0-patch1 10_1 10_2 10_3 10_4 10_5 1_10 develop"
VER_HDF5="$VER_HDF5_1 $VER_HDF5_2 $VER_HDF5_3"
#VER_HDF5="10_3 10_4 10_5 develop"
#VER_HDF5="8_1"
export LIBS="-ldl"
export FLIBS="-ldl"

if [  $HDF5BUILD = 1 ]; then
    rm -fr hdf5
    git clone https://brtnfld@bitbucket.hdfgroup.org/scm/hdffv/hdf5.git
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
	cd hdf5
        if [[ $i == 8*  || $i == 6* ]]; then
          wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O bin/config.guess
          wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O bin/config.sub
        fi
        
        if [[ $i =~ ^[0-9].* ]]; then
	    git checkout tags/hdf5-1_$i
            BUILD_DIR=build_1_$i
            if [[ "$host" == *"summit"* ]]; then
              if [[ $i == 8*  || $i == 6* ]]; then
                wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O bin/config.guess
                wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O bin/config.sub
                autoreconf -ivf 
              fi
            fi
	else
	    git checkout $i
	    ./autogen.sh
            BUILD_DIR=build_$i
            ONE=""
	fi

        rm -fr $BUILD_DIR
        mkdir $BUILD_DIR
        cd $BUILD_DIR

        CXXFLAGS=""
	if [[ $i == 8*  || $i == 6* ]]; then
	    HDF5_OPTS="--enable-production $OPTS"
            if [[ $i == 6* ]]; then
                HDF5_OPTS="$HDF5_OPTS --prefix $PWD/hdf5"
                CXXFLAGS="-DHDF5_1_6"
            fi
	else
	    HDF5_OPTS="--enable-build-mode=production $OPTS"
	fi

	HDF5=$PWD
	../configure --disable-fortran --disable-hl --without-zlib --without-szip $HDF5_OPTS
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
	cd ../../
    else
        if [[ $i =~ ^[0-9].* ]]; then
            BUILD_DIR=build_1_$i
	    HDF5=$TOPDIR/hdf5/$BUILD_DIR
	else
            BUILD_DIR=build_$i
	    HDF5=$TOPDIR/hdf5/$BUILD_DIR
            ONE=""
	fi
    fi
# Build EXAMPLE
    if [ $GENBUILD = 1 ]; then
        echo "$HDF5/hdf5/bin/h5pcc -o ${EXEC}_${BUILD_DIR} $DEF $SRC"
        $HDF5/hdf5/bin/h5pcc $CFLAGS -o ${EXEC}_${BUILD_DIR} $DEF $SRC
	status=$?
	if [[ $status != 0 ]]; then
            echo "FAILED TO COMPILE $SRC"
            rm -f ${EXEC}_${BUILD_DIR}
	    exit $status
	fi
    fi
    if [ $TEST = 1 ]; then
        echo "$MPIEXEC ./${EXEC}_${BUILD_DIR} $ARGS"
        $MPIEXEC ./${EXEC}_${BUILD_DIR} $ARGS 
 #       /usr/bin/time -v -f "%e real" -o "results" $MPIEXEC ./${EXEC}_${BUILD_DIR} $ARGS
        rm -fr *.h5
        #j0=$(printf "%02d" $j)
        #{ echo -n "$ONE$i " & grep "Elapsed" results | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'; } > $TOPDIR/gen_time_$j0
        #{ echo -n "$ONE$i " & grep "Maximum resident" results | sed -n -e 's/^.*bytes): //p'; } > $TOPDIR/gen_mem_$j0
    fi
    if [ $GENBUILD = 1 ]; then
        if [ $TEST = 1 ]; then
            rm -fr $TOPDIR/GEN.$i
        fi
    fi
    cd $TOPDIR
done

# Combine the timing numbers to a single file
if [ $TEST = 1 ]; then
    echo "#nprocs=$NPROCS, nelem=$NELEM" > ${PREFIX}gen-timings
    echo "#nprocs=$NPROCS, nelem=$NELEM" > ${PREFIX}gen-memory
    cat gen_time_* >> ${PREFIX}gen-timings
    cat gen_mem_* >> ${PREFIX}gen-memory
    sed -i 's/_/./g' ${PREFIX}gen-timings
    sed -i 's/_/./g' ${PREFIX}gen-memory
    
    rm -f gen_*
fi

