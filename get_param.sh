#!/usr/bin/env bash

set -euo pipefail

# Set docker image name based on the directory path
#
# Usage:
#   set_image_name <outvar> <path>
#
#
# Parameters:
#   <outvar>: variable name to store the image name
#   <path>: the directory path to extract the image name from
#
# Examples:
#   set_image_name "/home/user/projects/docker_maypp" IMAGE
#   set_image_name "/home/user/projects/maypp_ws" IMAGE
function set_image_name() {
    local -n _outvar="${1:?"${FUNCNAME[0]}: missing outvar argument"}"
    local _path="${2:?"${FUNCNAME[0]}: missing path argument"}"

    local -a _path_array=()
    local _found="" i

    IFS='/' read -ra _path_array <<<"${_path}"

    for (( i=${#_path_array[@]}-1 ; i>=0 ; i-- )); do
        local _part="${_path_array[i]}"
        # starts with 'docker_' or ends with '_ws'
        if [[ ${_part} == docker_* ]]; then
            _found="${_path_array[i]#docker_}"
            break
        elif [[ ${_part} == *_ws ]]; then
            _found="${_path_array[i]%_ws}"
            break
        fi
    done

    _outvar="${_found:-unknown}"
    _outvar="${_outvar,,}"
}

# Get workspace '*_ws' path, if not found, return parent path
#
# Usage:
#   get_workdir <outvar> <path>
#
# Parameters:
#   <outvar>: variable name to store the workspace path
#   <path>: the directory path to extract the image name from
#
# Examples:
#   get_workdir "/home/user/projects/maypp_ws" WS_PATH
#   get_workdir "/home/user/projects/docker_maypp" WS_PATH
function get_workdir() {
    local -n _outvar="${1:?"${FUNCNAME[0]}: missing outvar argument"}"
    local _path="${2:?"${FUNCNAME[0]}: missing path argument"}"

    local -a _path_array=()
    local _is_abs=0 _workdir="" i="" j=""

    # If the path is root, return "/"
    if [[ "${_path}" == "/" ]]; then
        _outvar="/"
        return 0
    fi

    # Remove trailing slashes from the path
    while [[ "${_path}" == */ ]]; do
        _path="${_path%/}"
    done

    # Check if the path is absolute
    [[ "${_path}" == /* ]] && _is_abs=1

    # Split the path into an array using '/' as the delimiter
    IFS='/' read -ra _path_array <<<"${_path}"

    for (( i=${#_path_array[@]}-1 ; i>=0 ; i-- )); do
        local _part="${_path_array[i]}"

        [[ -z "${_part}" ]] && continue
        # If the part end with '_ws'
        if [[ "${_part}" == *_ws ]]; then
            for (( j=0; j<=i; j++ )); do
                [[ -z "${_path_array[j]}" ]] && continue
                _workdir+="/${_path_array[j]}"
            done

            (( _is_abs )) || _workdir="${_workdir#/}"
            _outvar="${_workdir:-/}"
            return 0
        fi
    done

    # If no workspace folder is found based on the provided prefix,
    if [[ "$_path" == */* ]]; then
        # Extract the path to the parent directory
        _workdir="${_path%/*}"
        [[ -z "${_workdir}" ]] && _workdir="/"
    else
        _workdir="."
    fi

    _outvar="${_workdir}"
    return 0
}

# get system parameter, including user, group, UID, GID, hardware architecture, and GPU support
#
# Usage:
#   get_system_info <docker_hub_user_outvar> <user_outvar> <group_outvar> <uid_outvar> <gid_outvar> <hardware_outvar> <gpu_flag_outvar>
#
# Parameters:
#   <docker_hub_user_outvar>: variable name to store the docker hub user name
#   <user_outvar>: variable name to store the user name
#   <group_outvar>: variable name to store the group name
#   <uid_outvar>: variable name to store the user ID
#   <gid_outvar>: variable name to store the group ID
#   <hardware_outvar>: variable name to store the hardware architecture
#   <gpu_flag_outvar>: variable name to store the gpu flag for docker run
#
# Examples:
#   get_system_info DOCKER_HUB_USER USER GROUP UID GID HARDWARE GPU_FLAG
function get_system_info() {
    local -n _docker_hub_user_outvar="${1:?"${FUNCNAME[0]}: missing docker_hub_user outvar argument"}"; shift
    local -n _user_outvar="${1:?"${FUNCNAME[0]}: missing user outvar argument"}"; shift
    local -n _group_outvar="${1:?"${FUNCNAME[0]}: missing group outvar argument"}"; shift
    local -n _uid_outvar="${1:?"${FUNCNAME[0]}: missing uid outvar argument"}"; shift
    local -n _gid_outvar="${1:?"${FUNCNAME[0]}: missing gid outvar argument"}"; shift
    local -n _hardware_outvar="${1:?"${FUNCNAME[0]}: missing hardware outvar argument"}"; shift
    local -n _gpu_flag_outvar="${1:?"${FUNCNAME[0]}: missing gpu flag outvar argument"}"

    local _docker_info_name=""

    # Try to retrieve the current user from Docker using the `docker info`
    # command and store it in the `DOCKER_HUB_USER` variable
    _docker_info_name=$(docker info 2>/dev/null | grep Username | cut -d ' ' -f 3)
    # If that fails, fall back to using the `id` command to get the current user
    _docker_hub_user_outvar="${_docker_info_name:-$(id -un)}"

    _user_outvar="${USER:-$(id -un)}"
    _group_outvar="$(id -gn)"
    _uid_outvar="$(id -u)"
    _gid_outvar="$(id -g)"

    _hardware_outvar="$(uname -m)"

    # NOTE: maybe add check nvidia-docker2 or nvidia-container-runtime?
    local _pkg="nvidia-container-toolkit"
    if dpkg-query -W -f='${db:Status-Abbrev}\n' -- "${_pkg}" 2>/dev/null | grep -q '^ii'; then
        # Used in Docker run shell script
        _gpu_flag_outvar="--gpus all"

        # TODO: wait check docker compose flag
        # Used in Docker compose shell script
        # COMPOSE_GPU_FLAG="nvidia"
        # COMPOSE_GPU_CAPABILITIES="gpu, utility"
    else
        # Used in Docker run shell script
       _gpu_flag_outvar=""

        # Used in Docker compose shell script
        # COMPOSE_GPU_FLAG="nvidia"
        # COMPOSE_GPU_CAPABILITIES="gpu, utility"
    fi
}

# set the file name based on the directory path and hardware architecture
#
# Usage:
#  set_file <options> [--] <outvar> <file_name> <path> <hardware>
#
# Options:
#   --prefix    | -p  file prefix
#   --extension | -e  file extension, default is empty (optional)
#
# Parameters:
#   <_outvar>: variable name to store the file name
#   <path>: the directory path to search for the file
#   <hardware>: the hardware architecture (e.g., x86_64, arm64
#
# Examples:
function set_file() {
    local _parsed=""
    local _short_opts="p:e:"
    local _long_opts="prefix:,extension:"

    if ! _parsed=$(getopt -o "${_short_opts}" --long "${_long_opts}" -n "${FUNCNAME[0]}" -- "$@"); then
        printf "Usage: %s <options> [--] <outvar> <file_name> <path> <hardware>\n" "${FUNCNAME[0]}" >&2
    fi

    eval set -- "${_parsed}"

    local _prefix="" _ext=""

    while true; do
        case "$1" in
            -p | --prefix)
                _prefix="$2"; shift 2;;
            -e | --extension)
                _ext="$2"; shift 2;;
            --) shift; break ;;
            *) break ;;
        esac
    done

    [[ -n ${_ext} && ! ${_ext} =~ ^\. ]] && _ext=".${_ext}"

    local -n _outvar="${1:?"${FUNCNAME[0]}: missing outvar argument"}"; shift
    local _path="${1:?"${FUNCNAME[0]}: missing path argument"}"; shift
    local _hardware="${1:?"${FUNCNAME[0]}: missing hardware argument"}"

    local -a _file_list=()
    local _file=""

    readarray -t _file_list < <(find "${_path}" -maxdepth 1 -type f -name "${_prefix}*${_ext}" -printf "%f\n")

    # Check if there is no specific file found
    if [[ ${#_file_list[@]} -eq 0 ]]; then
        printf "No %s file found in the directory: %s\n" "${_prefix}${_ext}" "${_path}" >&2
        return 1
    else
        for _file in "${_file_list[@]}"; do
            # Check for exact match with hardware suffix
            if [[ ${_file} == "${_prefix}_${_hardware}${_ext}" || ${_file} == "${_prefix}.${_hardware}${_ext}" ]]; then
                _outvar="${_file}"
                return 0
            # Check for exact match without hardware suffix
            elif [[ ${_file} == "${_prefix}${_ext}" ]]; then
                _outvar="${_file}"
                return 0
            # Check for other suffix match
            elif [[ ${_file} == ${_prefix}_*${_ext} || ${_file} == ${_prefix}.*${_ext} ]]; then
                _outvar="${_file}"
                return 0
            fi
        done
    fi
}

################################ MAIN ##########################################
function main() {
    local _parsed=""
    local _short_opts=""
    local _long_opts="debug"

    if ! _parsed=$(getopt -o "${_short_opts}" --long "${_long_opts}" -n "${FUNCNAME[0]}" -- "$@"); then
        printf "Usage: %s [options]\n" "${FUNCNAME[0]}" >&2
    fi

    eval set -- "${_parsed}"

    local _debug=false

    while true; do
        case "$1" in
            --debug)
                _debug=true; shift ;;
            --) shift; break ;;
            *) break ;;
        esac
    done

    local _script_path=""
    _script_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

    image="" container=""
    ws_path=""
    docker_hub_user="" user="" group="" uid="" gid="" hardware="" gpu_flag=""
    dockerfile_name="" entrypoint_file=""

    set_image_name image "${_script_path}"
    container="${image,,}"

    get_workdir ws_path "${_script_path}"

    get_system_info docker_hub_user user group uid gid hardware gpu_flag

    set_file --prefix "Dockerfile" -- dockerfile_name "${_script_path}" "${hardware}"
    set_file --prefix "entrypoint" -e "sh" -- entrypoint_file "${_script_path}" "${hardware}"

    if [ "${_debug}" == true ]; then
        printf "image: %s, container: %s\n" "${image}" "${container}"
        printf "ws_path: %s\n" "${ws_path}"
        printf "docker_hub_user: %s, user: %s, group: %s, uid: %s, gid: %s, hardware: %s, gpu_flag: %s\n" \
            "${docker_hub_user}" "${user}" "${group}" "${uid}" "${gid}" "${hardware}" "${gpu_flag:-null}"
        printf "dockerfile: %s\n" "${dockerfile_name}"
        printf "entrypoint: %s\n" "${entrypoint_file}"
    fi
}


main "$@" || exit $?
