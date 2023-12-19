#!/bin/sh

set -e

if [ -z "${DISTRO}" ]; then
  echo "Please set the DISTRO environment variable."
  exit 1
fi
if [ -z "${METHOD}" ]; then
  echo "Please set the METHOD environment variable."
  exit 1
fi
if [ -z "${SH}" ]; then
  echo "Please set the SH environment variable."
  exit 1
fi

DEBUGLOG=$(mktemp)
trap "rm -rf '$DEBUGLOG'" EXIT

. ./inits/${DISTRO}.sh 2>&1 >$DEBUGLOG

. ./methods/${METHOD}.sh 2>&1 >$DEBUGLOG
if [ -z "${METHOD_NAME}" ]; then
  echo "Test framework bug: the METHOD_NAME variable is not set for the method ${METHOD}."
  cat $DEBUGLOG
  exit 1
fi

. ./shells/${SH}.sh 2>&1 >$DEBUGLOG
if [ -z "${SHELL_COMMAND}" ]; then
  echo "Test framework bug: the SHELL_COMMAND variable is not set for the shell ${SH}."
  cat $DEBUGLOG
  exit 1
fi

set -x
"${SHELL_COMMAND}" /src/install.sh --debug --install-method "${METHOD_NAME}"

tofu --version
