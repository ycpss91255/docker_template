#!/usr/bin/env bash

# ${1}: LIKE_SHELL

##### bash config #####
# add Hello Docker to bash config
echo "echo 'Hello Docker!'" >> /home/"${USER}"/.bashrc

# add common bash aliase to bash config
echo -e "alias eb='vim ~/.bashrc'\n\
alias sb='source ~/.bashrc && echo \"You source user config!\"'\n\
alias wb='source ~/work/devel/setup.bash && echo \"You source workspace config!\"'\n" >>/home/"${USER}"/.bashrc

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
unset color_prompt force_color_prompt" >>/home/${USER}/.bashrc

chown ${USER}:${GROUP} /home/${USER}/.bashrc

##### byobu #####
mkdir -p /home/${USER}/.byobu &&
    chown -R ${USER}:${GROUP} /home/${USER}/.byobu

echo -e "set -g default-shell /bin/${1}\n\
set -g default-command /bin/${1}" >/home/${USER}/.byobu/.tmux.conf
echo "unbind-key -n C-a" >>/home/${USER}/.byobu/keybindings.tmux

##### terminator #####
mkdir -p /home/${USER}/.config/
cp -r ./shell/terminator /home/${USER}/.config/
chown -R ${USER}:${GROUP} /home/${USER}/.config
