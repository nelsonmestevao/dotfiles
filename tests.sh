#!/bin/bash

if find . -name '*.sh' -print0 | xargs -n1 -0 shellcheck -s bash; then
    echo "\033[0;32mShell script linting passed!\033[0m"
else
    echo "\033[0;31mShell script linting failed!\033[0m"
    exit 1
fi
