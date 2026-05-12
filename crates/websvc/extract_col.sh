#!/usr/bin/env bash

INPUT_FILE=$1
OUTPUT_FILE=$2

awk -F';' 'NR>1 {print $1}' "$INPUT_FILE" | sort -u > "$OUTPUT_FILE"