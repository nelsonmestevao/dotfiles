#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing docker..."
_install docker

echo_info "Installing docker-compose..."
_install docker-compose

# add docker to usergroup
sudo usermod -aG docker "${USER}"

echo_done "Rofi configuration!"
