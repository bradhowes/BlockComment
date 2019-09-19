#!/bin/bash

set -eu #x

if [[ -n "${PROJECT_DIR:-}" ]]; then
    cd "${PROJECT_DIR:-.}"
    exec > "${PROJECT_DIR:-.}/script.log" 2>&1
fi

# Update the build number
agvtool bump -all > /dev/null 2>&1

BUILD="$(agvtool vers -terse)"
MVERS="$(agvtool mvers -terse1)"

echo "-- BUILD: ${BUILD} VERS: ${MVERS}"

[[ -z "${1:-}" ]] && exit 0

# Argument given for marketing version update
declare -i INDEX
case "${1}" in
    0|ma*) INDEX=0 ;; # bump major version
    1|mi*) INDEX=1 ;; # bump minor version
    *) INDEX=2 ;;     # bump patch version
esac

# Get the current version and then get the component parts
set -o noglob
IFS="." ARR=(${MVERS})
let NEWVALUE=${ARR[${INDEX}]}+1
ARR[${INDEX}]=${NEWVALUE}

# Zero out parts after the one being bumped changed
while
    let INDEX+=1
    ((INDEX < 3))
do
    ARR[${INDEX}]=0
done

# Apply new version
NVERS="${ARR[0]}.${ARR[1]}.${ARR[2]}"
echo "-- ${MVERS} --> ${NVERS}"
agvtool new-marketing-version "${NVERS}" > /dev/null 2>&1
