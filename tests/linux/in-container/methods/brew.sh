#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y git build-essential gcc procps curl file bash
    ;;
  ubuntu)
    apt-get install -y git build-essential gcc procps curl file bash
    ;;
  alpine)
    #apk add git gcc bash curl ruby gcompat
    echo "alpine - brew not supported"
    exit 0
    ;;
  fedora | rocky)
    dnf install -y procps-ng curl file git gcc bash
    #dnf group install -y 'Development Tools'
    ;;
  opensuse)
    zypper install -y file git gcc tar bash ruby gzip
esac

NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /root/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

export METHOD_NAME=brew
