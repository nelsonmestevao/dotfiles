#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing Haskell package binaries from hackage.haskell.org!"

xargs stack install <hackage.txt
