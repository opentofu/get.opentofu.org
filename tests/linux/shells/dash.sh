#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y dash
    export SHELL_COMMAND=/bin/dash
    ;;
  ubuntu)
    sudo apt-get install -y dash
    export SHELL_COMMAND=/bin/dash
    ;;
  alpine)
    apk add dash
    export SHELL_COMMAND=/usr/bin/dash
    ;;
  fedora | rocky)
    yum install -y dash
    export SHELL_COMMAND=/bin/dash
    ;;
  opensuse)
    zypper install -y dash
    export SHELL_COMMAND=/bin/dash
esac
