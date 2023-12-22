#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y bash
    ;;
  ubuntu)
    apt-get install -y bash
    ;;
  alpine)
    apk add bash
    ;;
  fedora | rocky)
    yum install -y bash
    ;;
  opensuse)
    zypper install -y bash
esac
export SHELL_COMMAND=/bin/bash
