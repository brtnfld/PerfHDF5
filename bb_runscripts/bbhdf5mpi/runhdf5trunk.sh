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
PLATFORM="$1"

CONFFILE=bbtconf.json
# PRODUCT - BRANCH list
# "hdf5trunk","develop",
# "hdf518","hdf5_1_8",
# "hdf5110","hdf5_1_10",
PRODUCT=hdf5trunk
BRANCH=develop

HOST='206.221.145.51'
DIRN='/mnt/ftp/pub/outgoing/QATEST/'

GENERATOR='Unix Makefiles'
OSSIZE=64

CONFIG=StdShar

# TOOLSET list
# "default",
# "GCC",
# "intel",

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
  git clone --branch $BRANCH 'ssh://git@bitbucket.hdfgroup.org:7999/hdffv/hdf5.git' . --progress
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
# Product configuration file
python ../../doftp.py $HOST $DIRN $PRODUCT/ . $CONFFILE
#
python ../../doftp.py $HOST $DIRN scripts . readJSON.py
#
python ../../doftp.py $HOST $DIRN scripts . doFilesftp.py
python ./doFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG bbparams autotools DTP/extra $CONFFILE
python ../../doftp.py $HOST $DIRN scripts . doATbuild.py
python ./doATbuild.py $CONFFILE $CONFIG bbparams $PLATFORM insbin $SCHEDULE "$DATASTORE"
python ../../doftp.py $HOST $DIRN scripts . doATinstall.py
python ./doATinstall.py $CONFFILE $CONFIG bbparams $PLATFORM $SCHEDULE "$DATASTORE"
python ../../doftp.py $HOST $DIRN scripts . doATinstallcheck.py
python ./doATinstallcheck.py $CONFFILE $CONFIG bbparams $PLATFORM $SCHEDULE "$DATASTORE"
python ../../doftp.py $HOST $DIRN scripts . doATpackage.py
python ./doATpackage.py $CONFFILE $CONFIG bbparams $PLATFORM $OSSIZE $SCHEDULE
python ../../doftp.py $HOST $DIRN scripts . dobtftpup.py
python ./dobtftpup.py $HOST $DIRN $PLATFORM $OSSIZE $PLATFORM $CONFIG bbparams autotools "$GENERATOR" $PRODUCT $CONFFILE
python ../../doftp.py $HOST $DIRN scripts . doATuninstall.py
python ./doATuninstall.py $CONFFILE $CONFIG bbparams $PLATFORM $SCHEDULE "$DATASTORE"
#
python ./readJSON.py
#
cd ../../..
