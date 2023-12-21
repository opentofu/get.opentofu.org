#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y ksh
    ;;
  ubuntu)
    apt-get install -y ksh
    ;;
  alpine)
    #apk add ksh
    echo "alpine - ksh not supported"
    exit 0
    ;;
  fedora | rocky)
    yum install -y ksh
    ;;
  opensuse)
    zypper install -y ksh
esac
export SHELL_COMMAND=/bin/ksh
