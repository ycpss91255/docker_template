#!/usr/bin/env bash

# Get dependent parameters
FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "${FILE_PATH}/get_param.sh"

# Build docker images

# shellcheck disable=SC2154
docker build -t "${docker_hub_user}"/"${image}" \
    --build-arg USER="${user}" \
    --build-arg GROUP="${group}" \
    --build-arg UID="${uid}" \
    --build-arg GID="${gid}" \
    --build-arg HARDWARE="${hardware}" \
    --build-arg ENTRYPOINT_FILE="${entrypoint_file}" \
    -f "${FILE_PATH}"/"${dockerfile_name}" "${FILE_PATH}"

#     --progress=plain \
#     --no-cache \
