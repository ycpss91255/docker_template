#!/usr/bin/env bash

source /opt/ros/${ROS_DISTRO}/setup.bash
source /ros_ws/install/local_setup.sh

exec "${@}"
