#!/bin/bash
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
# Run just the serial tests
# 
# ./run_cgns.sh --hdf5_nobuild --cgns_nobuild
#
# Run the parallel tests (--ptest numproc numelem)
# ./run_cgns.sh --enable-parallel --hdf5_nobuild --cgns_nobuild --ptest 4 2014

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
nc='\033[0m' # No Color

printf "$cyn *******************************\n"
printf "      _____________   _______\n"
printf "     / ____/ ____/ | / / ___/\n"
printf "    / /   / / __/  |/ /\__ \ \n"
printf "   / /___/ /_/ / /|  /___/ / \n"
printf "   \____/\____/_/ |_//____/  \n"
printf " *******************************$nc\n"

PARALLEL=0
HDF5BUILD=1
CGNSBUILD=1
PTEST=0
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
    PTEST=1
    shift # past argument
    shift # past value
    shift # past value
    ;;
    --default)
    shift
    ;;
    --help | -h)
    printf "OPTIONS:\n"
    printf " --enable-parallel        enabled building parallel HDF5\n"
    printf " --hdf5_nobuild           don't build hdf5 libraries\n"
    printf " --cgns_nobuild           don't build the program\n"
    printf " --notest                 don't run the program\n"
    printf " --ptest NumProc Nelem    number of processes, and size of problem\n\n"
    exit 0
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

printf "\n$mag    SUMMARY \n  ------------\n"
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
    printf "FALSE \n $nc"
else
    printf "TRUE \n $nc"
fi
if [[ $PARALLEL != 1 ]]; then
   printf "$red Enabled Parallel: FALSE $nc \n\n"
   export CC="gcc"
   export FC="gfortran"
   export F77="gfortran"
else
   printf "$grn Enabled Parallel: TRUE $nc \n\n"
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
       export MPIEXEC="jsrun -n $NPROCS"
       export CC="mpicc"
       export FC="mpifort"
       export F77="mpifort"
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
VER_HDF5_2="8_11 8_12 8_13 8_14 8_15-patch1 8_16 8_17 8_18 8_19 8_20 8_21 8_22 8_23 8"
VER_HDF5_3="10_0-patch1 10_1 10_2 10_3 10_4 10_5 10_6 10_7 10_8 10_9 10_10 10_11 10 12_0 12_1 12_2 12_3 12 14_0 14_1 14_2 14_3 14_4 14 develop"

VER_HDF5=" $VER_HDF5_1 $VER_HDF5_2 $VER_HDF5_3"
#VER_HDF5="$VER_HDF5_3"
#VER_HDF5="8"

export LIBS="-ldl"
export FLIBS="-ldl"
#export LIBS="-Wl,--no-as-needed -ldl"

if [ $HDF5BUILD = 1 ]; then
    if [ -d "hdf5" ]; then
        rm -fr hdf5
    fi
    git clone https://github.com/HDFGroup/hdf5.git
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
	
	if [[ $i == 8* ]]; then
	    HDF5_OPTS="--enable-production $OPTS"

            if [[ $HOSTNAME == summit* ]]; then
                if  [[ $i =~ 8_[1-9].* || $i == 8 ]]; then
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
	fi

        # Disable building tools and tests if option is available
        if grep -q 'enable-tools' ../configure; then
            HDF5_OPTS="$HDF5_OPTS --disable-tools --disable-tests"
        fi

	HDF5=$PWD
        BUILD_CMD="../configure --disable-fortran --enable-hl --without-zlib --without-szlib  $HDF5_OPTS"

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

      # compile the tests
        cd tests
        make -j 16
        status=$?
        if [[ $status != 0 ]]; then
            echo "CGNS make #FAILED"
            exit $status
        fi
        cd ..

	if [[ $PARALLEL == 1 ]]; then
	    cd ptests
	    make -j 16
	    status=$?
	    if [[ $status != 0 ]]; then
		echo "PCGNS make #FAILED"
		exit $status
	    fi
            cd ..
        fi
    fi

    if [ $TEST = 1 ]; then
        j0=$(printf "%02d" $j)
        if [[ $PARALLEL != 1 ]]; then
            cd $TOPDIR/CGNS.$i/src
        # Build all the the tests
            cd tests; make -j 16; cd $TOPDIR/CGNS.$i/src
            cd examples/fortran; make -j 16; cd $TOPDIR/CGNS.$i/src
            cd Test_UserGuideCode/Fortran_code; make -j 16; cd $TOPDIR/CGNS.$i/src
            cd Test_UserGuideCode/C_code; make -j 16; cd $TOPDIR/CGNS.$i/src
            
        # Time make check (does not include the complilation time)
            NTIMES=10
            VAL=""
            rm -f $TOPDIR/cgns_time_$j0
            for ((n=1;n<=${NTIMES};n++));do
              /usr/bin/time -v -f "%e real" -o "results" make test
              ETIME=`grep "Elapsed" results | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'`
              VAL+=${ETIME}","
            done
            VAL2=`echo $VAL | sed 's/\,/\n/g'`
            VALS=`echo "$VAL2" | awk '{if(min==""){min=max=$1}; if($1>max) {max=$1}; if($1<min) {min=$1}; total+=$1; count+=1} END {print total/count, min, max}'`
            echo "$ONE$i $VALS" > $TOPDIR/cgns_time_$j0
        else
            PREFIX="p"
            cd $TOPDIR/CGNS.${i}/src/ptests
            make -j 16
      # Time make check (does not include the complilation time)
           # /usr/bin/time -v -f "%e real" -o "results" make test
            NTIMES=5
            VAL=""
            rm -f $TOPDIR/cgns_time_$j0
            for ((n=1;n<=${NTIMES};n++));do
              echo "TIMING ... $MPIEXEC benchmark_hdf5 -nelem $NELEM"
              /usr/bin/time -v -f "%e real" -o "results"  $MPIEXEC benchmark_hdf5 -nelem $NELEM
              ETIME=`grep "Elapsed" results | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'`
	      VAL+=${ETIME}"," 
            done
            VAL2=`echo $VAL | sed 's/\,/\n/g'`
            VALS=`echo "$VAL2" | awk '{if(min==""){min=max=$1}; if($1>max) {max=$1}; if($1<min) {min=$1}; total+=$1; count+=1} END {print total/count, min, max}'`
            echo "$ONE$i $VALS" > $TOPDIR/cgns_time_$j0
    
        fi
#        { echo -n "$ONE$i " & grep "Elapsed" result* | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'; } > $TOPDIR/cgns_time_$j0
#        { echo -n "$ONE$i " & grep "Maximum resident" result* | sed -n -e 's/^.*bytes): //p'; } > $TOPDIR/cgns_mem_$j0
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

    current_time=$(date "+%Y.%m.%d-%H.%M.%S")

    i=1
    FILE_T=${PREFIX}cgns-timings
    until [ ! -f "${FILE_T}" ]
      do
        ((i=i+1))
        FILE_T=${PREFIX}cgns-timings.${i}
      done

    #i=1
    #FILE_M=${PREFIX}cgns-memory
    #until [ ! -f "${FILE_M}" ]
    #  do
    #    ((i=i+1))
    #    FILE_M=${PREFIX}cgns-memory.${i}
    #  done

    FILE_T=${FILE_T}.$current_time
    echo "#nprocs=$NPROCS, nelem=$NELEM, ntim=$NTIMES" > ${FILE_T}
    #echo "#nprocs=$NPROCS, nelem=$NELEM, ntim=$NTIMES" > ${FILE_M}
    cat cgns_time_* >> ${FILE_T}
    #cat cgns_mem_* >> ${FILE_M}
    sed -i 's/_/./g' ${FILE_T}
    #sed -i 's/_/./g' ${FILE_M}

# Add extra spaces for gnuplot formating
    sed -i 's/\(1.8\|1.10\|1.12\|1.14\) [0-9].*/&\n\n/g' ${FILE_T}
    #sed -i 's/\(1.8\|1.10\|1.12\|1.14\) [0-9].*/&\n\n/g' ${FILE_M}

    rm -f cgns_*
fi

