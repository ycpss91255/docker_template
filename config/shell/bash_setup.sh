#!/usr/bin/env bash

# ${1}: USER
# ${2}: GROUP

# Write Hello and alias to bashrc
cat << 'EOF' >> /home/"${1}"/.bashrc
echo 'Hello Docker!'

# Commonly used aliases
alias wb='source ~/work/install/local_setup.bash && \
    echo "You source workspace config!"'

EOF

# Write Color and git branch to bashrc
cat << 'EOF' >> /home/"${1}"/.bashrc
# Color and git branch
force_color_prompt=yes
color_prompt=yes

parse_git_branch() {
 git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
fi

unset color_prompt force_color_prompt
EOF


cat << 'EOF' >> /home/"${1}"/.bashrc
if [ -f "/usr/share/colcon_cd/function/colcon_cd.sh" ]; then
    source /usr/share/colcon_cd/function/colcon_cd.sh
fi

if [ -f "/etc/bash_completion" ]; then
    source /etc/bash_completion
fi

if [ -f "/usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" ]; then
    source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash
fi

if [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
    source "/opt/ros/${ROS_DISTRO}/setup.bash"
    if [ ! -f "${HOME}/work/install/local_setup.bash" ]; then
        echo "sourced /opt/ros/${ROS_DISTRO}/setup.bash"
    fi
fi

if [ -f "${HOME}/work/install/local_setup.bash" ]; then
    source "${HOME}/work/install/local_setup.bash"
    echo "sourced ${HOME}/work/install/local_setup.bash"
fi
EOF

chown "${1}":"${2}" /home/"${1}"/.bashrc
