#!/bin/bash

set -e

readonly pcbFile="youdbetterrun.kicad_pcb"
readonly schFile="youdbetterrun.kicad_sch"
readonly revision="RevC"
readonly outputFolder="$(pwd)/fabrication artifacts ${revision}"
readonly projectName="YoudBetterRun"

figlet -w 300 Check for TODOs

output="$(grep -r --color=always --exclude-dir=.git --exclude-dir=.kiri --exclude=generate_artifacts.sh TODO . | true)"

if [[ "" != "${output}" ]]
then
	echo "${output}"
	exit 1
fi

figlet -w 300 Electrical Rule Check

kicad-cli sch erc \
	--exit-code-violations \
	"${schFile}"

figlet -w 300 Design Rule Check

kicad-cli pcb drc \
	--schematic-parity \
	--exit-code-violations \
	"${pcbFile}"

figlet -w 300 Generate Gerber files

readonly gerberFolder="${outputFolder}/gerbers/"
readonly gerberZip="${projectName}_Gerbers_${revision}.zip"
mkdir --parents "${gerberFolder}"
rm --force "${gerberFolder}/"*
rm --force "${outputFolder}/gerbers.zip"

kicad-cli pcb export drill \
	--generate-map \
	--map-format gerberx2 \
	--excellon-separate-th \
	--output "${gerberFolder}" \
	"${pcbFile}"

kicad-cli pcb export gerbers \
	--no-protel-ext \
	--layers F.Cu,In1.Cu,In2.Cu,In3.Cu,In4.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts,F.Fab,B.Fab \
	--output "${gerberFolder}" \
	"${pcbFile}"

# figlet -w 300 Generate Bill of Materials

# kicad-cli sch export bom \
# 	--ref-range-delimiter '' \
# 	--preset BOM \
# 	--output "${outputFolder}/${projectName}_BOM.csv" \
# 	"${schFile}"

# figlet -w 300 Generate position files

# kicad-cli pcb export pos \
# 	--side both \
# 	--exclude-dnp \
# 	--units "mm" \
# 	--output "${outputFolder}/${projectName}_ComponentPlacement.pos" \
# 	"${pcbFile}"

# figlet -w 300 Generate assembly plan

# kicad-cli pcb export pdf \
# 	--theme _builtin_classic \
# 	--output "assembly_plan/${projectName}_TopAssembly.pdf" \
# 	--layers F.Fab,F.Silkscreen,Edge.Cuts \
# 	--include-border-title \
# 	"${pcbFile}"

# kicad-cli pcb export pdf \
# 	--theme _builtin_classic \
# 	--mirror \
# 	--output "assembly_plan/${projectName}_BottomAssembly.pdf" \
# 	--layers B.Fab,B.Silkscreen,Edge.Cuts \
# 	--include-border-title \
# 	"${pcbFile}"

# mkdir --parents assembly_plan/drills
# rm --force assembly_plan/drills/*
# kicad-cli pcb export drill \
# 	--generate-map \
# 	--map-format pdf \
# 	--excellon-separate-th \
# 	--output "assembly_plan/drills/" \
# 	"${pcbFile}"

# for f in assembly_plan/drills/*.pdf; do
# 	pdfcrop "${f}"
# done

rm --force "${outputFolder}/${gerberZip}"
(cd "${gerberFolder}" && zip "../${gerberZip}" *)
