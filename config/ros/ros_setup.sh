#!/usr/bin/env bash

# ${1}: ROS_DISTRO
# ${2}: ROS network localhost or global
# ${3}: ROS master IP
# ${4}: ROS slave IP

# add ROS env setting to bash config
IPV4REGEX="([0-9]{1,3}\.){3}[0-9]{1,3}"

ROS_SCOPE=$(echo ${2} | tr A-Z a-z)
ROS_DISTRO=$(echo ${1} | tr A-Z a-z)

if [[ "${2}" == "global" && ! "${3}" =~ $IPV4REGEX && ! "${4}" =~ $IPV4REGEX ]]; then
    ROS_MASTER_IP="${3}"
    ROS_SLAVE_IP="${4}"
else
    # localhost or unknown input
    ROS_MASTER_IP="127.0.0.1"
    ROS_SLAVE_IP=$ROS_MASTER_IP
fi

printf "
export ROS_MASTER_URI=http://${ROS_MASTER_IP}:11311
export ROS_IP=${ROS_SLAVE_IP}
source /opt/ros/${ROS_DISTRO}/setup.bash

alias wb='source ~/work/devel/setup.bash &&
    echo \"You source workspace config!\"'
" >> /home/"${USER}"/.bashrc

