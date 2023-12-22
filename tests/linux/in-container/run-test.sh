#!/bin/bash

set -ex
"${SHELL_COMMAND}" /src/install.sh --debug --install-method "${METHOD_NAME}"

tofu --version
