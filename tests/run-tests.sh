#!/bin/bash

set -e

/src/install.sh --gpg-url file:///src/opentofu.asc $@

tofu --version
