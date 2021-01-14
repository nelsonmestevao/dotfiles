#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

HACKAGE=(
  ShellCheck
  # cabal-install
  hindent
  hlint
  # lhs2tex
  # pandoc
  # pandoc-citeproc
  # pandoc-include-code
  # patat
)

echo_info "Installing Haskell package binaries from hackage.haskell.org!"

for pkg in "${HACKAGE[@]}"; do
  echo_info "Installing ${pkg}..."
  stack install "$pkg"
  echo_done "${pkg} installed!"
done
