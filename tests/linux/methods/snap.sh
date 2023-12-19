#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y snapd
    ;;
  ubuntu)
    sudo apt-get install -y snapd
    ;;
  alpine)
    apk add snapd
    ;;
  fedora | rocky)
    yum install -y snapd
    ;;
  opensuse)
    zypper install -y snapd
    ;;
esac

export METHOD_NAME=snap