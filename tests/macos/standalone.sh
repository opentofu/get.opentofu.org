#!/bin/bash

set -ex

../../src/install-opentofu.sh --debug --install-method "standalone"

tofu --version