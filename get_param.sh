#!/usr/bin/env bash

# Function to set the Docker image name based on the directory path
#
# Parameters:
#    ${1}: the directory path to search for the Dockerfile
#
# Returns:
#    IMAGE: The name of the Docker image to be used
#
# This function first checks if the `docker` folder has a suffix, such as `docker_xxx`, and extracts the suffix
# and store it in the `IMAGE` variable. If the `docker` folder has no suffix, it checks if the workspace folder
# has a prefix, such as `xxx_ws`, and extracts the prefix and store it in the `IMAGE` variable. If the workspace
# folder has no prefix/suffix, the image name is set to `unknown`. The function then returns the image name.
#
# If no Dockerfile is found in the directory, the function will not work correctly and will return an incorrect
# image name.
#
function set_image_name() {
    # Check if the `docker` folder has a suffix, such as `docker_xxx`
    # If yes, extract the suffix and store it in the `IMAGE` variable
    IMAGE=$(echo "${1}" | awk -F/ '{
            for (i=NF; i>0; i--) {
                if ($i ~ /^docker_/) {
                    sub(/^docker_/,"",$i);
                    print $i;
                    exit;
                }
            }
        }')

    # If the `docker` folder has no suffix, check if the workspace folder has a prefix, such as `xxx_ws`
    # If yes, extract the prefix and store it in the `IMAGE` variable, and update the `WS_PATH` variable accordingly
    if [[ -z "${IMAGE}" ]]; then
        IMAGE=$(echo "${1}" | awk -F/ '{
                for (i=NF; i>0; i--) {
                    if ($i ~ /_ws$/) {
                        sub(/_ws$/,"",$i);
                        print $i;
                        exit;
                    }
                }
            }')
    fi

    # If the workspace folder has no prefix/suffix, set the image name to `unknown`
    # and the workspace path to the current directory
    IMAGE=${IMAGE:-unknown}

    # Print out the values of IMAGE
    printf "%s" "${IMAGE}"
}

# Function to extract the path of the workspace folder
# and store it in the `WS_PATH` variable
#
# Parameters:
#    ${1}: the directory path to extract the workspace folder from
#
# Returns:
#    WS_PATH: the path to the workspace folder
#
# If a workspace folder with the given prefix is found,
# its path is stored in the `WS_PATH` variable.
# Otherwise, the `WS_PATH` variable is set to the parent directory
# of the given directory path.
#
function get_workdir() {
    WS_NAME=$(echo "${1}" | awk -F/ '{
            for (i=NF; i>0; i--) {
                if ($i ~ /_ws$/) {
                    print $i;
                    exit;
                }
            }
        }')

    if [[ -n "${WS_NAME}" ]]; then
        # Extract the path of the workspace folder and store it in the `WS_PATH` variable
        WS_PATH=$(echo "${1}" | awk -v ws="${WS_NAME}" -v found=0 -F/ '{
                for (i=1; i<=NF; i++) {
                    if ($i ~ /_ws$/){
                        found=1;
                        break;
                    }
                    printf "%s/", $i
                }
                if (found) printf "%s", ws
            }')
    else
        # If no workspace folder is found based on the provided prefix, extract the path to the parent directory
        WS_PATH=$(echo "${1}" | rev | cut -d '/' -f 2- | rev)
    fi

    # Print out the values of WS_PATH
    printf "%s" "${WS_PATH}"
}

# Function to check if GraphicsCard is NVIDIA and nvidia-docker2 or nvidia-container-runtime is installed
#
# Parameters:
#    None
#
# Returns:
#    GPU_FLAG: if NVIDIA graphics card and nvidia-docker2 or nvidia-container-runtime is installed, empty string otherwise
#
function check_nvidia() {
    if (lspci | grep -q VGA ||
        lspci | grep -iq NVIDIA ||
        lsmod | grep -q nvidia ||
        nvidia-smi -L | grep -iq nvidia) &&
        (command -v nvidia-smi >/dev/null 2>&1 ||
            command -v nvidia-docker >/dev/null 2>&1 ||
            dpkg -l | grep -q nvidia-container-toolkit); then
        GPU_FLAG="--gpus all"
    else
        GPU_FLAG=""
    fi

    # Print out the values of GPU_FLAG
    printf "%s" "${GPU_FLAG}"
}

# Function to get system parameter, including user, group, UID, GID, hardware architecture
#
# Parameters:
#    None
#
# Returns:
#    user: the user of the current Docker environment or the user of the current system
#    group: the group of the current user
#    uid: the UID of the current user
#    gid: the GID of the current user
#    hardware: the hardware architecture of the current system
#
function get_system_info() {
    # Try to retrieve the current user from Docker using the `docker info` command and store it in the `user` variable
    # If that fails, fall back to using the `id` command to get the current user
    docker_info_name=$(docker info 2>/dev/null | grep Username | cut -d ' ' -f 3)
    if [[ -z "${docker_info_name}" ]]; then
        user=$(id -un)
        group=$(id -gn)
    else
        user=${docker_info_name}
        group=${docker_info_name}
    fi
    # user=$(docker info 2>/dev/null | grep Username | cut -d ' ' -f 3 || id -un)

    # Retrieve the group of the current user using the `id` command and store it in the `group` variable
    # group=$(docker info 2>/dev/null | grep Username | cut -d ' ' -f 3 || id -gn)

    # Retrieve the UID of the current user using the `id` command and store it in the `uid` variable
    uid=$(id -u)

    # Retrieve the GID of the current user using the `id` command and store it in the `gid` variable
    gid=$(id -g)

    # Retrieve the hardware architecture of the current system using the `uname` command and store it in the `hardware` variable
    hardware=$(uname -m)

    # Print out the values of user, group, uid, gid and hardware
    printf "%s %s %d %d %s" "${user}" "${group}" "${uid}" "${gid}" "${hardware}"
}

# This function sets the Dockerfile name based on the directory path and hardware architecture
#
# Parameters:
#    ${1}: the directory path to search for the Dockerfile
#    ${2}: the hardware architecture
#
# Returns:
#    DOCKERFILE_NAME: The name of the Dockerfile to be used
#
# If no Dockerfile is found in the directory, an error message is displayed and the script exits.
# If only one Dockerfile is found, it is returned.
# If a Dockerfile with the architecture suffix is found, it is returned.
# Otherwise, the default Dockerfile is returned.
#
function set_dockerfile() {
    file_list=($(ls ${1} | grep Dockerfile))

    # Check if there is no Dockerfile file
    if [[ ${#file_list[@]} == 0 ]]; then
        echo "Not found Dockerfile file"
        exit 1
    # Check if  there is only only one Dockerfile file
    elif [[ ${#file_list[@]} == 1 ]]; then
        DOCKERFILE_NAME="${file_list[0]}"
    # Check if there is a Dockerfile_xxx file
    elif [[ -e "${1}/Dockerfile_${2}" ]]; then
        DOCKERFILE_NAME="Dockerfile_${2}"
    # Use the default Dockerfile file
    elif [[ -e "${1}/Dockerfile" ]]; then
        DOCKERFILE_NAME="Dockerfile"
    # If none of the above conditions are true, print an error message and exit
    else
        echo "Unknown Dockerfile file name"
        exit 1
    fi

    # Print out the values of DOCKERFILE_NAME
    printf "%s" "${DOCKERFILE_NAME}"
}


# This function sets the entrypoint.sh name based on the directory path and hardware architecture
#
# Parameters:
#    ${1}: the directory path to search for the entrypoint.sh
#    ${2}: the hardware architecture
#
# Returns:
#    ENTRYPOINT_FILE: The name of the entrypoint.sh to be used
#
# If no entrypoint.sh is found in the directory, an error message is displayed and the script exits.
# If only one entrypoint.sh is found, it is returned.
# If a entrypoint.sh with the architecture suffix is found, it is returned.
# Otherwise, the default entrypoint.sh is returned.
#
function set_entrypoint() {
    file_list=($(ls ${1} | grep entrypoint))

    # Check if there is no entrypoint file
    if [[ ${#file_list[@]} == 0 ]]; then
        echo "Not found entrypoint file"
        exit 1
    # Check if  there is only only one entrypoint file
    elif [[ ${#file_list[@]} == 1 ]]; then
        ENTRYPOINT_FILE="${file_list[0]}"
    # Check if there is a entrypoint_xxx file
    elif [[ -e "${1}/entrypoint_${2}.sh" ]]; then
        ENTRYPOINT_FILE="entrypoint_${2}.sh"
    # Use the default entrypoint file
    elif [[ -e "${1}/entrypoint.sh" ]]; then
        ENTRYPOINT_FILE="entrypoint.sh"
    # If none of the above conditions are true, print an error message and exit
    else
        echo "Unknown entrypoint file name"
        exit 1
    fi

    # Print out the values of ENTRYPOINT_FILE
    printf "%s" "${ENTRYPOINT_FILE}"
}
################################ MAIN ##########################################
# Analyze the user input parameters to make thecorresponding action
ARGS=$(getopt \
    -o h \
    --long debug,help \
    -- "$@")
eval set -- "${ARGS}"

while true; do
    case "$1" in
    --debug)
        DEBUG=true
        shift
        ;;
    -h | --help)
        echo "Usage: ${0} [OPTION]"
        echo " Options:"
        echo "     --debug    Enable debug mode"
        echo " -h, --help     Show this help massage and exit"
        exit 0
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Unknown option: ${1}"
        exit 1
        ;;
    esac
done

# $DEBUG && set -x

# TODO: wait check
# Start sharing xhost
# xhost +local:root

FILE_DIR=$(dirname $(readlink -f $0))

read -r GPU_FLAG <<<"$(check_nvidia)"
read -r user group uid gid hardware <<<"$(get_system_info)"
read -r IMAGE <<<"$(set_image_name "${FILE_DIR}")"
read -r WS_PATH <<<"$(get_workdir "${FILE_DIR}" "${IMAGE}")"
read -r DOCKERFILE_NAME <<<"$(set_dockerfile "${FILE_DIR}" "${hardware}")"
read -r ENTRYPOINT_FILE <<<"$(set_entrypoint "${FILE_DIR}" "${hardware}")"

# Set the container name to be the same as the image name
CONTAINER=${IMAGE}

if [ "$DEBUG" = true ]; then
    echo -e "GPU_FLAG=${GPU_FLAG}\n"

    echo "user=${user}"
    echo "group=${group}"
    echo "uid=${uid}"
    echo "gid=${gid}"
    echo -e "hardware=${hardware}\n"

    echo "FILE_DIR=${FILE_DIR}"
    echo "WS_PATH=${WS_PATH}"
    echo "IMAGE=${IMAGE}"
    echo -e "CONTAINER=${CONTAINER}\n"

    echo "DOCKERFILE_NAME=${DOCKERFILE_NAME}"
    echo -e "ENTRYPOINT_FILE=${ENTRYPOINT_FILE}"
fi
