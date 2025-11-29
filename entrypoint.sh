#!/usr/bin/env bash

# echo "hello docker!!"
source /opt/ros/${ROS_DISTRO}/setup.bash
source /ros_ws/install/local_setup.bash

exec "${@}"
