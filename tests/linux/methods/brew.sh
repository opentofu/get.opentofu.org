#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y git build-essential gcc procps curl file bash
    ;;
  ubuntu)
    sudo apt-get install -y git build-essential gcc procps curl file  bash
    ;;
  alpine)
    apk add git gcc bash curl
    ;;
  fedora | rocky)
    yum install -y procps-ng curl file git gcc  bash
    yum groupinstall -y 'Development Tools'
    ;;
  opensuse)
    zypper install -y procps-ng curl file git gcc tar  bash
    zypper groupinstall -y 'Development Tools'
esac

NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /root/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

export METHOD_NAME=brew