#!/bin/bash

export DOCKER_CREATE_OPTS="${DOCKER_CREATE_OPTS} --tmpfs /run --tmpfs /run/lock --tmpfs /tmp --privileged -v /lib/modules:/lib/modules:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro"
export DOCKER_INIT="/sbin/init"