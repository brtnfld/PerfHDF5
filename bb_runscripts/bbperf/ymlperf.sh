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

# trunk is bbtconf.yml
# 1.8 is bb18tconf.yml
# 1.10 is bb110tconf.yml
CONFFILE=bbtconf.yml
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
DATASTORE=$DATASTORE"\", \"modules\": {\"use\": \"/opt/pkgs/modules/all\"}, \"toolsets\": [\"default\"], \"compilers\": [\"C\", \"Fortran\"]}"

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
python ../doftp.py $HOST $DIRN scripts . doyDistributeGet.py
python ./doyDistributeGet.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG $PRODUCT $CONFFILE
#
if [ "$SCHEDULE" != "change" ]
then
  python ../doftp.py $HOST $DIRN scripts . doySourceftp.py
  python ../doftp.py $HOST $DIRN scripts . doysrcuncompress.py
#
  python ./doySourceftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG $PRODUCT $CONFFILE
  python ./doysrcuncompress.py $PLATFORM $CONFIG hdfsrc $CONFFILE
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
python ../../doftp.py $HOST $DIRN scripts . doyftpuncompress.py
python ./doyftpuncompress.py $HOST $DIRN $PLATFORM $OSSIZE $PLATFORM $CONFIG bbparams ctest insbin $CONFFILE "$DATASTORE"
#
python ../../doftp.py $HOST $DIRN scripts . doyinstall.py
python ./doyinstall.py $PLATFORM $CONFIG bbparams $CONFFILE ctest insbin install
#
python ../../doftp.py $HOST $DIRN scripts . doyFilesftp.py
python ../../doftp.py $HOST $DIRN scripts . doyCTbuild.py
#
#combust_io
#
#h5core
#
#h5perf
python ./doyFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG h5perf ctest DTP/extra $CONFFILE
python ./doyCTbuild.py $CONFFILE $CONFIG h5perf ctest $PLATFORM "$DATASTORE"
#
#seism-core
#
python ./readJSON.py
#
cd ../../..

