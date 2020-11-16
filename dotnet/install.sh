#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing dotnet dev tools..."
_install dotnet-sdk
_install dotnet-runtime
_install dotnet-host

echo_done "dotnet configuration!"
