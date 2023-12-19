#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get update
    apt-get install -y ash
    ;;
  ubuntu)
    apt-get update
    apt-get install -y ash
    ;;
  alpine)
    #apk add ash
    echo "$DISTRO - ash not supported"
    exit 0
    ;;
  fedora | rocky)
    echo "$DISTRO - ash not supported"
    exit 0
    #yum install -y ash
    ;;
  opensuse)
    echo "$DISTRO - ash not supported"
    exit 0
    #zypper install -y ash
esac

export SHELL_COMMAND=/bin/ash
