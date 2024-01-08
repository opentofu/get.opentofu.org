#!/bin/sh
#
set -e

INSTALLDIR="$(mktemp -d)"
trap "rm -rf '$INSTALLDIR'" EXIT

case "$DISTRO" in
  debian)
    apt-get install -y curl unzip
    LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest  -H "Authorization: token $GITHUB_TOKEN" | grep tag_name | cut -d : -f2 | tr -d "v\", ")
    curl -o "$INSTALLDIR/cosign.deb" -L "https://github.com/sigstore/cosign/releases/latest/download/cosign_${LATEST_VERSION}_amd64.deb" -H "Authorization: token $GITHUB_TOKEN"
    dpkg -i "$INSTALLDIR/cosign.deb"
    ;;
  ubuntu)
    apt-get install -y curl unzip
    LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest  -H "Authorization: token $GITHUB_TOKEN" | grep tag_name | cut -d : -f2 | tr -d "v\", ")
    curl -o "$INSTALLDIR/cosign.deb" -L "https://github.com/sigstore/cosign/releases/latest/download/cosign_${LATEST_VERSION}_amd64.deb" -H "Authorization: token $GITHUB_TOKEN"
    dpkg -i "$INSTALLDIR/cosign.deb"
    ;;
  alpine)
    apk add cosign unzip curl
    ;;
  fedora | rocky)
    yum install -y curl unzip
    LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest -H "Authorization: token $GITHUB_TOKEN" | grep tag_name | cut -d : -f2 | tr -d "v\", ")
    curl -o "$INSTALLDIR/cosign.rpm" -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-${LATEST_VERSION}-1.x86_64.rpm" -H "Authorization: token $GITHUB_TOKEN"
    rpm -ivh "$INSTALLDIR/cosign.rpm"
    ;;
  opensuse)
    zypper install -y unzip
    LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest -H "Authorization: token $GITHUB_TOKEN" | grep tag_name | cut -d : -f2 | tr -d "v\", ")
    curl -o "$INSTALLDIR/cosign.rpm" -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-${LATEST_VERSION}-1.x86_64.rpm" -H "Authorization: token $GITHUB_TOKEN"
    rpm -ivh "$INSTALLDIR/cosign.rpm"
    ;;
esac

export METHOD_NAME=standalone
