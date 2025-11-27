#!/usr/bin/env bash

# Get dependent parameters
FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

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
    local -r debug="$1"; shift

    local -r image="$1"; shift
    local -r user="$1"; shift

    local -r container="${image}"

    local dockerfile="" entrypoint_file=""

    set_file --prefix "Dockerfile" -- dockerfile "${FILE_PATH}" "x86_64"
    set_file --prefix "entrypoint" -e "sh" -- entrypoint_file "${FILE_PATH}" "x86_64"

    if [ "${debug}" = true ]; then
        printf "Building Docker image: %s/%s\n" "${user}" "${image}"
        printf "Using Dockerfile: %s\n" "${dockerfile}"
        printf "Using Entrypoint file: %s\n" "${entrypoint_file}"
    fi

    # Build docker images
    docker build -t "${user}"/"${image}" \
        --build-arg ENTRYPOINT_FILE="${entrypoint_file}" \
        -f "${FILE_PATH}"/"${dockerfile}" "${FILE_PATH}"
}

function run_container() {
    local -r debug="$1"; shift

    local -r image="$1"; shift
    local -r user="$1"; shift

    local -r container="${image}"

    if [ "${debug}" = true ]; then
        printf "Using Docker Image: %s\n" "${user}/${image}"
        printf "Run Docker Container: %s\n" "${container}"
    fi

    # Run docker container
    docker run --rm \
        --network=host \
        --ipc=host \
        -it --name "${container}" "${user}"/"${image}" \
            "$@"
}

function main() {
    # image and container name
    local ic_name="hokuyo_urg_node2"

    # if not login docker hub, use local username
    local -r docker_hub_user=$(
        docker info 2>/dev/null | grep Username | cut -d ' ' -f 3
    )
    local -r user="${docker_hub_user:-$(id -un)}"

    # All docker arguments
    local -ar docker_args=(
        "${ic_name}"
        "${user}"
    )

    local _parsed=""
    local _short_opts=""
    local _long_opts="build,run,debug"

    if ! _parsed=$(getopt -o "${_short_opts}" --long "${_long_opts}" -n "${FUNCNAME[0]}" -- "$@"); then
        printf "Usage: %s [options]\n" "${FUNCNAME[0]}" >&2
    fi

    eval set -- "${_parsed}"

    local _build=true _run=true _debug=false

    while true; do
        case "$1" in
            --build)
                _run=false; shift ;;
            --run)
                _build=false; shift ;;
            --debug)
                _debug=true; shift ;;
            --) shift; break ;;
            *) break ;;
        esac
    done

    local cmd_args=("$@")

    if [[ ${_build} == true ]]; then
        printf "Starting Docker image build process...\n"
        build_image "${_debug}" "${docker_args[@]}"
        printf "Docker image build process completed.\n"

        [ ${_run} == true ] && printf "\n\n"
    fi

    if [[ ${_run} == true ]]; then
        printf "Starting Docker container run process...\n"
        run_container "${_debug}" "${docker_args[@]}" "${cmd_args[@]}"
        printf "Docker container run process completed.\n"
    fi
}

main "${@}"
