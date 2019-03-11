#!/bin/bash

if find . -name '*.sh' -print0 | xargs -n1 -0 shellcheck -x; then
  printf '\033[0;32mShell script linting passed!\033[0m\n'
else
  printf '\033[0;31mShell script linting failed!\033[0m\n'
  exit 1
fi
