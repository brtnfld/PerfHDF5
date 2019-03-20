#!/bin/bash
#
#
# This script will build MATLAB, and get performance numbers, for all the currently released versions of HDF5.
#
# Download and Build all the versions of hdf5
#
#./run_matlab.sh --enable-parallel --notest --matlab_nobuild
#
# Build different versions of MATLAB 
#
#./run_matlab.sh --enable-parallel --hdf5_nobuild --notest
#
# Build both, no testing
#
# ./run_matlab.sh --enable-parallel --notest
#
# run the tests
# ./run_matlab.sh --enable-parallel --hdf5_nobuild --matlab_nobuild --ptest 4 2014

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
nc='\033[0m' # No Color

PARALLEL=0
HDF5BUILD=1
MATLABBUILD=1
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
    --hdf5_nobuild)
    HDF5BUILD=0
    shift
    ;;
    --matlab_nobuild)
    MATLABBUILD=0
    shift
    ;;
    --notest)
    TEST=0
    shift
    ;;
    --ptest)
    NPROCS="$2" # Number of processes
    NELEM="$3" # Size of parallel problem
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
#DEFAULT
   if [[ -z "$MPIEXEC" ]]; then
       export MPIEXEC="mpiexec -n $NPROCS"
       export CC="mpicc"
       export FC="mpif90"
       export F77="mpif90"
   fi

fi

# Output all the results in the matlab-timings file.
#

# List of all the HDF5 versions to run through
VER_HDF5_0="6_0 6_1 6_2 6_5 6_6 6_7 6_8 6_9 6_10"
VER_HDF5_1="$VER_HDF5_0 8_1 8_2 8_3-patched 8_4-patch1 8_5-patch1 8_6 8_7 8_8 8_9 8_10-patch1"
VER_HDF5_2="8_11 8_12 8_13 8_14 8_15-patch1 8_16 8_17 8_18 8_19 8_20 8_21"
VER_HDF5_3="10_0-patch1 10_1 10_2 10_3 10_4 10_5 1_10 HDFFV-10658-performance-drop-for-1-10 develop HDFFV-10658-performance-drop-from-1-8"

VER_HDF5="$VER_HDF5_1 $VER_HDF5_2 $VER_HDF5_3"
#VER_HDF5="8_1"
export LIBS="-ldl"
export FLIBS="-ldl"

if [  $HDF5BUILD = 1 ]; then
    rm -fr hdf5
    git clone https://brtnfld@bitbucket.hdfgroup.org/scm/~songyulu/hdf5_ray.git hdf5
 #   git clone https://brtnfld@bitbucket.hdfgroup.org/scm/hdffv/hdf5.git
fi

#if [ $MATLABBUILD = 1 ]; then
#    git clone https://github.com/MATLAB/MATLAB.git
#fi

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

        if [[ $i =~ ^[0-9].* ]]; then
	    git checkout tags/hdf5-1_$i
	    rm -fr build_1_$i
	    mkdir build_1_$i
	    cd build_1_$i
	else
	    git checkout $i
	    ./autogen.sh
	    rm -fr build_$i
	    mkdir build_$i
	    cd build_$i
            ONE=""
	fi
	
        CXXFLAGS=""
	if [[ $i == 8*  || $i == 6* ]]; then
	    HDF5_OPTS="--enable-production --enable-cxx $OPTS"
            if [[ $i == 6* ]]; then
                HDF5_OPTS="$HDF5_OPTS --prefix $PWD/hdf5"
                CXXFLAGS="-DHDF5_1_6"
            fi
	else
	    HDF5_OPTS="--enable-build-mode=production --enable-cxx $OPTS"
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
	    HDF5=$TOPDIR/hdf5/build_1_$i
	else
	    HDF5=$TOPDIR/hdf5/build_$i
            ONE=""
	fi
    fi

# Build EXAMPLE
    if [ $MATLABBUILD = 1 ]; then
        echo "$HDF5/hdf5/bin/h5c++ -o writeLargeNumDsets writeLargeNumDsets.cpp"
        $HDF5/hdf5/bin/h5c++ $CXXFLAGS -o writeLargeNumDsets writeLargeNumDsets.cpp
	status=$?
	if [[ $status != 0 ]]; then
            echo "FAILED TO COMPILE writeLargeNumDsets.cpp"
            rm -f writeLargeNumDsets
	    exit $status
	fi
    fi
    if [ $TEST = 1 ]; then
        /usr/bin/time -v -f "%e real" -o "results" ./writeLargeNumDsets
        rm -fr fileWithLargeNumDsets.h5
        j0=$(printf "%02d" $j)
        { echo -n "$ONE$i " & grep "Elapsed" results | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'; } > $TOPDIR/matlab_time_$j0
        { echo -n "$ONE$i " & grep "Maximum resident" results | sed -n -e 's/^.*bytes): //p'; } > $TOPDIR/matlab_mem_$j0
    fi
    if [ $MATLABBUILD = 1 ]; then
        if [ $TEST = 1 ]; then
            rm -fr $TOPDIR/MATLAB.$i
        fi
    fi
    cd $TOPDIR
done

# Combine the timing numbers to a single file
if [ $TEST = 1 ]; then
    echo "#nprocs=$NPROCS, nelem=$NELEM" > ${PREFIX}matlab-timings
    echo "#nprocs=$NPROCS, nelem=$NELEM" > ${PREFIX}matlab-memory
    cat matlab_time_* >> ${PREFIX}matlab-timings
    cat matlab_mem_* >> ${PREFIX}matlab-memory
    sed -i 's/_/./g' ${PREFIX}matlab-timings
    sed -i 's/_/./g' ${PREFIX}matlab-memory
    
    rm -f matlab_*
fi

