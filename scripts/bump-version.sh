#!/bin/bash
set -eux

cd "${PROJECT_DIR:-.}"
exec > "${PROJECT_DIR:-.}/script.log" 2>&1

# Update the build number
agvtool bump -all

if [[ "${CONFIGURATION:-${1:-}}" = "Release" ]]; then
    MVERS=$(agvtool mvers -terse1)
    set -o noglob
    IFS="." ARR=(${MVERS})
    let NEWPATCH=${ARR[2]}+1
    agvtool new-marketing-version ${ARR[0]}.${ARR[1]}.${NEWPATCH}
fi
