ARG IMAGE="osrf/ros:foxy-desktop-focal"

############################### system ###############################
FROM "${IMAGE}" AS sys

# User parameters
ARG USER="initial"
ARG GROUP="initial"
ARG UID="1000"
ARG GID="${UID}"
ARG SHELL="/bin/bash"
ARG HARDWARE="x86_64"
ENV HOME="/home/${USER}"

# Env vars for nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES="all"
ENV NVIDIA_DRIVER_CAPABILITIES="all"

# SHELL ["/bin/bash", "-c"]
# SHELL ["/bin/bash", "-xeu", "-c"]
SHELL ["/bin/bash", "-x", "-euo", "pipefail", "-c"]

# Setup users and groups
RUN if getent group "${GID}" >/dev/null; then \
        existing_grp="$(getent group "${GID}" | cut -d: -f1)"; \
        if [ "${existing_grp}" != "${GROUP}" ]; then \
            groupmod -n "${GROUP}" "${existing_grp}"; \
        fi; \
    else \
        groupadd -g "${GID}" "${USER}"; \
    fi; \
    \
    if getent passwd "${UID}" >/dev/null; then \
        existing_user="$(getent passwd "${UID}" | cut -d: -f1)"; \
        if [ "${existing_user}" != "${USER}" ]; then \
            usermod -l "${USER}" "${existing_user}"; \
        fi; \
        usermod -g "${GID}" -s "${SHELL}" -d "${HOME}" -m "${USER}"; \
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

RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && \
    echo "${TZ}" > /etc/timezone && \
    sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        tzdata \
        locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen "${LANG}" && \
    update-locale LANG="${LANG}"

############################### base ###############################
FROM sys AS base

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
        # auto complete
        bash-completion \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

############################### ros1 ###############################
FROM base AS ros1

ENV ROS_DISTRO=""

RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-noetic-desktop-full \
        # ros2 tools
        ros-foxy-ros1-bridge \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


############################### dev ###############################
FROM ros1 AS dev

ARG ENTRYPOINT_FILE="entrypoint.sh"
ARG CONFIG_DIR="/tmp/config"

COPY --chmod=0755 "./${ENTRYPOINT_FILE}" "/entrypoint.sh"
COPY --chown="${USER}":"${GROUP}" --chmod=0755 "config" "${CONFIG_DIR}"

# Switch USER
USER "${USER}"

# Run commands as USER
RUN "${CONFIG_DIR}"/pip/setup.sh

# Setup shell, terminator, tmux
RUN cat "${CONFIG_DIR}"/shell/bashrc >> "${HOME}/.bashrc" && \
    chown "${USER}":"${GROUP}" "${HOME}/.bashrc" && \
    "${CONFIG_DIR}"/shell/terminator/setup.sh && \
    "${CONFIG_DIR}"/shell/tmux/setup.sh && \
    sudo rm -rf "${CONFIG_DIR}"

# Switch workspace
WORKDIR "${HOME}/work"

# * Make SSH available
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
# CMD ["terminator"]
# CMD ["tmux"]
