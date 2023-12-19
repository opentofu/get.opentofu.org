#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y ksh
    ;;
  ubuntu)
    sudo apt-get install -y ksh
    ;;
  alpine)
    apk add ksh
    ;;
  fedora | rocky)
    yum install -y ksh
    ;;
  opensuse)
    zypper install -y ksh
esac
export SHELL_COMMAND=/bin/ksh
