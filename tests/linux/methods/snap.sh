#!/bin/bash

set -e

case "$DISTRO" in
  debian)
    apt-get install -y snapd
    /usr/lib/snapd/snapd &
    ;;
  ubuntu)
    apt-get install -y snapd
    /usr/lib/snapd/snapd &
    ;;
  alpine)
    apk add snapd
    ;;
  fedora | rocky)
    yum install -y snapd
    /usr/libexec/snapd/snapd &
    ;;
  opensuse)
    zypper install -y snapd
    /usr/libexec/snapd/snapd &
    ;;
esac

ln -s /var/lib/snapd/snap /snap

export METHOD_NAME=snap
