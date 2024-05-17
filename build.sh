#!/bin/bash

set -euo pipefail

mkdir -p dist/
rsync -avz src/ dist/
go run releases-generator/cmd/main.go dist/tofu/
