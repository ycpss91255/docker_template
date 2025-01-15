FROM nvidia/cuda:12.3.2-devel-ubuntu20.04
############################## SYSTEM PARAMETERS ##############################
# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID="${UID}"
ARG SHELL=/bin/bash
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh

# * ROS
ARG ROS_DISTRO=noetic
# localhost or global
ARG ROS_SCOPE=localhost
ARG ROS_MASTER_IP="127.0.0.1"
ARG ROS_SLAVE_IP="127.0.0.1"
# * Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all
# ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute
# * local config
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:UTF-8
ENV TZ=Asia/Taipei

# * Setup users and groups
RUN groupadd --gid "${GID}" "${GROUP}" && \
    useradd --gid "${GID}" --uid "${UID}" -ms "${SHELL}" "${USER}" && \
    mkdir -p /etc/sudoers.d && \
    echo "${USER}:x:${UID}:${UID}:${USER},,,:/home/${USER}:${SHELL}" >> /etc/passwd && \
    echo "${USER}:x:${UID}:" >> /etc/group && \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}" && \
    chmod 0440 "/etc/sudoers.d/${USER}"

# * Replace apt urls
# ? Change to tku
# RUN sed -i 's@archive.ubuntu.com@ftp.tku.edu.tw@g' /etc/apt/sources.list
# ? Change to Taiwan
RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

# * Set timezone
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone
############################### INSTALL #######################################
# * Install packages
RUN apt update && \
    apt install -y --no-install-recommends \
        curl \
        git \
        htop \
        less \
        locales \
        locales-all \
        lsb-release \
        psmisc \
        sudo \
        tree \
        vim \
        wget \
        # * Shell
        terminator \
        tmux \
        tmuxp \
        # * base tools
        build-essential \
        python3-dev \
        python3-pip \
        python3-setuptools \
        # * Work tools
        && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# * Install ROS
COPY --chown="${USER}":"${GROUP}" --chmod=0775 config/ros .ros

RUN echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add - && \
    apt update && \
    apt install -y --no-install-recommends \
        ros-noetic-desktop-full \
        python3-catkin-tools \
        python3-rosdep \
        python3-rosinstall \
        python3-rosinstall-generator \
        python3-wstool \
        python3-tk \
        liburdfdom-tools \
        && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    rosdep init && \
    sudo -u ${USER} bash -c "rosdep update" && \
    ./.ros/ros_setup.sh "${ROS_DISTRO}" "${ROS_SCOPE}" "${ROS_MASTER_IP}" "${ROS_SLAVE_IP}" && \
    rm -rf .ros

############################## USER CONFIG ####################################
# * Copy custom configuration
COPY --chmod=0775 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0775 config config

# * Switch user to ${USER}
USER ${USER}

RUN ./config/pip/pip_setup.sh && \
    ./config/shell/bash_setup.sh "${USER}" "${GROUP}" && \
    ./config/shell/terminator/terminator_setup.sh "${USER}" "${GROUP}" && \
    ./config/shell/tmux/tmux_setup.sh "${USER}" "${GROUP}" && \
    sudo rm -rf /config

# * Switch workspace to ~/work
RUN sudo mkdir -p /home/"${USER}"/work
WORKDIR /home/"${USER}"/work

# * Make SSH available
# EXPOSE 22

# ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]
