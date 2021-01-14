#!/usr/bin/env bash

#set -Eeuo pipefail

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

mkdir -p "$HOME/.julia/config"
symlink "$HOME/.dotfiles/julia/startup.jl" "$HOME/.julia/config/startup.jl"
