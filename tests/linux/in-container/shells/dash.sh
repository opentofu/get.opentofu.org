#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y dash
    export SHELL_COMMAND=/bin/dash
    ;;
  ubuntu)
    apt-get install -y dash
    export SHELL_COMMAND=/bin/dash
    ;;
  alpine)
    apk add dash
    export SHELL_COMMAND=/usr/bin/dash
    ;;
  fedora)
    yum install -y dash
    export SHELL_COMMAND=/bin/dash
    ;;
  rocky)
    export UNSUPPORTED=1
    ;;
  opensuse)
    zypper install -y dash
    export SHELL_COMMAND=/bin/dash
esac
