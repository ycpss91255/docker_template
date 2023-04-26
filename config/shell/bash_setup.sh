#!/usr/bin/env bash

# ${1}: USER
# ${2}: GROUP

{
    # add Hello Docker to bash config
    echo "echo 'Hello Docker!'"

    # add common bash aliase to bash config
    echo -e "alias eb='vim ~/.bashrc'\n\
    alias sb='source ~/.bashrc && echo \"You source user config!\"'\n\
    alias wb='source ~/work/devel/setup.bash && echo \"You source workspace config!\"'\n"

    # add color and git branch to bash config
    echo -e "force_color_prompt=yes\n\
    color_prompt=yes\n\
    parse_git_branch() {\n\
        git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'\n\
    }\n\
    if [ \"\$color_prompt\" = yes ]; then\n\
        PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]\$(parse_git_branch)\[\033[00m\]\$ '\n\
    else\n\
        PS1='\${debian_chroot:+(\$debian_chroot)}\u@\h:\w\$(parse_git_branch)\$ '\n\
    fi\n\
    unset color_prompt force_color_prompt"
} >> /home/"${1}"/.bashrc

chown "${1}":"${2}" /home/"${1}"/.bashrc
