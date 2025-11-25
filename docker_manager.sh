#!/usr/bin/env bash

# Get dependent parameters
FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

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

function build_image() {
    local -r docker_info_name=$(docker info 2>/dev/null | grep Username | cut -d ' ' -f 3)
    local -r docker_hub_user="${docker_info_name:-$(id -un)}"

    local image="", dockerfile_name="" entrypoint_file=""

    set_image_name image "${FILE_PATH}"

    set_file --prefix "Dockerfile" -- dockerfile_name "${FILE_PATH}" "x86_64"
    set_file --prefix "entrypoint" -e "sh" -- entrypoint_file "${FILE_PATH}" "x86_64"

    # printf "Building Docker image: %s/%s\n" "${docker_hub_user}" "${image}"
    # printf "Using Dockerfile: %s\n" "${dockerfile_name}"
    # printf "Using Entrypoint file: %s\n" "${entrypoint_file}"

    # Build docker images
    docker build -t "${docker_hub_user}"/"${image}" \
        --build-arg ENTRYPOINT_FILE="${entrypoint_file}" \
        -f "${FILE_PATH}"/"${dockerfile_name}" "${FILE_PATH}"
}

function run_container() {
    local -r docker_info_name=$(docker info 2>/dev/null | grep Username | cut -d ' ' -f 3)
    local -r docker_hub_user="${docker_info_name:-$(id -un)}"

    local image="" container=""

    set_image_name image "${FILE_PATH}"
    container="${image}"

    docker run --rm \
        --network=host \
        --ipc=host \
        -it --name "${container}" "${docker_hub_user}"/"${image}"
}

function main() {
    local _parsed=""
    local _short_opts=""
    local _long_opts="build,run"

    if ! _parsed=$(getopt -o "${_short_opts}" --long "${_long_opts}" -n "${FUNCNAME[0]}" -- "$@"); then
        printf "Usage: %s [options]\n" "${FUNCNAME[0]}" >&2
    fi

    eval set -- "${_parsed}"

    local _build=true _run=true

    while true; do
        case "$1" in
            --build)
                _run=false; shift ;;
            --run)
                _build=false; shift ;;
            --) shift; break ;;
            *) break ;;
        esac
    done

    if [[ ${_build} == true ]]; then
        build_image
    fi

    if [[ ${_run} == true ]]; then
        run_container
    fi
}

main "${@}"
