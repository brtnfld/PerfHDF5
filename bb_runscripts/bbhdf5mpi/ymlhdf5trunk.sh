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

CONFFILE=bbtconf.yml
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
SCHEDULE=change

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
python ../doftp.py $HOST $DIRN scripts . doyDistributeGet.py
python ./doyDistributeGet.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG $PRODUCT/ $CONFFILE
python ../doftp.py $HOST $DIRN scripts . doyftpuncompress.py
python ./doyftpuncompress.py $HOST $DIRN $PLATFORM $OSSIZE $PLATFORM $CONFIG bbparams autotools insbin $CONFFILE "$DATASTORE"
python ../doftp.py $HOST $DIRN scripts . doyatlin.py
python ./doyatlin.py insbin $CONFIG bbparams autotools $CONFFILE
#
if [ "$SCHEDULE" != "change" ]
then
  python ../doftp.py $HOST $DIRN scripts . doySourceftp.py
  python ../doftp.py $HOST $DIRN scripts . doysrcuncompress.py
#
  python ./doySourceftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG $PRODUCT/ $CONFFILE
  python ./doysrcuncompress.py $PLATFORM $CONFIG hdfsrc $CONFFILE
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
python ../../doftp.py $HOST $DIRN scripts . doyFilesftp.py
python ./doyFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG bbparams autotools DTP/extra $CONFFILE
python ../../doftp.py $HOST $DIRN scripts . doyATbuild.py
python ./doyATbuild.py $CONFFILE $CONFIG bbparams $PLATFORM insbin $SCHEDULE "$DATASTORE"
python ../../doftp.py $HOST $DIRN scripts . doyATinstall.py
python ./doyATinstall.py $CONFFILE $CONFIG bbparams $PLATFORM $SCHEDULE "$DATASTORE"
python ../../doftp.py $HOST $DIRN scripts . doyATinstallcheck.py
python ./doyATinstallcheck.py $CONFFILE $CONFIG bbparams $PLATFORM $SCHEDULE "$DATASTORE"
python ../../doftp.py $HOST $DIRN scripts . doyATpackage.py
python ./doyATpackage.py $CONFFILE $CONFIG bbparams $PLATFORM $OSSIZE $SCHEDULE
python ../../doftp.py $HOST $DIRN scripts . doybtftpup.py
python ./doybtftpup.py $HOST $DIRN $PLATFORM $OSSIZE $PLATFORM $CONFIG bbparams autotools "$GENERATOR" $PRODUCT $CONFFILE
python ../../doftp.py $HOST $DIRN scripts . doyATuninstall.py
python ./doyATuninstall.py $CONFFILE $CONFIG bbparams $PLATFORM $SCHEDULE "$DATASTORE"
#
python ./readJSON.py
#
cd ../../..
