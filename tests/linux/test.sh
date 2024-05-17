#!/bin/bash

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

if [ -z "${GITHUB_TOKEN}" ]; then
  GITHUB_TOKEN=""
fi

set -euo pipefail

DOCKER_CREATE_OPTS=""
# This string contains the default init command. This also switches the script over to the "exec" method.
DOCKER_INIT=""
UNSUPPORTED=0
# shellcheck disable=SC1090
. "./distros/${DISTRO}.sh"
if [ -z "${IMAGE}" ]; then
    echo "Test framework bug: the IMAGE variable is not set for the distro ${DISTRO}."
    exit 1
fi

# shellcheck disable=SC1090
. "./methods/${METHOD}.sh"
# shellcheck disable=SC1090
. "./shells/${SH}.sh"

if [ "${UNSUPPORTED}" -eq 1 ]; then
  echo "Combination unsupported, skipping test."
  exit 0
fi

INIT="-"
if [ -n "${DOCKER_INIT}" ]; then
  INIT="${DOCKER_INIT}"
fi
CID=$(\
docker create -tq \
  -v "$(realpath "$(pwd)/../../static"):/static" \
  -v "$(realpath "$(pwd)/../"):/tests" \
  -e "DISTRO=${DISTRO}" \
  -e "METHOD=${METHOD}" \
  -e "SH=${SH}" \
  -e "GITHUB_TOKEN=${GITHUB_TOKEN}" \
  -w /tests/linux/in-container/ \
  --entrypoint /tests/linux/in-container/test-helper.sh \
  ${DOCKER_CREATE_OPTS} \
  "${IMAGE}" \
  ${INIT} \
)

trap 'docker rm --force "${CID}" 2>&1 >/dev/null' EXIT
if [ -n "${DOCKER_INIT}" ]; then
  docker start "${CID}" >/dev/null
  SETUP=0
  echo "Waiting for container setup to complete..."
  for i in $(seq 1 300); do
    if [ $(docker logs "${CID}" | grep -c "Setup complete.") -ne 0 ]; then
      SETUP=1
      break
    fi
    sleep 1
  done
  if [ "${SETUP}" -eq "0" ]; then
    echo "Setup failed."
    docker logs "${CID}"
    exit 1
  fi
  docker exec -t \
    -e "DISTRO=${DISTRO}" \
    -e "METHOD=${METHOD}" \
    -e "SH=${SH}" \
    -e "GITHUB_TOKEN=${GITHUB_TOKEN}" \
    -e "SHELL_COMMAND=${SHELL_COMMAND}" \
    -w /tests/linux/in-container/ \
    "${CID}" \
     /tests/linux/in-container/run-test.sh
else
  docker start -a "${CID}"
fi
