#!/bin/bash

set -ex

../../static/install-opentofu.sh --debug --install-method "standalone"

tofu --version