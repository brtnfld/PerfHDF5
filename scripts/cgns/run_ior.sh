#!/bin/bash
#
#
# This script will build IOR, and get performance numbers, for all the currently released versions of HDF5.
#
# Download and Build all the versions of hdf5
#
#./run_ior.sh --notest --ior_nobuild
#
# Build different versions of IOR 
#
# ./run_ior.sh  --hdf5_nobuild --notest
#
# Build both, no testing
#
# ./run_ior.sh --notest
#
# run the tests
# ./run_ior.sh --hdf5_nobuild --ior_nobuild --ptest 

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
nc='\033[0m' # No Color

HDF5BUILD=1
IORBUILD=1
TEST=1
HDF5=""
ACCOUNT=""
PREFIX=""
NPROCS=6
TOPDIR=$PWD
JID="00000"

# currently unused variables
printf " %b %b %b %b \n" "$yel" "$blu" "$mag" "$nc" 

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --hdf5)
    HDF5="$2" # root install directory
    shift # past argument
    shift # past value
    ;;
    -p)
    ACCOUNT=$2
    shift # past argument
    shift # past value
    ;;
    --hdf5_nobuild)
    HDF5BUILD=0
    shift
    ;;
    --ior_nobuild)
    IORBUILD=0
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
    printf " %b unknown option %s %b\n\n" "$red" "$key" "$nc"
    exit 1
    ;;
esac
done

host=$HOSTNAME

echo -e "${grn}Enabled Parallel: TRUE${nc}"
OPTS="--enable-parallel"
IOR_OPTS="--with-mpiio --with-posix --with-hdf5"

#DEFAULT
if [[ -z "$MPIEXEC" ]]; then
    export MPIEXEC="mpiexec -n $NPROCS"
    export CC="mpicc"
    export FC="mpif90"
    export F77="mpif90"
fi

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
    
#CHECKS
    if [[ $ACCOUNT == '' ]];then
        printf "${ERROR_COLOR}FATAL ERROR: SUMMIT REQUIRES AN ALLOCATION ID TO BE SET \n"
        printf "    Usage: -p <ALLOCATION ID> ${NO_COLOR}\n\n"
        exit 1
    fi
    
    UNAME=$HOSTNAME
    export MPIEXEC="jsrun -n $NPROCS"
    export CC="cc"
    export FC="ftn"
    export F77="ftn"
fi

# Output all the results in the ior-timings file.
#

# List of all the HDF5 versions to run through
#VER_HDF5_1="8_0 8_1 8_2 8_3-patch1 8_4-patch1 8_5-patch1 8_6 8_7 8_8 8_9 8_10-patch1 8_11 8_12 8_13 8_14 8_15-patch1"
VER_HDF5_2="8_11 8_12 8_13 8_14 8_15-patch1 8_16 8_17 8_18 8_19 8_20 8_21 8"
VER_HDF5_3="10_0-patch1 10_1 10_2 10_3 10_4 10_5 10 develop"
VER_HDF5="$VER_HDF5_1 $VER_HDF5_2 $VER_HDF5_3"

#VER_HDF5="10_3 10_4 10_5 merge_hyperslab_update_01 refactor_obj_create_params develop"
#VER_HDF5="merge_hyperslab_update_01"
#VER_HDF5="$VER_HDF5_3"
#VER_HDF5="10_5 10 develop"

##export LIBS="-ldl"
##export FLIBS="-ldl"
#export LIBS="-Wl,--no-as-needed -ldl"

if [  $HDF5BUILD = 1 ]; then
    if [ -d "hdf5" ]; then
        rm -fr hdf5
    fi
    git clone https://brtnfld@bitbucket.hdfgroup.org/scm/hdffv/hdf5.git
fi

if [ $IORBUILD = 1 ]; then
#    wget --no-check-certificate https://github.com/hpc/ior/releases/download/3.2.1/ior-3.2.1.tar.gz
#    tar xzf ior-3.2.1.tar.gz ior

    if [ -d "ior" ]; then
        rm -fr ior
    fi

    if ! git clone https://github.com/hpc/ior.git; then
	printf "%b *** TESTING SCRIPT ERROR ***\n" "$red"
	printf "   - FAILED COMMAND: git clone $CGNS_SRC %b\n" "$nc"
	exit 1
    fi

    cd ior || exit
    if ! ./bootstrap; then
	printf "%b *** TESTING SCRIPT ERROR ***\n" "$red"
	printf "   - IOR FAILED COMMAND: bootstrap %b\n" "$nc"
        exit 1
    fi
    cd .. || exit

fi
printf "%b\n" "$cyn"
printf "*******************************************\n"
printf "            ________  ____  \n"
printf "           /  _/ __ \/ __ \ \n"
printf "           / // / / / /_/ / \n"
printf "         _/ // /_/ / _, _/  \n"
printf "        /___/\____/_/ |_|   \n"
printf " *******************************************\n"
printf "%b\n" "$nc"

j=0
for i in ${VER_HDF5}

do
    status=0
    j=$((j + 1))
# Build HDF5
    if [  $HDF5BUILD = 1 ]; then
	cd hdf5 || exit

        if [[ $i =~ ^[0-9].* ]]; then
            git stash
	    git checkout tags/hdf5-1_"$i"
            wget -O bin/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
            wget -O bin/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'

	    rm -fr build_1_"$i"
	    mkdir build_1_"$i"
	    cd build_1_"$i" || exit
            if [[ $i =~ ^[0-9]+$ ]]; then # main version branches 1_8, 1_10, etc..
                ONE=""
              else
                ONE="1."
            fi
	else
            git stash
	    git checkout "$i"
            wget -O bin/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
            wget -O bin/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'

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
            if [[ $i == "develop" ]]; then
                HDF5_OPTS="--with-default-api-version=v110 $HDF5_OPTS"
            fi
	fi

	HDF5=$PWD
	../configure --disable-fortran --disable-hl $HDF5_OPTS
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
            ONE="1."
	else
	    HDF5=$TOPDIR/hdf5/build_$i
            ONE=""
	fi
    fi

# Build IOR

    export LD_LIBRARY_PATH="$HDF5/hdf5/lib:$LD_LIBRARY_PATH"

    if [ $IORBUILD = 1 ]; then

        if [ -d "$HDF5/hdf5/include" ]; then
            export CPPFLAGS="-I$HDF5/hdf5/include"
            export LDFLAGS="-L$HDF5/hdf5/lib"
       #     export LIBS="$HDF5_DIR/lib/libhdf5.a -ldl -lm -lz"
        else
	    printf "%b Incorrect IOR's HDF5 path $HDF5/hdf5 %b\n" "$red" "$nc"
	    exit $status
        fi
        
      #  H5_VERS_MINOR=`grep '#define H5_VERS_MINOR' $HDF5/hdf5/include/H5public.h | awk '{print $3}'`
      #  if (( $H5_VERS_MINOR > 10 )); then
      #      export CFLAGS="-DH5_USE_110_API"
      #  fi 
      #  tar xvzf ior-3.2.1.tar.gz

        if [ -d "${TOPDIR}"/IOR."$i" ]; then
            rm -fr "${TOPDIR}"/IOR."$i"/*
        else
            mkdir "${TOPDIR}"/IOR."$i"
        fi
	cd "${TOPDIR}"/IOR."$i" || exit

        CONFDIR="${TOPDIR}"/ior
        mkdir ior
        
	CONFIG_CMD="$CONFDIR/configure --prefix=$PWD/ior $IOR_OPTS"
        
	if ! $CONFIG_CMD; then
	    printf "%b configure command #FAILED: %s %b\n" "$red" "$CONFIG_CMD" "$nc"
	    exit 1
        fi
	
	if ! make -j 16 ; then
	    printf "%b IOR make #FAILED %b\n" "$red" "$nc"
	    exit 1
	fi
#
#	if ! make -i check; then
#	    printf "%b IOR make check (build) #FAILED %b\n" "$red" "$nc"
#	    exit 1
#	fi

	if ! make install ; then
	    printf "%b IOR make install #FAILED %b\n" "$red" "$nc"
	    exit 1
	fi
        
      #  export CFLAGS=""
    fi

    if [ $TEST = 1 ]; then

        cd "$TOPDIR"/IOR."$i"/ior/bin || exit

        $MPIEXEC ./ior -b 32m -t 16m -i 5 -a HDF5 -O summaryFormat=default -O summaryFile=ior_hdf_${NPROCS}.${JID}.txt
        
        write_max=$(tail -n3 ior_hdf_${NPROCS}.${JID}.txt | grep 'write' | awk  '{print $2}')
        write_min=$(tail -n3 ior_hdf_${NPROCS}.${JID}.txt | grep 'write' | awk  '{print $3}')
        write_mean=$(tail -n3 ior_hdf_${NPROCS}.${JID}.txt | grep 'write' | awk  '{print $4}')
        read_max=$(tail -n3 ior_hdf_${NPROCS}.${JID}.txt | grep 'read' | awk  '{print $2}')
        read_min=$(tail -n3 ior_hdf_${NPROCS}.${JID}.txt | grep 'read' | awk  '{print $3}')
        read_mean=$(tail -n3 ior_hdf_${NPROCS}.${JID}.txt | grep 'read' | awk  '{print $4}')

        j0=$(printf "%02d" $j)
        echo "$ONE$i $write_mean, $write_min, $write_max, $read_mean, $read_min, $read_max" > "$TOPDIR"/ior_time_"$j0"
        
    fi
#    if [ $IORBUILD = 1 ]; then
#        if [ $TEST = 1 ]; then
#            rm -fr $TOPDIR/IOR.$i
#        fi
#    fi
    cd "$TOPDIR" || exit
done

# Combine the timing numbers to a single file
if [ $TEST = 1 ]; then
    echo "#nprocs=$NPROCS" > ${PREFIX}ior-timings
    cat ior_time_* >> ${PREFIX}ior-timings
    sed -i 's/_/./g' ${PREFIX}ior-timings
    
#    rm -f ior_*
fi


