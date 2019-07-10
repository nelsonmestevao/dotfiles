#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo "Symling .default-python-packages..."
ln -sfT ~/.dotfiles/python/default-python-packages ~/.default-python-packages

echo_done "Python configuration!"
