#!/bin/bash

set -ex

../../src/install.sh --debug --install-method "brew"

tofu --version