#!/usr/bin/env bash

# Get dependent parameters
FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "${FILE_PATH}/get_param.sh"

# Build stage name
# build_stage="base"
# build_stage="sys"
# build_stage="dev"
# build_stage="runtime"

# Build docker images
docker build -t "${docker_hub_user}"/"${image}" \
    --build-arg USER="${user}" \
    --build-arg GROUP="${group}" \
    --build-arg UID="${uid}" \
    --build-arg GID="${gid}" \
    --build-arg HARDWARE="${hardware}" \
    --build-arg ENTRYPOINT_FILE="${entrypoint_file}" \
    -f "${FILE_PATH}"/"${dockerfile_name}" "${FILE_PATH}"

#     --target="${build_stage}" \
#     --progress=plain \
#     --no-cache \
