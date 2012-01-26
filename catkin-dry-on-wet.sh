#!/bin/sh -e

set -x
./buildfarm/sanity_check.sh

/bin/echo "vvvvvvvvvvvvvvvvvvv  catkin-workspace-all.sh vvvvvvvvvvvvvvvvvvvvvv"

if [ -z "$WORKSPACE" ] ; then
    /bin/echo "Don't see no workspace."
    exit 1
fi

cd $WORKSPACE

# get ros system tools
#sudo apt-get install -y python-pip
#sudo pip install --upgrade rosinstall
#sudo pip install --upgrade rosdep
if [ ! -d rosdep ]; then
  hg clone https://kforge.ros.org/rosrelease/rosdep
fi
cd rosdep
hg pull
hg up
sudo python setup.py install
cd ..

sudo sh -c "echo \"deb http://packages.ros.org/ros-shadow-fixed/ubuntu $UBUNTU_DISTRO main\" > /etc/apt/sources.list.d/ros-latest.list"
wget http://packages.ros.org/ros.key -O - | sudo apt-key add -
sudo apt-get update

curl -s https://raw.github.com/willowgarage/catkin/master/test/test.rosinstall > test.rosinstall
rosinstall -n --delete-changed-uris src test.rosinstall

#temp
sudo apt-get install -y libwxgtk2.8-dev ros-fuerte-swig-wx curl
export PATH=/opt/ros/fuerte/bin:$PATH

cd src
rm -f CMakeLists.txt
ln -s catkin/toplevel.cmake CMakeLists.txt
cd ..
#rm -rf build
mkdir -p build
cd build
DESTDIR=$WORKSPACE/install
rm -rf $DESTDIR
cmake -DCMAKE_INSTALL_PREFIX=$DESTDIR ../src
export ROS_HOME=$WORKSPACE/build/ros_home
export ROS_TEST_RESULTS_DIR=$WORKSPACE/build/test_results
make
#make -i test
make install

mkdir -p $WORKSPACE/dry_land
#rm -rf $WORKSPACE/dry_land/*
curl -s https://raw.github.com/willowgarage/catkin/master/test/unstable/desktop-overlay.rosinstall > $WORKSPACE/dry_land/desktop-overlay.rosinstall
curl -s https://raw.github.com/willowgarage/catkin/master/test/unstable/extras.rosinstall > $WORKSPACE/dry_land/extras.rosinstall
# temporary: protect against kforge auth errors
rosinstall -n --delete-changed-uris $WORKSPACE/dry_land $DESTDIR $WORKSPACE/dry_land/desktop-overlay.rosinstall $WORKSPACE/dry_land/extras.rosinstall
. $DESTDIR/setup.sh
. $WORKSPACE/dry_land/setup.sh
rosdep install -y -a
export VERBOSE=1
fail=0
if ! rosmake --status-rate=0.1 -a -k; then
  fail=1
fi
rosmake --status-rate=0.1 -a --test-only || true

$WORKSPACE/build/env.sh $WORKSPACE/src/ros/tools/rosunit/scripts/clean_junit_xml.py

/bin/echo "^^^^^^^^^^^^^^^^^^  catkin-workspace-all.sh ^^^^^^^^^^^^^^^^^^^^"

if [ $fail -eq 1 ]; then
  echo "Build failed"
  exit 1
fi

cd $WORKSPACE
$WORKSPACE/buildfarm/sanity_check.sh
