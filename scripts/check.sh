#!/bin/sh
set -e

PRO="$(ls -1 *.kicad_pro)"
echo "Detected project: $PRO"

BASE="$(basename "${PRO%.kicad_pro}")"
SCH="${BASE}.kicad_sch"
PCB="${BASE}.kicad_pcb"

[ -f "$PRO" -a -f "$SCH" -a -f "$PCB" ] || die "Unable to detect files: $PRO $SCH $PCB"

RET=0

echo "::group::ERC"
if ! kicad-cli sch erc \
 -o erc.rpt \
 --format report \
 --severity-error \
 --exit-code-violations \
 "$SCH"
then
    RET=1
    echo "::error::ERC failure"
fi

echo "==== ERC Result"
grep -i error -B1 -A4 erc.rpt
echo
echo "::endgroup::"

echo "::group::DRC"
if ! kicad-cli pcb drc \
 -o drc.rpt \
 --format report \
 --severity-error \
 --exit-code-violations \
 "$PCB"
then
    RET=1
    echo "::error::DRC failure"
fi

echo "==== DRC Result"
grep -i error -B1 -A4 drc.rpt
echo
echo "::endgroup::"

exit $RET
