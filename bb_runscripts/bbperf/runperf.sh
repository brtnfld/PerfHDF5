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
DATASTORE=$DATASTORE"\", \"modules\": {\"use\": \"/opt/pkgs/modules/all\"}, \"toolsets\": [\"default\"], \"compilers\": [\"C\", \"Fortran\", \"Java\"]}"

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
python ../doftp.py $HOST $DIRN scripts . doDistributeGet.py
python ./doDistributeGet.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG $PRODUCT/ $CONFFILE
python ../doftp.py $HOST $DIRN scripts . doftpuncompress.py
python ./doftpuncompress.py $HOST $DIRN $PLATFORM $OSSIZE $PLATFORM $CONFIG bbparams autotools insbin $CONFFILE "$DATASTORE"
python ../doftp.py $HOST $DIRN scripts . doatlin.py
python ./doatlin.py insbin $CONFIG bbparams autotools $CONFFILE
#
if [ "$SCHEDULE" != "change" ]
then
  python ../doftp.py $HOST $DIRN scripts . doSourceftp.py
  python ../doftp.py $HOST $DIRN scripts . dosrcuncompress.py
#
  python ./doSourceftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG $PRODUCT/ $CONFFILE
  python ./dosrcuncompress.py $PLATFORM $CONFIG hdfsrc $CONFFILE
fi
#
mkdir autotools
cd autotools
#
python ../../doftp.py $HOST $DIRN scripts . doFilesftp.py
python ../../doftp.py $HOST $DIRN scripts . doATbuild.py
# Product configuration file
python ../../doftp.py $HOST $DIRN $PRODUCT/ . $CONFFILE
#
python ../../doftp.py $HOST $DIRN scripts . readJSON.py
#
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG bbparams autotools DTP/extra $CONFFILE
#
#combust_io test
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG combust_io autotools DTP/extra $CONFFILE
python ./doATbuild.py $CONFFILE $CONFIG combust_io $PLATFORM insbin $SCHEDULE "$DATASTORE"
#
#h5core test
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG h5core autotools DTP/extra $CONFFILE
python ./doATbuild.py $CONFFILE $CONFIG h5core $PLATFORM insbin $SCHEDULE "$DATASTORE"
#
#h5perf test
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG h5perf autotools DTP/extra $CONFFILE
python ./doATbuild.py $CONFFILE $CONFIG h5perf $PLATFORM insbin $SCHEDULE "$DATASTORE"
#
#seism-core test
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG seism-core autotools DTP/extra $CONFFILE
python ./doATbuild.py $CONFFILE $CONFIG seism-core $PLATFORM insbin $SCHEDULE "$DATASTORE"
#
python ./readJSON.py
#
cd ../../..

