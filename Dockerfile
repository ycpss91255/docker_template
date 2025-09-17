FROM osrf/ros:humble-desktop-full-jammy
############################## SYSTEM PARAMETERS ##############################
# Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID="${UID}"
ARG SHELL=/bin/bash
# TODO: use Hardware parameter
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypoint.sh

# Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
# ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

# Setup users and groups
RUN groupadd --gid "${GID}" "${GROUP}" && \
    useradd --gid "${GID}" --uid "${UID}" -ms "${SHELL}" "${USER}" && \
    mkdir -p /etc/sudoers.d && \
    echo "${USER}:x:${UID}:${UID}:${USER},,,:/home/${USER}:${SHELL}" >> /etc/passwd && \
    echo "${USER}:x:${UID}:" >> /etc/group && \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}" && \
    chmod 0440 "/etc/sudoers.d/${USER}"

# Replace apt urls (Change to Taiwan)
RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

# Time zone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

############################### INSTALL #######################################
# Install packages
RUN apt update && \
    apt install -y --no-install-recommends \
        sudo \
        wget \
        curl \
        psmisc \
        # Shell
        tmux \
        terminator \
        # base tools
        python3-pip \
        python3-dev \
        python3-setuptools \
        # auto complete
        bash-completion \
        # python3-argcomplete \
        python3-colcon-argcomplete \
        ros-${ROS_DISTRO}-ros2cli \
        # * Work tools
        ros-${ROS_DISTRO}-laser-proc \
        ros-${ROS_DISTRO}-laser-filters \
        && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

############################## USER CONFIG ####################################
# opy custom configuration
COPY --chmod=0775 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0775 config config

# Switch user to ${USER}
USER ${USER}

RUN ./config/shell/bash_setup.sh "${USER}" "${GROUP}" && \
    ./config/shell/tmux/tmux_setup.sh "${USER}" "${GROUP}" && \
    ./config/pip/pip_setup.sh && \
    sudo rm -rf /config

# Switch workspace to ~/work
RUN sudo mkdir -p /home/"${USER}"/work
WORKDIR /home/"${USER}"/work

# Make SSH available
EXPOSE 22

ENTRYPOINT [ "/entrypoint.sh", "tmux" ]
# ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]
