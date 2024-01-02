#!/bin/bash

set -e

case "$DISTRO" in
  debian)
    apt-get install -y snapd systemd
    ;;
  ubuntu)
    apt-get install -y snapd systemd snap fuse
    systemctl enable snapd
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
