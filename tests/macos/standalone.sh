#!/bin/bash

set -ex

../../src/install-opentofu.sh --debug --install-method "portable"

tofu --version