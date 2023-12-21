#!/bin/sh

echo "Skipping combination $DISTRO - snapd"
exit 0

case "$DISTRO" in
  debian)
    apt-get install -y snapd
    ;;
  ubuntu)
    apt-get install -y snapd
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
