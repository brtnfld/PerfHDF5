#!/bin/bash
#
# This script will build macsio, and get performance numbers, for all the currently released versions of HDF5.
#
# Download and Build all the versions of hdf5
#
#./run_macsio.sh --enable-parallel --notest --macsio_nobuild
#
# Build different versions of macsio 
#
#./run_macsio.sh --enable-parallel --hdf5_nobuild --notest
#
# Build both, no testing
#
# ./run_macsio.sh --enable-parallel --notest
#
# Run just the serial tests
# 
# ./run_macsio.sh --hdf5_nobuild --macsio_nobuild
#
# Run the parallel tests (--ptest numproc numelem)
# ./run_macsio.sh --enable-parallel --hdf5_nobuild --macsio_nobuild --ptest 4 2014

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
nc='\033[0m' # No Color

printf "$cyn *************************************** \n"
printf "  __  __          _____  _____ _____ ____   \n"
printf " |  \/  |   /\   / ____|/ ____|_   _/ __ \  \n"
printf " | \  / |  /  \ | |    | (___   | || |  | | \n"
printf " | |\/| | / /\ \| |     \___ \  | || |  | | \n"
printf " | |  | |/ ____ \ |____ ____) |_| || |__| | \n"
printf " |_|  |_/_/    \_\_____|_____/|_____\____/  \n"
printf " ******************************************$nc\n"

PARALLEL=0
HDF5BUILD=1
MACSIOBUILD=1
PTEST=0
TEST=1
HDF5=""
PREFIX=""
ONE="1."
NPROCS=8
TOPDIR=$PWD
SIZE=1M

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
    --macsio_nobuild)
    MACSIOBUILD=0
    shift
    ;;
    --notest)
    TEST=0
    shift
    ;;
    --ptest)
    NPROCS="$2" # Number of processes
    iSIZE="$3"
    PTEST=1
    shift # past argument
    shift # past value
    if echo "$iSIZE" | grep -q 'M'; then
        SIZE="$iSIZE" # Size of parallel problem
        shift # past value
    fi
    ;;
    --default)
    shift
    ;;
    --help | -h)
    printf "OPTIONS:\n"
    printf " --enable-parallel        enabled building parallel HDF5\n"
    printf " --hdf5_nobuild           don't build hdf5 libraries\n"
    printf " --macsio_nobuild         don't build the program\n"
    printf " --notest                 don't run the program\n"
    printf " --ptest NumProc size    number of processes, and size of problem\n\n"
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
printf "BUILD MACSIO: "
if [[ $MACSIOBUILD != 0 ]]; then
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
       export CXX="mpicxx"
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
       export CXX="mpicxx"
   fi

#DEFAULT
   if [[ -z "$MPIEXEC" ]]; then
       export MPIEXEC="mpiexec -n $NPROCS"
       export CC="mpicc"
       export FC="mpif90"
       export F77="mpif90"
       export CXX="mpicxx"
   fi

fi

# Output all the results in the macsio-timings file.
#

# List of all the HDF5 versions to run through
VER_HDF5_0="8_1 8_2 8_3-patched 8_4-patch1 8_5-patch1 8_6"
VER_HDF5_1="8_7 8_8 8_9 8_10-patch1"
VER_HDF5_2="8_11 8_12 8_13 8_14 8_15-patch1 8_16 8_17 8_18 8_19 8_20 8_21 8_22 8"
VER_HDF5_3="10_0-patch1 10_1 10_2 10_3 10_4 10_5 10_6 10_7 10 12_0 12 develop"

VER_HDF5=" $VER_HDF5_1 $VER_HDF5_2 $VER_HDF5_3"
#VER_HDF5="$VER_HDF5_3"
VER_HDF5="8_7 develop"

export LIBS="-ldl"
export FLIBS="-ldl"
#export LIBS="-Wl,--no-as-needed -ldl"

if [ $HDF5BUILD = 1 ]; then
    if [ -d "hdf5" ]; then
        rm -fr hdf5
    fi
    git clone https://github.com/HDFGroup/hdf5.git

# BUILD ZLIB
#    git clone https://github.com/madler/zlib
#    cd zlib
#    git checkout v1.2.11
#    ZLIB_DIR="$PWD/zlib-1.2.11/zlib"
#    ./configure --prefix=$ZLIB_DIR
#    make && make install
#    cd ..
#else
#     ZLIB_DIR="$PWD/zlib/zlib-1.2.11/zlib"
fi

if [ $MACSIOBUILD = 1 ]; then
    # BUILD DEPENDANTS
    
    ## JSON ##
    printf "$yel"
    printf "      _              \n"    
    printf "     (_)__ ___  ___  \n" 
    printf "    / (_-</ _ \/ _ \ \n" 
    printf " __/ /___/\___/_//_/ \n" 
    printf "|___/                \n\n"
    printf "$nc"
    git clone https://github.com/LLNL/json-cwx
    cd json-cwx/json-cwx
    sh autogen.sh
    JSON_DIR=$PWD/.plocal
    ./configure --prefix=$JSON_DIR
    make && make install
    cd $TOPDIR

    ## Get SILO ##    
    wget https://wci.llnl.gov/sites/wci/files/2021-01/silo-4.10.2.tgz
    tar xvzf silo-4.10.2.tgz
    cd silo-4.10.2
    patch -p1 < ../silo.v2.patch
    status=$?
    if [[ $status != 0 ]]; then
        printf "$red" "ERROR IN PATCHING SILO #FAILED \n" "$nc"
        exit $status
    fi
    SILO_SRC=$PWD
    cd $TOPDIR

else
   JSON_DIR=$PWD/json-cwx/.plocal
fi

#if [ $MACSIOBUILD = 1 ]; then
#    git clone https://github.com/MACSIO/MACSIO.git
#fi

j=0
for i in ${VER_HDF5}
do
    status=0
    j=$[j + 1]
# Build HDF5
    if [ $HDF5BUILD = 1 ]; then

        printf "$yel"
        printf "   __ _____  ________ \n"
        printf "  / // / _ \/ __/ __/ \n"
        printf " / _  / // / _//__ \  \n"
        printf "/_//_/____/_/ /____/  \n"
        printf "$nc"

	cd hdf5
        git checkout .

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
        cmd="../configure --disable-fortran --disable-hl --without-zlib --without-szlib  --disable-shared $HDF5_OPTS"
        #cmd="../configure --disable-fortran --disable-hl --with-zlib=$ZLIB_DIR --without-szlib  --disable-shared $HDF5_OPTS"

        printf "$mag $cmd $nc\n"

	$cmd

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

# Build MACSIO

    if [ $MACSIOBUILD = 1 ]; then

        ## SILO ##
        printf "$yel"
        printf "       _ _     \n"
        printf "  ___ (_) /__  \n" 
        printf " (_-</ / / _ \ \n"
        printf "/___/_/_/\___/ \n"
        printf "$nc \n"

        mkdir  silo.$i
        cd silo.$i
        SILO_DIR=$PWD/silo

        #export ZLIB_LIBRARIES="$ZLIB_DIR"
        #export LDFLAGS="-L$ZLIB_DIR/lib"
        #export LIBS="-lz -ldl"
        #export LD_LIBRARY_PATH="$LDFLAGS:$LD_LIBRARY_PATH"

        SILO_DIR=$PWD/silo

        LIB_ARCH="lib64"
        if [ -d "$HDF5/hdf5/lib" ]; then
             LIB_ARCH="lib"
        fi

        #--with-zlib=INC,DIR

        cmd="$SILO_SRC/configure --prefix=$SILO_DIR --with-hdf5=$HDF5/hdf5/include,$HDF5/hdf5/$LIB_ARCH --without-zlib --disable-hzip --disable-fpzip"
        printf "$yel $cmd $nc \n"
        $cmd

        make && make install

        cd $TOPDIR

        ## MACSIO ##
        git clone https://github.com/brtnfld/MACSio.git
	cd MACSio
        if [ -d "macsio.$i" ]; then
            rm -fr build.$i
        fi
        mkdir macsio.$i
        cd macsio.$i

        cmd="cmake -D CMAKE_INSTALL_PREFIX=$PWD \
            -D CMAKE_BUILD_TYPE=Production \
            -D CMAKE_EXE_LINKER_FLAGS="-ldl" \
            -D WITH_JSON-CWX_PREFIX=$JSON_DIR \
            -D WITH_SILO_PREFIX=$SILO_DIR \
            -D ENABLE_HDF5_PLUGIN=ON \
            -D ENABLE_HDF5_ZLIB=OFF \
            -D WITH_HDF5_PREFIX=$HDF5/hdf5 \
            -D ENABLE_HDF5_SZIP=OFF $TOPDIR/MACSio"

         #   -DENABLE_HDF5_ZLIB=ON \
         #   -DWITH_ZLIB_PREFIX=$ZLIB_DIR \
         #   -DZLIB_LIBRARIES=$ZLIB_DIR/lib/libz.a \

        printf "$yel $cmd $nc \n"
        $cmd

        make -j 8
	status=$?
	if [[ $status != 0 ]]; then
	    echo "MACSIO make #FAILED"
	    exit $status
	fi
        cd ..
    fi

    if [ $TEST = 1 ]; then

        MACSIO_DIR=$TOPDIR/MACSio

        j0=$(printf "%02d" $j)
        if [[ $PARALLEL != 1 ]]; then
            printf "$red" "NO VALID SERIAL TESTING\n" "$nc" 
      #      cd $TOPDIR/MACSIO.$i/src/tests
      #      make -j 16
      # Time make check (does not include the complilation time)
      #      NTIMES=4
      #      VAL=""
      #      rm -f $TOPDIR/macsio_time_$j0
      #      for ((n=1;n<=${NTIMES};n++));do
      #        /usr/bin/time -v -f "%e real" -o "results" make test
      #        ETIME=`grep "Elapsed" results | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'`
      #        VAL+=${ETIME}","
      #      done
      #      VAL2=`echo $VAL | sed 's/\,/\n/g'`
      #      VALS=`echo "$VAL2" | awk '{if(min==""){min=max=$1}; if($1>max) {max=$1}; if($1<min) {min=$1}; total+=$1; count+=1} END {print total/count, min, max}'`
      #      echo "$ONE$i $VALS" > $TOPDIR/macsio_time_$j0
        else
            #--no_collective 

            PREFIX="p"
            opt="--parallel_file_mode MIF 2"
            opt="--parallel_file_mode SIF 1"
            cd $MACSIO_DIR/macsio.${i}/macsio
            NTIMES=5
            VAL=""
            rm -f $TOPDIR/macsio_time_$j0
            cmd="$MPIEXEC ./macsio --interface hdf5 $opt --part_size $SIZE --num_dumps 1"
            #cmd="$MPIEXEC ./macsio --interface hdf5 $opt --part_mesh_dims 100 100 0 --num_dumps 1"
            printf "$i :: $cmd \n"
            for ((n=1;n<=${NTIMES};n++));do
              /usr/bin/time -v -f "%e real" -o "results" $cmd 
              ETIME=`grep "Elapsed" results | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'`
	      VAL+=${ETIME}"," 
              ls -aolFh *.h5
            done
            VAL2=`echo $VAL | sed 's/\,/\n/g'`
            VALS=`echo "$VAL2" | awk '{if(min==""){min=max=$1}; if($1>max) {max=$1}; if($1<min) {min=$1}; total+=$1; count+=1} END {print total/count, min, max}'`
            echo "$ONE$i $VALS" > $TOPDIR/macsio_time_$j0
    
        fi
#        { echo -n "$ONE$i " & grep "Elapsed" result* | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'; } > $TOPDIR/macsio_time_$j0
#        { echo -n "$ONE$i " & grep "Maximum resident" result* | sed -n -e 's/^.*bytes): //p'; } > $TOPDIR/macsio_mem_$j0
        rm -fr *.h5
    fi
    if [ $MACSIOBUILD = 1 ]; then
        if [ $TEST = 1 ]; then
            rm -fr $MACSIO_DIR/macsio.${i}
        fi
    fi
    cd $TOPDIR
done

# Combine the timing numbers to a single file
if [ $TEST = 1 ]; then

    i=1
    FILE_T=${PREFIX}macsio-timings
    until [ ! -f "${FILE_T}" ]
      do
        ((i=i+1))
        FILE_T=${PREFIX}macsio-timings.${i}
      done

    #i=1
    #FILE_M=${PREFIX}macsio-memory
    #until [ ! -f "${FILE_M}" ]
    #  do
    #    ((i=i+1))
    #    FILE_M=${PREFIX}macsio-memory.${i}
    #  done

    echo "#nprocs=$NPROCS, size=$SIZE, ntim=$NTIMES" > ${FILE_T}
    #echo "#nprocs=$NPROCS, nelem=$NELEM, ntim=$NTIMES" > ${FILE_M}
    cat macsio_time_* >> ${FILE_T}
    #cat macsio_mem_* >> ${FILE_M}
    sed -i 's/_/./g' ${FILE_T}
    #sed -i 's/_/./g' ${FILE_M}

# Add extra spaces for gnuplot formating
    sed -i 's/\(1.8\|1.10\|1.12\|1.14\) [0-9].*/&\n\n/g' ${FILE_T}
    #sed -i 's/\(1.8\|1.10\|1.12\|1.14\) [0-9].*/&\n\n/g' ${FILE_M}

    rm -f macsio_*
fi

