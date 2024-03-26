#!/usr/bin/env bash

# Get dependent parameters
source "$(dirname "$(readlink -f "${0}")")/get_param.sh"

# TODO: add option get user parameters from command line

# del old data
docker system prune -f
# Build docker images
docker build -t "${DOCKER_HUB_USER}"/"${IMAGE}" \
	--build-arg USER="${user}" \
	--build-arg UID="${uid}" \
	--build-arg GROUP="${group}" \
	--build-arg GID="${gid}" \
	--build-arg HARDWARE="${hardware}" \
	--build-arg ENTRYPOINT_FILE="${ENTRYPOINT_FILE}" \
	-f "${FILE_DIR}"/"${DOCKERFILE_NAME}" "${FILE_DIR}"

#     --progress=plain \
#     --no-cache \
