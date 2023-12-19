#!/bin/sh

case "$DISTRO" in
  debian)
    apt-get install -y curl unzip
    LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
    curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign_${LATEST_VERSION}_amd64.deb"
    dpkg -i cosign_${LATEST_VERSION}_amd64.deb
    rm cosign_${LATEST_VERSION}_amd64.deb
  ubuntu)
    sudo apt-get install -y curl unzip
    LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
    curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign_${LATEST_VERSION}_amd64.deb"
    sudo dpkg -i cosign_${LATEST_VERSION}_amd64.deb
    rm cosign_${LATEST_VERSION}_amd64.deb
    ;;
  alpine)
    apk add cosign unzip curl
    ;;
  fedora | rocky)
    yum install -y curl unzip
    LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
    curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-${LATEST_VERSION}.x86_64.rpm"
    rpm -ivh cosign-${LATEST_VERSION}.x86_64.rpm
    rm cosign-${LATEST_VERSION}.x86_64.rpm
    ;;
  opensuse)
    zypper install -y curl unzip
    LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
    curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-${LATEST_VERSION}.x86_64.rpm"
    rpm -ivh cosign-${LATEST_VERSION}.x86_64.rpm
    rm cosign-${LATEST_VERSION}.x86_64.rpm
    ;;
esac

export METHOD_NAME=portable