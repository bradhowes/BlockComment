#!/bin/bash
#
# Script to bump the build number and optionally the marketing version found
# in *.info files.
#
# Usage: bump-version.sh [ARG]
#
# Without ARG, just increment the build number. When ARG is present, it indicates
# which part of the marketing version to increment:
#
# 0 | ma[jor] -- increment the first number, and zero out the other two
# 1 | mi[nor] -- increment the second number, and zero out the third
# 2 | p[atch] -- increment the last number
#

set -eu #x

# Update the build number for all targets
agvtool bump -all > /dev/null 2>&1

# Fetch the new build number and the current 'marketing' version
BUILD="$(agvtool vers -terse)"
MVERS="$(agvtool mvers -terse1)"

printf "%s\n" "-- BUILD: ${BUILD} VERS: ${MVERS}"

# No arguments, all done
[[ -z "${1:-}" ]] && exit 0

# Argument given for marketing version update -- accept either index (0-2) or
# words 'ma[jor]', 'mi[nor]', 'p[atch]'
declare -i INDEX
case "${1}" in
    0|ma*) INDEX=0 ;; # bump major version
    1|mi*) INDEX=1 ;; # bump minor version
     2|p*) INDEX=2 ;;     # bump patch version
esac

# Split the current version into three parts
set -o noglob
IFS="." ARR=(${MVERS})
let NEWVALUE=${ARR[${INDEX}]}+1
ARR[${INDEX}]=${NEWVALUE}

# Zero out parts after the one being bumped
while
    let INDEX+=1
    ((INDEX < 3))
do
    ARR[${INDEX}]=0
done

# Apply new version
NVERS="${ARR[0]}.${ARR[1]}.${ARR[2]}"
printf "%s\n" "-- ${MVERS} --> ${NVERS}"
agvtool new-marketing-version "${NVERS}" > /dev/null 2>&1
