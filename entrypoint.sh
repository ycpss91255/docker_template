#!/usr/bin/env bash

source /opt/ros/"${ROS_DISTRO}"/setup.bash
# echo "hello docker!!"

exec "${@}"
