#!/bin/bash

set -e

# Unusupported for now.
export UNSUPPORTED=1
exit 0

case "$DISTRO" in
  debian)
    apt-get install -y snapd systemd
    ;;
  ubuntu)
    apt-get install -y snapd systemd
    ;;
  alpine)
    # Not supported
    UNSUPPORTED=1
    ;;
  fedora | rocky)
    yum install -y snapd systemd
    ;;
  opensuse)
    zypper install -y snapd systemd
    ;;
esac

ln -s /var/lib/snapd/snap /snap

export METHOD_NAME=snap
