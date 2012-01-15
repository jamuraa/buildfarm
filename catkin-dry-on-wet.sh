#!/bin/sh -e

./buildfarm/sanity_check.sh

/bin/echo "vvvvvvvvvvvvvvvvvvv  catkin-workspace-all.sh vvvvvvvvvvvvvvvvvvvvvv"

if [ -z "$WORKSPACE" ] ; then
    /bin/echo "Don't see no workspace."
    exit 1
fi

cd $WORKSPACE

curl -s https://raw.github.com/willowgarage/catkin/master/test/full.rosinstall > full.rosinstall
rosinstall -n src full.rosinstall

cd src
rm -f CMakeLists.txt
ln -s catkin/toplevel.cmake CMakeLists.txt
cd ..
rm -rf build
mkdir build
cd build
cmake ../src
export ROS_TEST_RESULTS_DIR=$WORKSPACE/build/test_results
make
#make -i test
#$WORKSPACE/build/env.sh $WORKSPACE/src/ros/tools/rosunit/scripts/clean_junit_xml.py
DESTDIR=$(/bin/pwd)/DESTDIR
make install DESTDIR=$DESTDIR

cd ..
mkdir dry
cd dry
curl -s https://raw.github.com/willowgarage/catkin/master/test/unstable/desktop-overlay.rosinstall > unstable.rosinstall
curl -s https://raw.github.com/willowgarage/catkin/master/test/unstable/extras.rosinstall >> unstable.rosinstall
rosinstall -n . $DESTDIR unstable.rosinstall
curl -s https://raw.github.com/willowgarage/catkin/master/test/unstable/perception_pcl-unstable-build-fix.diff > perception_pcl-unstable-build-fix.diff 
patch -d perception_pcl -p0 < perception_pcl-unstable-build-fix.diff
. setup.bash
. $DESTDIR/setup.bash
rosmake -a -k


/bin/echo "^^^^^^^^^^^^^^^^^^  catkin-workspace-all.sh ^^^^^^^^^^^^^^^^^^^^"

cd $WORKSPACE
$WORKSPACE/buildfarm/sanity_check.sh