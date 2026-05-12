#!/usr/bin/env bash
echo "extract col#1 from input file $1 and save the col#1 in output file $2"
INPUT_FILE=$1
OUTPUT_FILE=$2

awk -F';' 'NR>1 {print $1}' "$INPUT_FILE" | sort -u > "$OUTPUT_FILE"