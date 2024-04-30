#!/bin/bash
#
#
# This script will build MATLAB, and get performance numbers, for all the currently released versions of HDF5.
#
# Download and Build all the versions of hdf5
#
#./run_matlab.sh --notest --matlab_nobuild
#
# Build different versions of MATLAB 
#
#./run_matlab.sh --hdf5_nobuild --notest
#
# Build both, no testing
#
# ./run_matlab.sh --notest
#
# run the tests
# ./run_matlab.sh --hdf5_nobuild --matlab_nobuild --ptest 4 2014

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
VER_HDF5_2="8_11 8_12 8_13 8_14 8_15-patch1 8_16 8_17 8_18 8_19 8_20 8_21 8_22 8_23 8"
VER_HDF5_3="10_0-patch1 10_1 10_3 10_4 10_5 10_6 10_7 10_8 10_9 10_10 10_11 10 12_0 12_1 12_2 12_3 12 14_0 14_1 14_2 14_3 14_4 14 develop"
#VER_HDF5_3="10_0-patch1 10_1 10_2 10_3 10_4 10_5 10_6 10_7 10_8 10_9 10_10 10_11 10 12_0 12_1 12_2 12_3 12 14_0 14_1 14_2 14_3 14_4 14 develop"
#VER_HDF5="10_9 10_10 10_11 10 12_0 12_1 12_2 12_3 12 14_0 14_1 14_2 14_3 14_4 14 develop"
VER_HDF5="$VER_HDF5_1 $VER_HDF5_2 $VER_HDF5_3"
#VER_HDF5="10_3 10_4 10_5 10_6 10_7 10_8 1_10 12_0 1_12 develop"
export LIBS="-ldl"
export FLIBS="-ldl"

if [  $HDF5BUILD = 1 ]; then
    rm -fr hdf5
    git clone https://github.com/HDFGroup/hdf5.git 
fi

#if [ $MATLABBUILD = 1 ]; then
#    git clone https://github.com/MATLAB/MATLAB.git
#fi
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
XTICS=""
j=0
for i in ${VER_HDF5}
do
    status=0
    j=$[j + 1]
# Build HDF5
    if [ $HDF5BUILD = 1 ]; then
	cd hdf5
        git checkout .

        if [[ $i =~ ^[0-9].* ]]; then

            if git show-ref --tags | grep "tags/hdf5-1_$i$"; then
                # found tag
                git checkout -f tags/hdf5-1_$i
                status=$?
                if [[ $status != 0 ]]; then
                    printf "\n%bgit checkout -f tags/hdf5-1_$i #FAILED%b \n\n" "$red" "$nc"
                    exit $status
                fi
            else
                # tag not found, must be a branch
                git checkout -f hdf5_1_$i
                status=$?
                if [[ $status != 0 ]]; then
                    printf "\n%bgit checkout hdf5_1_$i #FAILED%b \n\n" "$red" "$nc"
                    exit $status
                fi
                if test -f "autogen.sh";then
                    ./autogen.sh
                fi
            fi
            BUILD_DIR=build_1_$i
	else
	    git checkout -f $i
	    ./autogen.sh
            ONE=""
            BUILD_DIR=build_$i
	fi

        rm -fr $BUILD_DIR
        mkdir $BUILD_DIR
        cd $BUILD_DIR

        CXXFLAGS=""
	if [[ $i == 8* || $i == 6*  ]]; then
	    HDF5_OPTS="--enable-production  --enable-cxx $OPTS"
            if [[ $i == 6* ]]; then
                HDF5_OPTS="$HDF5_OPTS --prefix $PWD/hdf5"
                CXXFLAGS="-DHDF5_1_6"
            fi
            if [[ $HOSTNAME == summit* ]]; then
                if  [[ $i =~ 8_[1-9].* || $i == 8 || $i == 6 ]]; then
                    # wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O bin/config.guess
                    # wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O bin/config.sub
                    git clone git://git.savannah.gnu.org/config.git
                    cp config/config.guess ../bin/
                    cp config/config.sub ../bin/
                    rm -fr config
                fi
            fi

	else
	    HDF5_OPTS="--enable-build-mode=production --enable-cxx $OPTS"
	fi

        # Disable building tools and tests if option is available
        if grep -q 'enable-tools' ../configure; then
            HDF5_OPTS="$HDF5_OPTS --disable-tools --disable-tests"
        fi

	HDF5=$PWD
        BUILD_CMD="../configure --disable-fortran --disable-hl --without-zlib --without-szlib  $HDF5_OPTS"

        printf "$mag $BUILD_CMD $nc\n"

	$BUILD_CMD

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
       if [[ $i == 6* ]]; then
            CXXFLAGS="-DHDF5_1_6"
        else
            CXXFLAGS=""
        fi

        if [[ $i =~ ^[0-9].* ]]; then
	    HDF5=$TOPDIR/hdf5/build_1_$i
	else
	    HDF5=$TOPDIR/hdf5/build_$i
            ONE=""
	fi
    fi

# Build EXAMPLE
    if [ $MATLABBUILD = 1 ]; then
        echo "$HDF5/hdf5/bin/h5c++ -o writeLargeNumDsets_$i writeLargeNumDsets.cpp"
        $HDF5/hdf5/bin/h5c++ $CXXFLAGS -o writeLargeNumDsets_$i writeLargeNumDsets.cpp
	status=$?
	if [[ $status != 0 ]]; then
            echo "FAILED TO COMPILE writeLargeNumDsets.cpp"
            rm -f writeLargeNumDsets_$i
	    exit $status
	fi
    fi
    if [ $TEST = 1 ]; then
       NTIMES=60
       VAL=""
       echo "HDF5 Version = 1_$i"
       rm -f time_x
       echo "1_$i" > time_x
       for ((n=1;n<=${NTIMES};n++));do
          (/usr/bin/time -p  ./writeLargeNumDsets_$i;) &> t.out
          grep -i "real" t.out | sed -e 's/.*\l\(.*\)/\1/' >> time_x
          rm -fr fileWithLargeNumDsets.h5
       done
       if test -f matlab-timings.$current_time; then
         cp matlab-timings.$current_time pre_x
         paste -d' ' pre_x time_x > matlab-timings.$current_time
         rm -f pre_x
       else
         cp time_x matlab-timings.$current_time
       fi
       VAR1="\"1_${i}\" "
       count=$(( count + 1 ))
       XTICS+=${VAR1}${count}" , "
       #echo $XTICS
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
    echo "#set xtics ("${XTICS}") scale 0.0" >> matlab-timings.$current_time
    #echo "#nprocs=$NPROCS, nelem=$NELEM" > ${PREFIX}matlab-timings.$current_time
    #echo "#nprocs=$NPROCS, nelem=$NELEM" > ${PREFIX}matlab-memory.$current_time
    #cat matlab_time_* >> ${PREFIX}matlab-timings.$current_time
    #cat matlab_mem_* >> ${PREFIX}matlab-memory.$current_time
    #sed -i 's/_/./g' ${PREFIX}matlab-timings.$current_time
    #sed -i 's/_/./g' ${PREFIX}matlab-memory.$current_time
    
    #rm -f matlab_*
fi

