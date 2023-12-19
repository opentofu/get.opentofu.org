#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get update
    apt-get install -y ash
    ;;
  ubuntu)
    sudo apt-get update
    sudo apt-get install -y ash
    ;;
  alpine)
    apk add ash
    ;;
  fedora | rocky)
    yum install -y ash
    ;;
  opensuse)
    zypper install -y ash
esac

SHELL_COMMAND=/bin/ash
