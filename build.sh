#!/bin/bash

set -euo pipefail

cp -rf ./src ./dist
go run releases-generator/cmd/main.go dist/tofu/
