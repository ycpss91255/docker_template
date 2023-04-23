FROM ubuntu:22.04
############################## SYSTEM PARAMETERS ##############################
# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID=${UID}
ARG SHELL=/bin/bash
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh

# * Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all
# ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

# * Setup users and groups
RUN groupadd --gid ${GID} ${GROUP} \
    && useradd --gid ${GID} --uid ${UID} -ms ${SHELL} ${USER} \
    && mkdir -p /etc/sudoers.d \
    && echo "${USER}:x:${UID}:${UID}:${USER},,,:$HOME:${shell}" >> /etc/passwd \
    && echo "${USER}:x:${UID}:" >> /etc/group \
    && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}" \
    && chmod 0440 "/etc/sudoers.d/${USER}"

# * Replace apt urls
# ? Change to tku
RUN sed -i 's@archive.ubuntu.com@ftp.tku.edu.tw@g' /etc/apt/sources.list
# ? Change to Taiwan
# RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

# Time zone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

############################### INSTALL #######################################
# * Install packages
RUN apt update \
    && apt install -y --no-install-recommends \
        sudo \
        git \
        htop \
        wget \
        curl \
        psmisc \
        # * Shell
        byobu \
        terminator \
        # * base tools
        python3-pip \
        python3-dev \
        python3-setuptools \
        # * Work tools
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# gnome-terminal libcanberra-gtk-module libcanberra-gtk3-module \
# dbus-x11 libglvnd0 libgl1 libglx0 libegl1 libxext6 libx11-6 \

############################### INSTALL #######################################
# * Switch workspace to /home/${USER}/.tmp
WORKDIR /home/${USER}/.tmp

# * Copy custom configuration
COPY config .

RUN bash ./script/shell_setup.sh "bash" \
    && bash ./script/pip_setup.sh \
    && rm -rf /home/${USER}/.tmp

# * Copy entrypoint
COPY --chmod=0775 ./${ENTRYPOINT_FILE} /entrypoint.sh

# * Switch workspace to /home/${USER}
WORKDIR /home/${USER}

# * Switch user to ${USER}
USER ${USER}
RUN sudo mkdir work

# * Make SSH available
EXPOSE 22

# * Switch workspace to ~/work
WORKDIR /home/${USER}/work

# ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
# ENTRYPOINT [ "/entrypoint.sh", "byobu" ]
ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]
