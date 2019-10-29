#!/bin/bash
#
#
# This script will build NETCDF, and get performance numbers, for all the currently released versions of HDF5.
#
# Download and Build all the versions of hdf5
#
#./run_netcdf.sh --enable-parallel --notest --netcdf_nobuild
#
# Build different versions of NETCDF 
#
# ./run_netcdf.sh --enable-parallel --hdf5_nobuild --notest
#
# Build both, no testing
#
# ./run_netcdf.sh --enable-parallel --notest
#
# run the tests
# ./run_netcdf.sh --enable-parallel --hdf5_nobuild --netcdf_nobuild --ptest 4 2014

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
nc='\033[0m' # No Color

PARALLEL=0
HDF5BUILD=1
NETCDFBUILD=1
TEST=1
HDF5=""
PREFIX=""
NPROCS=6
TOPDIR=$PWD

# currently unused variables
printf " %b %b %b %b \n" "$yel" "$blu" "$mag" "$nc" 

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
    --netcdf_nobuild)
    NETCDFBUILD=0
    shift
    ;;
    --notest)
    TEST=0
    shift
    ;;
    --ptest)
    NPROCS="$2" # Number of processes
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
   NETCDF_OPTS="--enable-parallel4"

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

# Output all the results in the netcdf-timings file.
#

# List of all the HDF5 versions to run through
VER_HDF5_1="8_12 8_13 8_14 8_15-patch1"
VER_HDF5_2="8_16 8_17 8_18 8_19 8_20 8_21"
VER_HDF5_3="10_0-patch1 10_1 10_2 10_3 10_4 1_10 develop"

VER_HDF5="$VER_HDF5_1 $VER_HDF5_2 $VER_HDF5_3"
VER_HDF5="10_3 10_4 10_5 merge_hyperslab_update_01 refactor_obj_create_params develop"
#VER_HDF5="merge_hyperslab_update_01"
#VER_HDF5="$VER_HDF5_3"
#VER_HDF5="10_1"

export LIBS="-ldl"
export FLIBS="-ldl"
#export LIBS="-Wl,--no-as-needed -ldl"

if [  $HDF5BUILD = 1 ]; then
    if [ -d "hdf5" ]; then
        rm -fr hdf5
    fi
    git clone https://brtnfld@bitbucket.hdfgroup.org/scm/hdffv/hdf5.git
fi
if [ $NETCDFBUILD = 1 ]; then
    tar xvzf netcdf-c-4.6.2.tar.gz
fi

printf "%b *******************************************\n" "$cyn" 
printf "      _   __     __  __________  ______\n"
printf "     / | / /__  / /_/ ____/ __ \/ ____/\n"
printf "    /  |/ / _ \/ __/ /   / / / / /_\n"  
printf "   / /|  /  __/ /_/ /___/ /_/ / __/\n"   
printf "  /_/ |_/\___/\__/\____/_____/_/\n" 
printf " ******************************************* %b\n" "$nc"

j=0
for i in ${VER_HDF5}

do
    status=0
    j=$((j + 1))
# Build HDF5
    if [  $HDF5BUILD = 1 ]; then
	cd hdf5 || exit

        if [[ $i =~ ^[0-9].* ]]; then
	    git checkout tags/hdf5-1_"$i"
	    rm -fr build_1_"$i"
	    mkdir build_1_"$i"
	    cd build_1_"$i" || exit
	else
	    git checkout "$i"
	    ./autogen.sh
	    rm -fr build_"$i"
	    mkdir build_"$i"
	    cd build_"$i" || exit
            ONE=""
	fi
	
	if [[ $i == 8* ]]; then
	    HDF5_OPTS="--enable-production $OPTS"	
	else
            HDF5_OPTS="--enable-build-mode=production $OPTS"
            if [[ $i != 10* ]]; then
                HDF5_OPTS="--with-default-api-version=v110 $HDF5_OPTS"
            fi
	fi

	HDF5=$PWD
	../configure --disable-fortran "$HDF5_OPTS"
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

# Build NETCDF

#    export LD_LIBRARY_PATH="$HDF5/hdf5/lib"

    if [ $NETCDFBUILD = 1 ]; then

        if [ -d "$HDF5/hdf5/include" ]; then
            export CPPFLAGS="-I$HDF5/hdf5/include"
            export LDFLAGS="-L$HDF5/hdf5/lib"
        else
	    echo "Incorrect NETCDF's HDF5 path $HDF5/hdf5"
	    exit $status
        fi
        
      #  H5_VERS_MINOR=`grep '#define H5_VERS_MINOR' $HDF5/hdf5/include/H5public.h | awk '{print $3}'`
      #  if (( $H5_VERS_MINOR > 10 )); then
      #      export CFLAGS="-DH5_USE_110_API"
      #  fi 

        tar xvzf netcdf-c-4.6.2.tar.gz

        if [ -d "${TOPDIR}"/NETCDF."$i" ]; then
            rm -fr "${TOPDIR}"/NETCDF."$i"/*
        else
            mkdir "${TOPDIR}"/NETCDF."$i"
        fi
	cd "${TOPDIR}"/NETCDF."$i" || exit

        CONFDIR="${TOPDIR}"/netcdf-c-4.6.2/

	CONFIG_CMD="$CONFDIR/configure --enable-shared=no \
	--prefix=$PWD/netcdf $NETCDF_OPTS"
        
	echo "$CONFIG_CMD"
	$CONFIG_CMD
	
	make -j 16
	status=$?
	if [[ $status != 0 ]]; then
	    echo "NETCDF make #FAILED"
	    exit $status
	fi
        make -i -j 16 check
	status=$?
	if [[ $status != 0 ]]; then
	    echo "NETCDF make check (build) #FAILED"
	    exit $status
	fi
      #  export CFLAGS=""
    fi

    if [ $TEST = 1 ]; then
        cd "$TOPDIR"/NETCDF."$i" || exit
      # Time make check (does not include the complilation time)
        /usr/bin/time -v -f "%e real" -o "results" make -i check

        j0=$(printf "%02d" $j)
        { echo -n "$ONE$i " & grep "Elapsed" results | sed -n -e 's/^.*ss): //p' | awk -F: '{ print ($1 * 60) + $2 }'; } > "$TOPDIR"/netcdf_time_"$j0"
        { echo -n "$ONE$i " & grep "Maximum resident" results | sed -n -e 's/^.*bytes): //p'; } > "$TOPDIR":/netcdf_mem_"$j0"
    fi
#    if [ $NETCDFBUILD = 1 ]; then
#        if [ $TEST = 1 ]; then
#            rm -fr $TOPDIR/NETCDF.$i
#        fi
#    fi
    cd "$TOPDIR" || exit
done

# Combine the timing numbers to a single file
if [ $TEST = 1 ]; then
    echo "#nprocs=$NPROCS" > ${PREFIX}netcdf-timings
    echo "#nprocs=$NPROCS" > ${PREFIX}netcdf-memory
    cat netcdf_time_* >> ${PREFIX}netcdf-timings
    cat netcdf_mem_* >> ${PREFIX}netcdf-memory
    sed -i 's/_/./g' ${PREFIX}netcdf-timings
    sed -i 's/_/./g' ${PREFIX}netcdf-memory
    
    rm -f netcdf_*
fi

