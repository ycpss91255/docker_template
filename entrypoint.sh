#!/usr/bin/env bash
set -e

# source ROS1 + ROS2
source /opt/ros/noetic/setup.bash
source /opt/ros/foxy/setup.bash

_bridge_file="/bridge.yaml"
if [ -s ${_bridge_file} ]; then
    printf "Loading ROS2 bridge parameters from %s\n" "${_bridge_file}"
    rosparam load /bridge.yaml
fi

exec "${@}"

# MODE="$1"
# shift || true

# if [ "$MODE" = "dynamic" ]; then
#     echo "[Bridge] Using dynamic_bridge"
#     exec ros2 run ros1_bridge dynamic_bridge "$@"
# elif [ "$MODE" = "param" ]; then
#     echo "[Bridge] Using parameter_bridge"
#     exec ros2 run ros1_bridge parameter_bridge "$@"
# else
#     echo "[Bridge] Unknown mode: $MODE"
#     echo "Usage:"
#     echo "  docker run image dynamic   # run dynamic_bridge"
#     echo "  docker run image param     # run parameter_bridge"
#     exec "$MODE" "$@"
# fi
