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

makepdf mps-io.kicad_pcb 1Front 'F.Cu,F.Silkscreen,Edge.Cuts'

makepdf mps-io.kicad_pcb 2Gnd 'In1.Cu,Edge.Cuts'

makepdf mps-io.kicad_pcb 3Gnd 'In2.Cu,Edge.Cuts'

makepdf mps-io.kicad_pcb 4Bot 'B.Cu,B.Silkscreen,Edge.Cuts'

pdfunite "$TDIR"/*-layer.pdf "$OUT"
