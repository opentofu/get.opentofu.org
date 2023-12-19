#!/bin/bash

case "$DISTRO" in
  debian)
    export SHELL_COMMAND=/bin/dash
    ;;
  ubuntu)
    export SHELL_COMMAND=/bin/dash
    ;;
  alpine)
    export SHELL_COMMAND=/usr/bin/dash
    ;;
  fedora)
    export SHELL_COMMAND=/bin/dash
    ;;
  rocky)
    export UNSUPPORTED=1
    ;;
  opensuse)
    export SHELL_COMMAND=/bin/dash
esac
