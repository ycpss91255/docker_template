ARG ROS_DISTRO="humble"

ARG BUILD_TAG="base"
ARG RUNTIME_TAG="core"

ARG WS_PATH="/ros_ws"

############################## Builder ####################################
FROM ros:${ROS_DISTRO}-ros-${BUILD_TAG}-jammy AS builder

# Install base dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG WS_PATH
WORKDIR "${WS_PATH}"

# Pull main source code
RUN git clone --recursive https://github.com/Hokuyo-aut/urg_node2.git \
        ./src/urg_node2

# Install dependencies
RUN apt-get update && \
    rosdep install --from-paths src --ignore-src -r -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Build the workspace
RUN /ros_entrypoint.sh colcon build

############################## Runtime ####################################
FROM ros:${ROS_DISTRO}-ros-${RUNTIME_TAG}-jammy AS runtime

ARG USER="myuser"
ARG GROUP="myuser"
ARG UID="1000"
ARG GID="${UID}"
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

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-laser-proc \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER ${USER}

# Copy install from builder
ARG WS_PATH
COPY --from=builder --chown="${USER}":"${GROUP}" "${WS_PATH}/install" "${WS_PATH}/install"

# Copy local hokuyo configuration
ARG CONFIG_PATH="config"
COPY --chmod=0544 --chown="${USER}":"${GROUP}" "./${CONFIG_PATH}" "/ros_ws/install/urg_node2/share/urg_node2/config"

ARG ENTRYPOINT_FILE="entrypoint.sh"
COPY --chmod=0755 "./${ENTRYPOINT_FILE}" "/entrypoint.sh"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2", "launch", "urg_node2", "urg_node2.launch.py"]
