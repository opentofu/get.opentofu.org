#!/bin/bash

set -euo pipefail

cp -rf ./static ./dist
go run releases-generator/cmd/main.go dist/tofu/
