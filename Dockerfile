ARG ROS_DISTRO="humble"
ARG BUILD_TAG="base"
ARG RUNTIME_TAG="base"
ARG UBUNTU_CODENAME="jammy"

############################## system ##############################
FROM ros:${ROS_DISTRO}-ros-${BUILD_TAG}-${UBUNTU_CODENAME} AS sys

# librealsense dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        udev \
        libudev-dev \
        libusb-1.0-0-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Build and install librealsense
RUN git clone --depth 1 -b "v2.56.4" https://github.com/realsenseai/librealsense /tmp/librealsense && \
    mkdir -p /tmp/librealsense/build && \
    cd /tmp/librealsense/build && \
    cmake /tmp/librealsense \
        -DFORCE_RSUSB_BACKEND=ON \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_GRAPHICAL_EXAMPLES=OFF \
        -DBUILD_WITHOUT_SYSTEM_LIBUSB=OFF && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    rm -rf /tmp/librealsense

# realsense2-ros dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-tqdm \
        python3-requests \
        ros-${ROS_DISTRO}-tf2-ros \
        ros-${ROS_DISTRO}-cv-bridge \
        ros-${ROS_DISTRO}-xacro \
        ros-${ROS_DISTRO}-launch-pytest \
        ros-${ROS_DISTRO}-image-transport \
        ros-${ROS_DISTRO}-diagnostic-updater \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG WORKDIR="/ros_ws"
WORKDIR ${WORKDIR}

# Build and install realsense2-ros
RUN git clone --depth 1 -b "4.56.4" https://github.com/realsenseai/realsense-ros.git "${WORKDIR}"/src/realsense-ros && \
    /ros_entrypoint.sh colcon build


ARG REALSENSE_RULE="99-realsense-libusb.rules"
COPY ./config/${REALSENSE_RULE} "/etc/udev/rules.d/${REALSENSE_RULE}"

############################## USER CONFIG ####################################
ARG USER="initial"
ARG GROUP="initial"
ARG UID="1000"
ARG GID="${UID}"
ARG HARDWARE="x86_64"
ARG SHELL="/bin/bash"
ENV HOME="/home/${USER}"

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

USER ${USER}

ARG ENTRYPOINT_FILE="entrypoint.sh"
COPY --chmod=0755 "./${ENTRYPOINT_FILE}" "/entrypoint.sh"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2", "launch", "realsense2_camera", "rs_align_depth_launch.py"]

