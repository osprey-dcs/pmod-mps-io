#!/bin/sh
set -e -x

# Generate anufacture outputs from git commit
#
# TODO: generate d356
# TODO: generate drill report
# TODO: gerber output differences...

die() {
    echo "$1" >&2
    exit 1
}

ODIR="$1"
REF="${2:-HEAD}"

[ -n "$ODIR" ] || die "Usage: $0 </out/dir> [REF]"

TDIR=`mktemp -d`
trap 'rm -rf "$TDIR"' EXIT INT QUIT TERM

install -d "$TDIR/git"
install -d "$TDIR/out"
install -d "$TDIR/out/gerbers"

git archive "$REF" | tar -C "$TDIR/git" -x

PRO="$(ls -1 "$TDIR/git"/*.kicad_pro)"
echo "Detected project: $PRO"

BASE="$(basename "${PRO%.kicad_pro}")"
SCH="${BASE}.kicad_sch"
PCB="${BASE}.kicad_pcb"

[ -f "$PRO" -a -f "$SCH" -a -f "$PCB" ] || die "Unable to detect files: $PRO $SCH $PCB"

echo "Generate BOM"

kicad-cli sch export bom \
 -o "$TDIR/out"/BOM.csv \
 --preset "Grouped by MPN" \
 --ref-range-delimiter '' \
 "$SCH"

echo "Generate Gerbers"

# --layers "F.Cu,In1.Cu,In2.Cu,In3.Cu,In4.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,F.Courtyard,B.Courtyard,F.Fab,B.Fab" \
# --common-layers "Edge.Cuts" \

kicad-cli pcb export gerbers \
 -o "$TDIR/out/gerbers" \
 --board-plot-params \
 "$PCB"

echo "Generate Drill"

kicad-cli pcb export drill \
 -o "$TDIR/out/gerbers" \
 --map-format gerberx2 \
 --excellon-separate-th \
 --excellon-units in \
 "$PCB"

echo "Generate Placement"

kicad-cli pcb export pos \
 -o "$TDIR/out/gerbers/$BASE-top.pos" \
 --side front \
 --units mm \
 --use-drill-file-origin \
 "$PCB"

kicad-cli pcb export pos \
 -o "$TDIR/out/gerbers/$BASE-bottom.pos" \
 --side back \
 --units mm \
 --use-drill-file-origin \
 "$PCB"

echo "Generate"

kicad-cli pcb export ipc2581 \
 -o "$TDIR/out/$BASE.xml" \
 --bom-col-mfg-pn MPN \
 --bom-col-mfg Manufacturer \
 "$PCB"

echo "Saving"

install -d "$ODIR"

cp -r "$TDIR/out"/* "$ODIR/"
