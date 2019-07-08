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

CONFIG=StdMPIShar

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
DATASTORE=$DATASTORE"\", \"modules\": {\"use\": \"/opt/pkgs/modules/all\"}, \"toolsets\": {\"default\": [\"default\"]}, \"compilers\": [\"C\", \"Fortran\"]}"

mkdir $CONFIG
cd $CONFIG
python ../doftp.py $HOST $DIRN scripts3 . doftp.py

mkdir build
cd build
# Main configuration file
python ../doftp.py $HOST $DIRN scripts3 . bbtconf.json
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
python ../doftp.py $HOST $DIRN scripts3 . bbsystems.json
#
if [ "$SCHEDULE" != "change" ]
then
  python ../doftp.py $HOST $DIRN scripts3 . doySourceftp.py
  python ../doftp.py $HOST $DIRN scripts3 . doysrcuncompress.py
#
  python ./doySourceftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG $PRODUCT/ $CONFFILE
  python ./doysrcuncompress.py $PLATFORM $CONFIG hdfsrc $CONFFILE
fi
#
mkdir autotools
cd autotools
#
#
# Product configuration file
python ../../doftp.py $HOST $DIRN $PRODUCT/ . $CONFFILE
#
python ../../doftp.py $HOST $DIRN scripts3 . readJSON.py
#
mkdir util_functions
python ../../doftp.py $HOST $DIRN scripts3/util_functions util_functions __init__.py
python ../../doftp.py $HOST $DIRN scripts3/util_functions util_functions util_functions.py
python ../../doftp.py $HOST $DIRN scripts3/util_functions util_functions at_functions.py
python ../../doftp.py $HOST $DIRN scripts3/util_functions util_functions ct_functions.py
python ../../doftp.py $HOST $DIRN scripts3/util_functions util_functions cdash_functions.py
python ../../doftp.py $HOST $DIRN scripts3/util_functions util_functions step_functions.py
python ../../doftp.py $HOST $DIRN scripts3/util_functions util_functions ctest_log_parser.py
python ../../doftp.py $HOST $DIRN scripts3/util_functions util_functions log_parse.py
python ../../doftp.py $HOST $DIRN scripts3/util_functions util_functions six.py
#
python ../../doftp.py $HOST $DIRN scripts3 . doyDistributeGet.py
python ./doyDistributeGet.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG bbparams $CONFFILE
#
python ../../doftp.py $HOST $DIRN scripts3 . doyFilesftp.py
python ./doyFilesftp.py $HOST $DIRN $PLATFORM $PLATFORM $CONFIG bbparams autotools DTP/extra $CONFFILE
python ../../doftp.py $HOST $DIRN scripts3 . doyATbuild.py
python ./doyATbuild.py $HOST $DIRN $CONFFILE $CONFIG bbparams $PLATFORM $OSSIZE insbin $SCHEDULE "$DATASTORE"
python ../../doftp.py $HOST $DIRN scripts3 . doybtftpup.py
python ./doybtftpup.py $HOST $DIRN $PLATFORM $OSSIZE $PLATFORM $CONFIG bbparams autotools $PRODUCT $CONFFILE "$DATASTORE"
#
python ./readJSON.py
#
cd ../../..
