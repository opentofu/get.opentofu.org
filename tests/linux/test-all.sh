#!/bin/bash

SUMMARYFILE=$(mktemp)
trap "rm -rf '${SUMMARYFILE}'" EXIT
FINAL_EXIT_CODE=0
printf "%-20s %-20s %-20s %s\n" "Distro" "Method" "Shell" "Result" >>$SUMMARYFILE
for DISTROFILE in distros/*.sh; do
  DISTRO=$(basename "${DISTROFILE}" | sed -e 's/\.sh//')
  for METHODFILE in methods/*.sh; do
    METHOD=$(basename "${METHODFILE}" | sed -e 's/\.sh//')
    for SHFILE in shells/*.sh; do
      SH=$(basename "${SHFILE}" | sed -e 's/\.sh//')

      (
        LOGFILE=$(mktemp)
        trap "rm -rf '$LOGFILE'" EXIT
        DISTRO="${DISTRO}" METHOD="${METHOD}" SH="${SH}" ./test.sh 2>&1 >$LOGFILE
        EXIT_CODE=$?
        if [ "$?" -eq "0" ]; then
          echo -e "::group::\033[32m✅  ${DISTRO} ${METHOD} ${SH}\033[0m"
          printf "%-20s %-20s %-20s %s\n" "${DISTRO}" "${METHOD}" "${SH}" "✅" >>$SUMMARYFILE
        else
          echo -e "::group::\033[31m❌  ${DISTRO} ${METHOD} ${SH} (exit code: ${EXIT_CODE})\033[0m"
          printf "%-20s %-20s %-20s %s\n" "${DISTRO}" "${METHOD}" "${SH}" "❌" >>$SUMMARYFILE
        fi
        cat $LOGFILE
        echo "::endgroup::"
        exit "${EXIT_CODE}"
      )
      EXIT_CODE=$?

      if [ "${EXIT_CODE}" -ne "0" ]; then
        FINAL_EXIT_CODE=${EXIT_CODE}
      fi
    done
  done
done

if [ "${FINAL_EXIT_CODE}" -eq 0 ]; then
  echo -e "::group::\033[32m✅  Summary\033[0m"
else
  echo -e "::group::\033[32m❌  Summary\033[0m"
fi
cat "$SUMMARYFILE"
echo "::endgroup::"

exit $FINAL_EXIT_CODE