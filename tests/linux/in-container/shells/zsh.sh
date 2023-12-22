#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y zsh
    ;;
  ubuntu)
    apt-get install -y zsh
    ;;
  alpine)
    apk add zsh
    ;;
  fedora | rocky)
    yum install -y zsh
    ;;
  opensuse)
    zypper install -y zsh
esac
export SHELL_COMMAND=/bin/zsh
