set -ex
tmpdir=`mktemp -d`

APT_GET_DEPS="python-setuptools python-yaml python-pip libgtest-dev mercurial subversion git-core cmake build-essential openssh-client"
# Stuff that doesn't change much
PIP_STATIC_DEPS="nose mock coverage"
# Stuff that changes a lot (install with -U)
PIP_DEPS="rospkg rosdep rosinstall"
MANUAL_PY_DEP_HG_URIS="https://kforge.ros.org/rosrelease/rosci"

# Add the ROS repo
#sudo sh -c "echo \"deb http://packages.ros.org/ros-shadow-fixed/ubuntu $UBUNTU_DISTRO main\" > /etc/apt/sources.list.d/ros-latest.list"
sudo sh -c "echo \"deb http://packages.ros.org/ros-shadow-fixed/ubuntu $UBUNTU_DISTRO main\" > /etc/apt/sources.list.d/ros-latest.list"
#sudo sh -c "echo \"deb http://packages.ros.org/ros-shadow-fixed/ubuntu $UBUNTU_DISTRO main\" > /etc/apt/sources.list.d/ros-latest.list"
#sudo sh -c "echo \"deb http://50.28.27.175/repos/building $UBUNTU_DISTRO main\" > /etc/apt/sources.list.d/ros-latest.list"
wget http://packages.ros.org/ros.key -O - | sudo apt-key add -
sudo apt-get update

for p in $APT_GET_DEPS; do
  sudo apt-get install -y $p > /dev/null
done

for p in $PIP_STATIC_DEPS; do
  sudo pip install $p > /dev/null
done

for p in $PIP_DEPS; do
  sudo pip install -U $p > /dev/null
done

for u in $MANUAL_PY_DEP_HG_URIS; do
  cd $tmpdir
  hg clone $u `basename $u`
  cd `basename $u`
  sudo python setup.py install
done

# Ignore error on init; it might have already happened.
sudo rosdep init || true
rosdep update

rm -rf $WORKSPACE/src

# install the source we're supposed to build
wget $ROSINSTALL_URL -O $tmpdir/my.rosinstall
#DEBUG
hg clone ssh://vcs@kforge.ros.org/moveit/moveit_manipulation
rosinstall -n $WORKSPACE/src $tmpdir/my.rosinstall
# install all rosdep deps
ROS_PACKAGE_PATH=$WORKSPACE/src rosdep install -ya
# re-run rosinstall to produce a combined setup shell file
rosinstall -n $WORKSPACE/src /opt/ros/$ROSDISTRO_NAME $tmpdir/my.rosinstall

## bootstrap env
SETUP_FILE=$WORKSPACE/src/setup.sh
. $SETUP_FILE

export ROS_HOME=$WORKSPACE/ros_home
export ROS_TEST_RESULTS_DIR=$WORKSPACE/test_results
# HACK: shouldn't need to do this
#export ROS_PACKAGE_PATH=$WORKSPACE/$STACK_NAME:$ROS_PACKAGE_PATH

# rosbuild-specific stuff
#
fail=0
if ! rosmake -ak; then
  fail=1
fi

#TODO: turn on tests
#if cd $WORKSPACE/build && make -k test; then echo "tests passed"; fi
#
#CLEANED_TEST_DIR=$ROS_TEST_RESULTS_DIR/_hudson
#if [[ ! -d $CLEANED_TEST_DIR ]]; then
#  mkdir -p $CLEANED_TEST_DIR
#fi
#rosci-clean-junit-xml
#
## In case there are no test results, make one up, to keep Jenkins from declaring
## the build a failure
#cat > $WORKSPACE/build/test_results/_hudson/jenkins_dummy.xml <<EOF
#<?xml version="1.0" encoding="UTF-8"?>
#<testsuite tests="1" failures="0" time="1" errors="0" name="dummy">
#  <testcase name="dummy" status="run" time="1" classname="Results"/>
#</testsuite>
#EOF

sudo rm -rf $tmpdir

if [[ $fail -eq 1 ]]; then
  echo "Build failed"
  exit 1
fi
