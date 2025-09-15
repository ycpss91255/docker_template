FROM ubuntu:22.04
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
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
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
# RUN sed -i 's@archive.ubuntu.com@ftp.tku.edu.tw@g' /etc/apt/sources.list
# ? Change to Taiwan
RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

# * Time zone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

# * local config
# NOTE: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
# RUN apt update && \
#     apt inatall -y --no-install-recommends \
#         locales && \
#     locale-gen en_US.UTF-8 && \
#     update-locale LANG=en_US.UTF-8
# ENV LC_ALL en_US.UTF-8
# ENV LANG en_US.UTF-8
# ENV LANGUAGE en_US:UTF-8

############################### INSTALL #######################################
# * Install packages
RUN apt update && \
    apt install -y --no-install-recommends \
        sudo \
        git \
        htop \
        wget \
        curl \
        psmisc \
        vim \
        htop \
        tree \
        # * Shell
        tmux \
        terminator \
        # * base tools
        python3-pip \
        python3-dev \
        python3-setuptools \
        # * Work tools
        && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# gnome-terminal libcanberra-gtk-module libcanberra-gtk3-module \
# dbus-x11 libglvnd0 libgl1 libglx0 libegl1 libxext6 libx11-6 \
# display dep
# libnss3 libgbm1 libxshmfence1 libdrm2 libx11-xcb1 libxcb-*-dev


############################## USER CONFIG ####################################
# * Copy custom configuration
# ? Requires docker version >= 17.09
COPY --chmod=0775 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0775 config config

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
ENTRYPOINT [ "/entrypoint.sh", "tmux" ]
# ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]
