#!/bin/bash

set -ex

../../src/install-opentofu.sh --debug

tofu --version