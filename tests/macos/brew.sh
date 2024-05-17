#!/bin/bash

set -ex

../../static/install-opentofu.sh --debug --install-method "brew"

tofu --version