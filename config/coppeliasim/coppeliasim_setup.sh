#!/usr/bin/env bash

# ${1}: USER
# ${2}: GROUP

printf "
# CoppeliaSim ROOT DIR
export COPPELIASIM_ROOT_DIR=/home/"${1}"/coppeliasim
" >>/home/"${1}"/.bashrc
