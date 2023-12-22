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

# shellcheck disable=SC1090
. "./distros/${DISTRO}.sh"

# shellcheck disable=SC1090
. "./methods/${METHOD}.sh"
if [ -z "${METHOD_NAME}" ]; then
  echo "Test framework bug: the METHOD_NAME variable is not set for the method ${METHOD}."
  exit 1
fi

# shellcheck disable=SC1090
. "./shells/${SH}.sh"
if [ -z "${SHELL_COMMAND}" ]; then
  echo "Test framework bug: the SHELL_COMMAND variable is not set for the shell ${SH}."
  exit 1
fi

if [ -n "${INIT}" ] && [ "${INIT}" != "-" ]; then
  exec ${INIT}
else
  echo "Setup complete."
  exec /tests/linux/in-container/run-test.sh
fi
