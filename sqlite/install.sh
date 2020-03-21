#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Configuring .sqliterc..."
ln -sfT ~/.dotfiles/sqlite/sqliterc ~/.sqliterc

echo_done "SQLite configuration!"

