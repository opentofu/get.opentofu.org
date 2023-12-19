#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y dash
    ;;
  ubuntu)
    sudo apt-get install -y dash
    ;;
  alpine)
    apk add dash
    ;;
  fedora | rocky)
    yum install -y dash
    ;;
  opensuse)
    zypper install -y dash
esac
export SHELL_COMMAND=/bin/dash
