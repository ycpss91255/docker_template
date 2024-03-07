#!/usr/bin/env bash

# ${1}: ROS2 version
# ${2}: ROS2 network localhost or global
# ${3}: ROS2 global numble

# add ROS2 env setting to bash config
ROS_TYPE=$(echo ${2} | tr a-z A-Z)

if [ "${3}" != "0" ]; then
	echo "export ROS_DOMAIN_ID=${3}" >>/home/"${USER}"/.bashrc
elif [ "${ROS_TYPE}" == "LOCALHOST" ]; then
	echo "export ROS_LOCALHOST_ONLY=1" >>/home/"${USER}"/.bashrc
else
	echo "export ROS_DOMAIN_ID=0" >>/home/"${USER}"/.bashrc
fi

printf "
source /opt/ros/${ROS_DISTRO}/setup.bash

# colcon_cd
if dpkg -l | grep -q \"python3-colcon-common-extensions\"; then
    source /usr/share/colcon_cd/function/colcon_cd.sh
fi

if dpkg -l | grep -q \"python3-colcon-argcomplete\"; then
    source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash
fi

alias wb='source ~/work/install/local_setup.bash && echo \"You source workspace config!\"'
" >>/home/"${USER}"/.bashrc
