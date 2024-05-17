#!/bin/sh

set -ex
"${SHELL_COMMAND}" /static/install-opentofu.sh --debug --install-method "${METHOD_NAME}"

tofu --version
