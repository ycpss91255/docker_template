FROM stereolabs/zed:5.0-devel-cuda12.8-ubuntu22.04

############################## SYSTEM PARAMETERS ##############################
ARG USER="initial"
ARG GROUP="initial"
ARG UID="1000"
ARG GID="${UID}"
ARG SHELL=/bin/bash
# NOTE: not used
ARG HARDWARE=x86_64

# Env vars for nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# SHELL ["/bin/bash", "-c"]
SHELL ["/bin/bash", "-eux" , "-c"]

# Setup users and groups
RUN if getent group "${GID}" >/dev/null; then \
        existing_grp="$(getent group "${GID}" | cut -d: -f1)"; \
        if [ "${existing_grp}" != "${GROUP}" ]; then \
            groupmod -n "${GROUP}" "${existing_grp}"; \
        fi; \
    elif getent group "${USER}" >/dev/null; then \
        groupmod -g "${GID}" "${USER}"; \
    else \
        groupadd -g "${GID}" "${USER}"; \
    fi; \
    \
    useradd --gid "${GID}" --uid "${UID}" -ms "${SHELL}" "${USER}" && \
    \
    if getent passwd "${UID}" >/dev/null; then \
        existing_user="$(getent passwd "${UID}" | cut -d: -f1)"; \
        if [ "${existing_user}" != "${USER}" ]; then \
            usermod -l "${USER}" "${existing_user}"; \
        fi; \
        usermod -g "${GID}" -s "${SHELL}" -d "/home/${USER}" -m  "${USER}"; \
    elif id -u "${USER}" >/dev/null 2>&1; then \
        usermod -u "${UID}" -g "${GID}" -s "${SHELL}" -d "/home/${USER}" -m "${USER}"; \
    else \
        useradd -u "${UID}" -g "${GID}" -s "${SHELL}" -m "${USER}"; \
    fi; \
    \
    mkdir -p /etc/sudoers.d; \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}"; \
    chmod 0440 "/etc/sudoers.d/${USER}"

# Setup locale ,timezone and Replace apt urls (Change to Taiwan)
ENV TZ="Asia/Taipei"
ENV LC_ALL="en_US.UTF-8"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"

RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        tzdata \
        locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen "${LANG}" && \
    update-locale LANG="${LANG}" && \
    ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

############################### INSTALL #######################################
# Install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        psmisc \
        htop \
        # Shell
        tmux \
        terminator \
        # base tools
        ca-certificates \
        software-properties-common \
        wget \
        curl \
        git \
        vim \
        tree \
        # python3 tools
        python3-pip \
        python3-dev \
        python3-setuptools \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install ROS2 ${ROS_DISTRO}
ENV ROS_DISTRO=humble

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        software-properties-common \
        curl \
        && \
    add-apt-repository -y universe && \
    ROS_APT_SOURCE_VERSION=$( \
        curl -fsSL --retry 3 \
            "https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest" \
        | grep -F "tag_name" \
        | cut -d '"' -f4 \
    ); \
    curl -fsSL --retry 3 -o /tmp/ros2-apt-source.deb \
        "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb" && \
    dpkg -i /tmp/ros2-apt-source.deb && \
    rm /tmp/ros2-apt-source.deb && \
    apt-get update && \
    # install ROS2 packages
    apt-get install -y --no-install-recommends \
        ros-dev-tools \
        ros-${ROS_DISTRO}-desktop \
        # auto complete
        bash-completion \
        python3-colcon-argcomplete \
        ros-${ROS_DISTRO}-ros2cli \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Realsense, Hokuyo, Sick, ZED dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Realsense2
        ros-${ROS_DISTRO}-librealsense2* \
        ros-${ROS_DISTRO}-realsense2* \
        # Hokuyo
        ros-${ROS_DISTRO}-laser-proc \
        ros-${ROS_DISTRO}-laser-filters \
        # sick nanoscan3
        ros-${ROS_DISTRO}-sick-safetyscanners2-interfaces \
        ros-${ROS_DISTRO}-sick-safetyscanners-base \
        # zed_ros2_wrapper dependencies
        ros-${ROS_DISTRO}-zed-msgs \
        ros-${ROS_DISTRO}-nmea-msgs \
        ros-${ROS_DISTRO}-geographic-msgs \
        ros-${ROS_DISTRO}-diagnostic-updater \
        ros-${ROS_DISTRO}-robot-localization \
        ros-${ROS_DISTRO}-image-transport-plugins \
        ros-${ROS_DISTRO}-compressed-image-transport \
        ros-${ROS_DISTRO}-compressed-depth-image-transport \
        ros-${ROS_DISTRO}-theora-image-transport \
        ros-${ROS_DISTRO}-point-cloud-transport-plugins \
        ros-${ROS_DISTRO}-draco-point-cloud-transport \
        ros-${ROS_DISTRO}-zlib-point-cloud-transport \
        ros-${ROS_DISTRO}-zstd-point-cloud-transport \
        ros-${ROS_DISTRO}-backward-ros \
        ros-${ROS_DISTRO}-xacro \
        ros-${ROS_DISTRO}-ffmpeg-image-transport \
        ros-${ROS_DISTRO}-ffmpeg-encoder-decoder \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # fix permission for python packages
    chown -R root:root /usr/local/lib/python3.*/dist-packages && \
    find /usr/local/lib/python3.*/dist-packages -type d -exec chmod a+rx {} \; && \
    find /usr/local/lib/python3.*/dist-packages -type f -exec chmod a+r  {} \; && \
    chmod 644 /usr/local/lib/python3.*/dist-packages/cython.py 2>/dev/null || true

############################## USER CONFIG ####################################
ARG ENTRYPOINT_FILE=entrypoint.sh
ARG CONFIG_DIR="/tmp/config"
ENV HOME="/home/${USER}"

COPY --chmod=0755 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0755 config "${CONFIG_DIR}"

# Switch user to ${USER}
USER ${USER}

# rosdep init and realsense udev rules
RUN sudo rosdep init && \
    rosdep update && \
    # install pip requirements
    ${CONFIG_DIR}/pip/pip_setup.sh && \
    sudo pip uninstall -y numpy && \
    # realsense udev rules
    sudo cp ${CONFIG_DIR}/realsense/99-realsense-libusb.rules /etc/udev/rules.d/99-realsense-libusb.rules

# Setup shell, terminator, tmux
RUN cat ${CONFIG_DIR}/shell/bashrc >> "${HOME}/.bashrc" && \
    chown "${USER}":"${GROUP}" "${HOME}/.bashrc" && \
    ${CONFIG_DIR}/shell/terminator/terminator_setup.sh && \
    ${CONFIG_DIR}/shell/tmux/tmux_setup.sh && \
    sudo rm -rf "${CONFIG_DIR}"

# Switch workspace to ~/work
WORKDIR "${HOME}/work"

# * Make SSH available
EXPOSE 22

# ENTRYPOINT ["/entrypoint.sh", "terminator"]
# ENTRYPOINT ["/entrypoint.sh", "tmux"]
ENTRYPOINT ["/entrypoint.sh", "bash"]
# ENTRYPOINT ["/entrypoint.sh"]
