#!/bin/sh -ex

cat > $HOME/.pbuilderrc <<EOF
sudo mkdir -p /var/cache/pbuilder/ccache
sudo chmod a+w /var/cache/pbuilder/ccache
export CCACHE_DIR="/var/cache/pbuilder/ccache"
export PATH="/usr/lib/ccache:${PATH}"
EXTRAPACKAGES="ccache lsb-release ccache cmake libopenmpi-dev libboost-dev gccxml python-empy python-yaml python-setuptools openssl sudo wget"
BINDMOUNTS="${CCACHE_DIR}"
EOF


TOP=$(cd `dirname $0` ; /bin/pwd)

JOB_NAME=$1
DISTRO=$2
ARCH=$3

/usr/bin/env

SHORTJOB=$(dirname $1)

/bin/echo "SHORTJOB: $SHORTJOB"

$TOP/create_chroot.sh $DISTRO $ARCH

sudo pbuilder execute \
    --basetgz /var/cache/pbuilder/$DISTRO-$ARCH.tgz \
    --bindmounts /home \
    -- $TOP/$SHORTJOB.sh $DISTRO $ARCH

