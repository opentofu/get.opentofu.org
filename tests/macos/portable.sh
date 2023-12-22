#!/bin/bash

set -ex

../../src/install.sh --debug --install-method "portable"

tofu --version