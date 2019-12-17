#!/bin/bash
#
#
# This script will build CGNS, and get performance numbers, for all the currently released versions of HDF5.
#
# Download and Build all the versions of hdf5
#
#./run_cgns.sh --enable-parallel --notest --cgns_nobuild
#
# Build different versions of CGNS 
#
#./run_cgns.sh --enable-parallel --hdf5_nobuild --notest
#
# Build both, no testing
#
# ./run_cgns.sh --enable-parallel --notest
#
# run the tests
# ./run_cgns.sh --enable-parallel --hdf5_nobuild --cgns_nobuild --ptest 4 2014

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
nc='\033[0m' # No Color

printf "$cyn ***************************\n"
printf "   _____________   _______\n"
printf "  / ____/ ____/ | / / ___/\n"
printf " / /   / / __/  |/ /\__ \ \n"
printf "/ /___/ /_/ / /|  /___/ / \n"
printf "\____/\____/_/ |_//____/  \n"
printf " *******************************$nc\n"

PARALLEL=0
HDF5BUILD=1
CGNSBUILD=1
TEST=1
HDF5=""
PREFIX=""
ONE="1."
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
    --cgns_nobuild)
    CGNSBUILD=0
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
    printf "\n$red ERROR: unknown option $key $nc\n"
    exit 1
    ;;
esac
done

host=$HOSTNAME
HOSTNAME=`hostname -d`
OPTS=""

printf "\n$cyn    SUMMARY \n  ------------\n"
printf "BUILD HDF5: "
if [[ $HDF5BUILD != 0 ]]; then
    printf "TRUE \n"
else
    printf "FALSE \n"
fi
printf "BUILD CGNS: "
if [[ $CGNSBUILD != 0 ]]; then
    printf "TRUE \n"
else
    printf "FALSE \n"
fi
printf "NO TESTING: "
if [[ $TEST != 0 ]]; then
    printf "TRUE \n $nc"
else
    printf "FALSE \n $nc"
fi
if [[ $PARALLEL != 1 ]]; then
   printf "$red Enabled Parallel: FALSE $nc \n"
   export CC="gcc"
   export FC="gfortran"
   export F77="gfortran"
else
   printf "$grn Enabled Parallel: TRUE $nc \n"
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
   if [[ $HOSTNAME == summit* ]]; then
       export CC="mpicc"
       export FC="mpif90"
       export F77="mpif90"
   fi

#DEFAULT
   if [[ -z "$MPIEXEC" ]]; then
       export MPIEXEC="mpiexec -n $NPROCS"
       export CC="mpicc"
       export FC="mpif90"
       export F77="mpif90"
   fi

fi

# Output all the results in the cgns-timings file.
#

# List of all the HDF5 versions to run through
VER_HDF5_0="8_1 8_2 8_3-patched 8_4-patch1 8_5-patch1 8_6"
VER_HDF5_1="8_7 8_8 8_9 8_10-patch1"
VER_HDF5_2="8_11 8_12 8_13 8_14 8_15-patch1 8_16 8_17 8_18 8_19 8_20 8_21 8"
VER_HDF5_3="10_0-patch1 10_1 10_2 10_3 10_4 10_5 10_6 10 12_0_alpha1 12 develop"

VER_HDF5=" $VER_HDF5_1 $VER_HDF5_2 $VER_HDF5_3"
#VER_HDF5="$VER_HDF5_3"
#VER_HDF5="develop"
#VER_HDF5="10_3 10_4 10_5 merge_hyperslab_update_01 refactor_obj_create_params develop"

export LIBS="-ldl"
export FLIBS="-ldl"
#export LIBS="-Wl,--no-as-needed -ldl"

if [  $HDF5BUILD = 1 ]; then
    if [ -d "hdf5" ]; then
        rm -fr hdf5
    fi
    git clone https://brtnfld@bitbucket.hdfgroup.org/scm/hdffv/hdf5.git
fi

#if [ $CGNSBUILD = 1 ]; then
#    git clone https://github.com/CGNS/CGNS.git
#fi

j=0
for i in ${VER_HDF5}

do
    status=0
    j=$[j + 1]
# Build HDF5
    if [  $HDF5BUILD = 1 ]; then
	cd hdf5
        git checkout .

        if [[ $i =~ ^[0-9].* ]]; then
            if [[ $i == *"_"* ]]; then
                git checkout tags/hdf5-1_$i
            else
                git checkout hdf5-1_$i
            fi
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
	
	if [[ $i == 8* ]]; then
	    HDF5_OPTS="--enable-production $OPTS"

            if [[ $HOSTNAME == summit* ]]; then
                if  [[ $i =~ 8_[1-9].* ]]; then
                    git clone git://git.savannah.gnu.org/config.git
                    cp config/config.guess ../bin/
                    cp config/config.sub ../bin/
                    rm -fr config
                fi
            fi

	else
	    HDF5_OPTS="--enable-build-mode=production $OPTS"
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
        if [[ $i =~ ^[0-9].* ]]; then
	    HDF5=$TOPDIR/hdf5/build_1_$i
	else
	    HDF5=$TOPDIR/hdf5/build_$i
            ONE=""
	fi
    fi

# Build CGNS

    if [ $CGNSBUILD = 1 ]; then

        git clone https://github.com/CGNS/CGNS.git CGNS.$i
        
	cd ${TOPDIR}/CGNS.$i/src
        CONFDIR="."
        
#        if [ $TEST = 0 ]; then
#            rm -fr build_1_${i}
#            mkdir build_1_${i}
#            cd build_1_${i}
#            CONFDIR=".."
#        fi

	CONFIG_CMD="$CONFDIR/configure \
	--with-fortran \
	--with-hdf5=$HDF5/hdf5 \
	--enable-lfs \
	--disable-shared \
	--enable-debug \
	--disable-cgnstools \
	--enable-64bit $OPTS"

	echo "$CONFIG_CMD"
	$CONFIG_CMD
	
	make -j 16
	status=$?
	if [[ $status != 0 ]]; then
	    echo "CGNS make #FAILED"
	    exit $status
	fi
	if [[ $PARALLEL != 1 ]]; then
            cd tests
      # compile the tests
	    make -j 16
	    status=$?
	    if [[ $status != 0 ]]; then
		echo "CGNS make #FAILED"
		exit $status
	    fi
	else
	    cd ptests
	    make -j 16
	    status=$?
	    if [[ $status != 0 ]]; then
		echo "PCGNS make #FAILED"
		exit $status
	    fi
        fi
    fi
    if [ $TEST = 1 ]; then
        if [[ $PARALLEL != 1 ]]; then
            cd $TOPDIR/CGNS.$i/src/tests
            make -j 16
      # Time make check (does not include the complilation time)
            /usr/bin/time -v -f "%e real" -o "results" make test
        else
            PREFIX="p"
            cd $TOPDIR/CGNS.${i}/src/ptests
            make -j 16
      # Time make check (does not include the complilation time)
           # /usr/bin/time -v -f "%e real" -o "results" make test
            echo "TIMING ... $MPIEXEC benchmark_hdf5"
            /usr/bin/time -v -f "%e real" -o "results" $MPIEXEC benchmark_hdf5 -nelem $NELEM
        fi
        j0=$(printf "%02d" $j)
        { echo -n "$ONE$i " & grep "Elapsed" results | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'; } > $TOPDIR/cgns_time_$j0
        { echo -n "$ONE$i " & grep "Maximum resident" results | sed -n -e 's/^.*bytes): //p'; } > $TOPDIR/cgns_mem_$j0
        rm -fr benchmark_*.cgns 
    fi
    if [ $CGNSBUILD = 1 ]; then
        if [ $TEST = 1 ]; then
            rm -fr $TOPDIR/CGNS.$i
        fi
    fi
    cd $TOPDIR
done

# Combine the timing numbers to a single file
if [ $TEST = 1 ]; then
    echo "#nprocs=$NPROCS, nelem=$NELEM" > ${PREFIX}cgns-timings
    echo "#nprocs=$NPROCS, nelem=$NELEM" > ${PREFIX}cgns-memory
    cat cgns_time_* >> ${PREFIX}cgns-timings
    cat cgns_mem_* >> ${PREFIX}cgns-memory
    sed -i 's/_/./g' ${PREFIX}cgns-timings
    sed -i 's/_/./g' ${PREFIX}cgns-memory
    
    rm -f cgns_*
fi

