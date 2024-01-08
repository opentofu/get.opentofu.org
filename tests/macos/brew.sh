#!/bin/bash

set -ex

../../src/install-opentofu.sh --debug --install-method "brew"

tofu --version