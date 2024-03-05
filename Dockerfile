FROM nvidia/cuda:12.3.2-devel-ubuntu22.04
############################## SYSTEM PARAMETERS ##############################
# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID="${UID}"
ARG SHELL=/bin/bash
# TODO: use Hardware parameter
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh

# * Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all
# ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

# * Setup users and groups
RUN groupadd --gid "${GID}" "${GROUP}" \
    && useradd --gid "${GID}" --uid "${UID}" -ms "${SHELL}" "${USER}" \
    && mkdir -p /etc/sudoers.d \
    && echo "${USER}:x:${UID}:${UID}:${USER},,,:/home/${USER}:${SHELL}" >> /etc/passwd \
    && echo "${USER}:x:${UID}:" >> /etc/group \
    && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}" \
    && chmod 0440 "/etc/sudoers.d/${USER}"

# * Replace apt urls
# ? Change to tku
RUN sed -i 's@archive.ubuntu.com@ftp.tku.edu.tw@g' /etc/apt/sources.list
# ? Change to Taiwan
# RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

# * Time zone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

############################### INSTALL #######################################
# * Install packages
RUN apt update \
    && apt install -y --no-install-recommends \
        sudo \
        git \
        wget \
        curl \
        psmisc \
        vim \
        # * Shell
        tmux \
        # tmuxinator \
        terminator \
        # * base tools
        htop \
        python3-pip \
        python3-dev \
        python3-setuptools \
        # * coppeliasim dep
        libgl1-mesa-glx \
        libqt5gui5 \
        xz-utils \
        # * ros2
        software-properties-common \
        # * Work tools
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

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

# * Install coppeliasim
ARG COPPELIASIM_DIR="/home/${USER}/coppeliasim"

RUN mkdir -p "${COPPELIASIM_DIR}" \
    && tar Jvxf ./config/coppeliasim/*.tar.xz -C "${COPPELIASIM_DIR}" --strip-components=1

RUN ./config/pip/pip_setup.sh

# * Install ROS2 base
        # ros-humble-ros-base \
RUN add-apt-repository -y universe \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
    | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && apt update \
    && apt install -y --no-install-recommends \
        ros-humble-desktop \
        ros-dev-tools \
        python3-rosdep \
        python3-colcon-common-extensions \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
    && rosdep init \
    && sudo -u ${USER} bash -c "rosdep update"

############################## USER CONFIG ####################################
# * Switch user to ${USER}
USER ${USER}

# * ROS Arguments
ARG ROS_DISTRO=humble
# LOCALHOST or GLOBAL
ARG ROS_TYPE=LOCALHOST
# ? https://docs.ros.org/en/humble/Concepts/About-Domain-ID.html
# short 0~101
ARG ROS_ID=0

RUN ./config/shell/bash_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/terminator/terminator_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/tmux/tmux_setup.sh "${USER}" "${GROUP}" \
    && ./config/ros2/ros2_setup.sh "${ROS_DISTRO}" "${ROS_TYPE}" "${ROS_ID}" \
    && sudo rm -rf /config

# * Switch workspace to ~/work
RUN sudo mkdir -p /home/"${USER}"/work
WORKDIR /home/"${USER}"/work

# * Make SSH available
EXPOSE 22

# ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
ENTRYPOINT [ "/entrypoint.sh", "tmux" ]
# ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]
