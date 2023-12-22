#!/bin/bash

LOGROOT="./logs"
rm -rf $LOGROOT
mkdir $LOGROOT

function run_case() {
	export DISTRO="$1" METHOD="$2" SH="$3" 
	echo "Starting DISTRO=$DISTRO METHOD=$METHOD SH=$SH"

	LOGFILE="${LOGROOT}/results.${DISTRO}.${METHOD}.${SH}.log"
        ./test.sh &>$LOGFILE
        EXIT_CODE=$?

	echo "Completed DISTRO=$DISTRO METHOD=$METHOD SH=$SH with exit code $EXIT_CODE"
}

export -f run_case

cases=""

for DISTROFILE in distros/*.sh; do
#for DISTROFILE in alpine; do
  DISTRO=$(basename "${DISTROFILE}" | sed -e 's/\.sh//')
  echo $DISTRO
  for METHODFILE in methods/*.sh; do
  #for METHODFILE in brew; do
    METHOD=$(basename "${METHODFILE}" | sed -e 's/\.sh//')
    for SHFILE in shells/*.sh; do
    #for SHFILE in bash; do
      SH=$(basename "${SHFILE}" | sed -e 's/\.sh//')
      run_case $DISTRO $METHOD $SH &
    done
  done
  wait
done
