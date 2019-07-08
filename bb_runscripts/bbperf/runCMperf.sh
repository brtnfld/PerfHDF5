# PLATFORM list
# "fedora",
# "debian",
# "ubuntu",
# "opensuse",
# "centos6",
# "centos7",
# "cygwin",
# "ppc64",
# "osx109",
# "osx1010",
# "osx1011",
# "osx1012",
# "osx1013",
# "osx1014",

USAGE()
{
cat << EOF
Usage: $0 <platform>
   Run tests for <platform>

EOF

}


if [ $# != 1 ]; then
    USAGE
    exit 1
fi

PLATFORM="$1"

# trunk is bbtconf.json
# 1.8 is bb18tconf.json
# 1.10 is bb110tconf.json
CONFFILE=bbtconf.json
PRODUCT=hdf5perf
#
HOST='206.221.145.51'
DIRN='/mnt/ftp/pub/outgoing/QATEST/'

GENERATOR='Unix Makefiles'
OSSIZE=64

# trunk is StdMPITrunk
# 1.8 is StdMPI18
# 1.10 is StdMPI110
CONFIG=StdMPITrunk

# SCHEDULE list
# "weekly",
# "nightly",
# "change",
SCHEDULE=weekly

DATASTORE="{\"generator\": \""
DATASTORE=$DATASTORE"$GENERATOR"
DATASTORE=$DATASTORE"\", \"scheduler\": \""
DATASTORE=$DATASTORE"$SCHEDULE"
DATASTORE=$DATASTORE"\", \"modules\": {\"use\": \"/opt/pkgs/modules/all\"}, \"toolsets\": {\"default\": [\"default\"], \"MPI\": [\"default\"]}, \"compilers\": [\"C\", \"Fortran\"]}"

mkdir $CONFIG
cd $CONFIG
python ../doftp.py $HOST $DIRN scripts . doftp.py

mkdir build
cd build
# Main configuration file
python ../doftp.py $HOST $DIRN scripts . bbtconf.json
#
if [ "$SCHEDULE" == "change" ]
then
  mkdir hdfsrc
  cd hdfsrc
  #git clone --branch master 'ssh://git@bitbucket.hdfgroup.org:7999/hdffv/performance.git' . --progress
  git clone --branch master 'https://git@bitbucket.hdfgroup.org/scm/hdffv/performance.git' . --progress
  #
  cd ..
fi
#
# Product configuration file
python ../doftp.py $HOST $DIRN $PRODUCT/ . $CONFFILE
# Platform configuration file
python ../doftp.py $HOST $DIRN scripts . bbsystems.json
#
if [ "$SCHEDULE" != "change" ]
then
  python ../doftp.py $HOST $DIRN scripts . doSourceftp.py
  python ../doftp.py $HOST $DIRN scripts . dosrcuncompress.py
#
  python ./doSourceftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG $PRODUCT $CONFFILE
  python ./dosrcuncompress.py $PLATFORM $CONFIG hdfsrc $CONFFILE
fi
#
mkdir ctest
cd ctest
#
# Product configuration file
python ../../doftp.py $HOST $DIRN $PRODUCT/ . $CONFFILE
#
python ../../doftp.py $HOST $DIRN scripts . readJSON.py
#
mkdir util_functions
python ../../doftp.py $HOST $DIRN scripts/util_functions util_functions __init__.py
python ../../doftp.py $HOST $DIRN scripts/util_functions util_functions util_functions.py
python ../../doftp.py $HOST $DIRN scripts/util_functions util_functions at_functions.py
python ../../doftp.py $HOST $DIRN scripts/util_functions util_functions ct_functions.py
python ../../doftp.py $HOST $DIRN scripts/util_functions util_functions cdash_functions.py
python ../../doftp.py $HOST $DIRN scripts/util_functions util_functions step_functions.py
python ../../doftp.py $HOST $DIRN scripts/util_functions util_functions ctest_log_parser.py
python ../../doftp.py $HOST $DIRN scripts/util_functions util_functions log_parse.py
python ../../doftp.py $HOST $DIRN scripts/util_functions util_functions six.py
#
python ../../doftp.py $HOST $DIRN scripts . doDistributeGet.py
python ./doDistributeGet.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG bbparams $CONFFILE
#
python ../../doftp.py $HOST $DIRN scripts . doFilesftp.py
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG bbparams ctest DTP/extra $CONFFILE
python ../../doftp.py $HOST $DIRN scripts . doCTbuild.py
#
#combust_io
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG combust_io ctest DTP/extra $CONFFILE
python ./doCTbuild.py $HOST $DIRN $CONFFILE $CONFIG combust_io ctest $PLATFORM $OSSIZE insbin "$DATASTORE"
#
#h5core
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG h5core ctest DTP/extra $CONFFILE
python ./doCTbuild.py $HOST $DIRN $CONFFILE $CONFIG h5core ctest $PLATFORM $OSSIZE insbin "$DATASTORE"
#
#h5perf
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG h5perf ctest DTP/extra $CONFFILE
python ./doCTbuild.py $HOST $DIRN $CONFFILE $CONFIG h5perf ctest $PLATFORM $OSSIZE insbin "$DATASTORE"
#
#seism-core
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG seism-core ctest DTP/extra $CONFFILE
python ./doCTbuild.py $HOST $DIRN $CONFFILE $CONFIG seism-core ctest $PLATFORM $OSSIZE insbin "$DATASTORE"
#
python ./readJSON.py
#
cd ../../..

