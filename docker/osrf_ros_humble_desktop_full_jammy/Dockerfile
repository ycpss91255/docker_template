FROM osrf/ros:humble-desktop-full-jammy

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
ENV TZ=Asia/Taipei
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tzdata \
        locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone && \
    sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

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
        # auto complete
        bash-completion \
        python3-colcon-argcomplete \
        ros-${ROS_DISTRO}-ros2cli \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

############################## USER CONFIG ####################################
ARG ENTRYPOINT_FILE=entrypoint.sh
ARG CONFIG_DIR="/tmp/config"
ENV HOME="/home/${USER}"

COPY --chmod=0755 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0755 config "${CONFIG_DIR}"

# Switch user to ${USER}
USER ${USER}

# Setup shell, terminator, tmux, pip config
RUN cat ${CONFIG_DIR}/shell/bashrc >> "${HOME}/.bashrc" && \
    chown "${USER}":"${GROUP}" "${HOME}/.bashrc" && \
    ${CONFIG_DIR}/shell/terminator/terminator_setup.sh && \
    ${CONFIG_DIR}/shell/tmux/tmux_setup.sh && \
    ${CONFIG_DIR}/pip/pip_setup.sh && \
    sudo rm -rf "${CONFIG_DIR}"

# Switch workspace to ~/work
WORKDIR "${HOME}/work"

# * Make SSH available
EXPOSE 22

# ENTRYPOINT ["/entrypoint.sh", "terminator"]
# ENTRYPOINT ["/entrypoint.sh", "tmux"]
ENTRYPOINT ["/entrypoint.sh", "bash"]
# ENTRYPOINT ["/entrypoint.sh"]
