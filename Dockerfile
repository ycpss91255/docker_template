FROM nvidia/cuda:12.3.2-devel-ubuntu22.04
############################## SYSTEM PARAMETERS ##############################
# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID="${UID}"
ARG SHELL=/bin/bash
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh

# * Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all
# ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

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
RUN sed -i 's@archive.ubuntu.com@ftp.tku.edu.tw@g' /etc/apt/sources.list
# ? Change to Taiwan
# RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

# * Time zone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

# * local config
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:UTF-8

############################### INSTALL #######################################
# * Install packages

RUN apt update && \
    apt install -y --no-install-recommends \
        sudo \
        locales \
        locales-all \
        git \
        wget \
        curl \
        psmisc \
        vim \
        tree \
        # * Shell
        tmux \
        # tmuxinator \
        terminator \
        # * base tools
        htop \
        python3-pip \
        python3-dev \
        python3-setuptools \
        build-essential \
        # # * coppeliasim dep
        # xsltproc \
        # libgl1-mesa-glx \
        # libqt5gui5 \
        # xz-utils \
        # * ros2
        software-properties-common \
        # dev tools
        libgtest-dev \
        # * run tools
        libserial-dev \
        libspdlog-dev \
        && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# # * Install coppeliasim
# ARG COPPELIASIM_DIR="/home/${USER}/coppeliasim"
# # * Copy custom configuration
# COPY --chown="${USER}":"${GROUP}" --chmod=0775 config/coppeliasim .coppeliasim
# RUN mkdir -p "${COPPELIASIM_DIR}" && \
#     chown "${USER}":"${GROUP}" "${COPPELIASIM_DIR}" && \
#     tar Jvxf .coppeliasim/*.tar.xz -C "${COPPELIASIM_DIR}" --strip-components=1 && \
#     ./.coppeliasim/coppeliasim_setup.sh "${USER}" "${GROUP}" && \
#     rm -rf .coppeliasim

# * ROS Arguments
ARG ROS_DISTRO=humble
# LOCALHOST or GLOBAL
ARG ROS_TYPE=LOCALHOST
# ? https://docs.ros.org/en/humble/Concepts/About-Domain-ID.html
# short 0~101 (turtlebot3 => 30)
ARG ROS_ID=30
# turtlebot3 
ENV LDS_MODEL=LDS_01
ENV TURTLEBOT3_MODEL=burger
ENV OPENCR_MODEL="${TURTLEBOT3_MODEL}"
ENV OPENCR_PORT=/dev/opencr

COPY --chown="${USER}":"${GROUP}" --chmod=0775 config/ros2 .ros2

ARG OPENCR_ARCH="i386"
# * Install ROS2 base
RUN if [ "${HARDWARE}" == "x86_64" ]; then \
        OPENCR_ARCH="i386"; \
    elif [ "${HARDWARE}" == "arrch64" ]; then \
        OPENCR_ARCH="armhf"; \
    fi && \
    dpkg --add-architecture "${OPENCR_ARCH}" && \
    add-apt-repository -y universe && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && \
    echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
    apt update && \
    apt install -y --no-install-recommends \
        # base tools
        ros-humble-desktop \
        ros-dev-tools \
        python3-rosdep \
        python3-colcon-common-extensions \
        python3-colcon-argcomplete \
        python3-colcon-clean \
        ros-humble-std-msgs \
        # coppeliasim and gazebo dep
        ros-humble-gazebo-msgs \
        # gazebo-classic
        ros-humble-gazebo-ros-pkgs \
        # turtlebot3 ros2 dep
        ros-humble-cartographer \
        ros-humble-cartographer-ros \
        ros-humble-navigation2 \
        ros-humble-nav2-bringup \
        # turtlebot3
        libboost-system-dev \
        python3-argcomplete \
        ros-humble-dynamixel-sdk \
        ros-humble-turtlebot3-msgs \
        ros-humble-turtlebot3 \
        ros-humble-turtlebot3-simulations \
        ros-humble-turtlebot3-gazebo \
        ros-humble-hls-lfcd-lds-driver \
        libudev-dev \
        libc6:"${OPENCR_ARCH}" \
        && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    rosdep init && \
    sudo -u ${USER} bash -c "rosdep update" && \
    ./.ros2/ros2_setup.sh "${ROS_DISTRO}" "${ROS_TYPE}" "${ROS_ID}" && \
    rm -rf ./.ros2

############################## USER CONFIG ####################################
# * Copy custom configuration
# ? Requires docker version >= 17.09
COPY --chmod=0775 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0775 config config
# ? docker version < 17.09
# COPY ./${ENTRYPOINT_FILE} /entrypoint.sh
# COPY config config
# RUN sudo chmod 0775 /entrypoint.sh && \
    # sudo chown -R "${USER}":"${GROUP}" config \
    # && sudo chmod -R 0775 config

# * Switch user to ${USER}
USER ${USER}

RUN ./config/shell/bash_setup.sh "${USER}" "${GROUP}" && \
    ./config/shell/terminator/terminator_setup.sh "${USER}" "${GROUP}" && \
    ./config/shell/tmux/tmux_setup.sh "${USER}" "${GROUP}" && \
    ./config/pip/pip_setup.sh && \
    sudo rm -rf /config

# * Switch workspace to ~/work
RUN sudo mkdir -p /home/"${USER}"/work
WORKDIR /home/"${USER}"/work

# * Make SSH available
EXPOSE 22

# ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
# ENTRYPOINT [ "/entrypoint.sh", "tmux" ]
ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]
