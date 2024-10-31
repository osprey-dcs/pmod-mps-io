#!/bin/sh
set -e -x

OUT="$1"

TDIR=`mktemp -d`
trap 'rm -rf "$TDIR"' EXIT INT QUIT TERM

# makepdf input name layers
makepdf() {
    inp="$1"
    name="$2"
    layers="$3"
    kicad-cli pcb export pdf \
     -D LAYER="$name" \
     --drill-shape-opt 2 \
     --include-border-title \
     -l "$layers" \
     -o "$TDIR/$name-layer.pdf" \
     "$inp"
}

# Pwr3.Cu -> In3.Cu
# cf.
# https://gitlab.com/kicad/code/kicad/-/blob/master/include/layer_ids.h

makepdf Quartz.kicad_pcb 1Front 'F.Cu,F.Silkscreen,Edge.Cuts'

makepdf Quartz.kicad_pcb 2Gnd 'In1.Cu,Edge.Cuts'

makepdf Quartz.kicad_pcb 3Pwr 'In2.Cu,Edge.Cuts'

makepdf Quartz.kicad_pcb 4In 'In3.Cu,Edge.Cuts'

makepdf Quartz.kicad_pcb 5Gnd 'In4.Cu,Edge.Cuts'

makepdf Quartz.kicad_pcb 6Bot 'B.Cu,B.Silkscreen,Edge.Cuts'

pdfunite "$TDIR"/*-layer.pdf "$OUT"
