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

# Create the container without umask
CID1=$(
  docker create -tq \
    -v "$(realpath "$(pwd)/../../src"):/src" \
    -v "$(realpath "$(pwd)/../"):/tests" \
    -e "DISTRO=${DISTRO}" \
    -e "METHOD=${METHOD}" \
    -e "SH=${SH}" \
    -e "GITHUB_TOKEN=${GITHUB_TOKEN}" \
    -w /tests/linux/in-container/ \
    --entrypoint /tests/linux/in-container/test-helper.sh \
    ${DOCKER_CREATE_OPTS} \
    "${IMAGE}" \
    ${INIT}
)

# Set up trap to remove container CID1 on exit
trap 'docker rm --force "${CID1}" >/dev/null 2>&1' EXIT

# Start the first container without umask
if [ -n "${DOCKER_INIT}" ]; then
  docker start "${CID1}" >/dev/null

  echo "Testing installer script in default environment (without hardening)"

  # Wait for container setup to complete
  SETUP=0
  echo "Waiting for first container setup to complete..."
  for i in $(seq 1 300); do
    if [ $(docker logs "${CID1}" | grep -c "Setup complete.") -ne 0 ]; then
      SETUP=1
      break
    fi
    sleep 1
  done

  if [ "${SETUP}" -eq "0" ]; then
    echo "Setup failed for the first container."
    docker logs "${CID1}"
    exit 1
  fi

  # Run the installer script and check exit code for the first container
  docker exec -t \
    -e "DISTRO=${DISTRO}" \
    -e "METHOD=${METHOD}" \
    -e "SH=${SH}" \
    -e "GITHUB_TOKEN=${GITHUB_TOKEN}" \
    -e "SHELL_COMMAND=${SHELL_COMMAND}" \
    -w /tests/linux/in-container/ \
    "${CID1}" \
    /tests/linux/in-container/run-test.sh

else
  docker start -a "${CID1}"
fi

# Check if $DISTRO is Debian and create CID2 accordingly
if [ "${DISTRO}" = "debian" ]; then
  # Create the container with umask 0027
  CID2=$(
    docker create -tq \
      -v "$(realpath "$(pwd)/../../src"):/src" \
      -v "$(realpath "$(pwd)/../"):/tests" \
      -e "DISTRO=${DISTRO}" \
      -e "METHOD=${METHOD}" \
      -e "SH=${SH}" \
      -e "GITHUB_TOKEN=${GITHUB_TOKEN}" \
      -w /tests/linux/in-container/ \
      --entrypoint /tests/linux/in-container/test-helper.sh \
      ${DOCKER_CREATE_OPTS} \
      "${IMAGE}" \
      umask 0027 \
    ${INIT}
  )

  # Set up trap to remove container CID2 on exit
  if [ -n "${DOCKER_INIT}" ]; then
    trap 'docker rm --force "${CID1}" "${CID2}" >/dev/null 2>&1' EXIT

    # Start the second container with umask
    docker start "${CID2}" >/dev/null

    echo "Second container running with umask 0027 (hardened)."

    # Wait for container setup to complete
    SETUP=0
    echo "Waiting for second container setup to complete..."
    for i in $(seq 1 300); do
      if [ $(docker logs "${CID2}" | grep -c "Setup complete.") -ne 0 ]; then
        SETUP=1
        break
      fi
      sleep 1
    done

    if [ "${SETUP}" -eq "0" ]; then
      echo "Setup failed for the second container."
      docker logs "${CID2}"
      exit 1
    fi

    # Run the installer script and check exit code for the second container
    docker exec -t \
      -e "DISTRO=${DISTRO}" \
      -e "METHOD=${METHOD}" \
      -e "SH=${SH}" \
      -e "GITHUB_TOKEN=${GITHUB_TOKEN}" \
      -e "SHELL_COMMAND=${SHELL_COMMAND}" \
      -w /tests/linux/in-container/ \
      "${CID2}" \
      /tests/linux/in-container/run-test.sh
  else
    docker start -a "${CID2}"
  fi
fi
