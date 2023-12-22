#!/bin/sh

case "$DISTRO" in
  debian | ubuntu)
    export METHOD_NAME=deb
    ;;
  alpine)
    export METHOD_NAME=apk
    ;;
  fedora | rocky | opensuse)
    export METHOD_NAME=rpm
    ;;
esac
