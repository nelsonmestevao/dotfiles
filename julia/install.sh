#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Symling startup.jl..."
mkdir -p ~/.julia/config
ln -sfT ~/.dotfiles/julia/startup.jl ~/.julia/config/startup.jl

echo_done "Julia configuration!"
