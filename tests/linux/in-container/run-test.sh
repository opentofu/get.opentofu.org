#!/bin/sh

set -ex
"${SHELL_COMMAND}" /src/install-opentofu.sh --debug --install-method "${METHOD_NAME}"

tofu --version
