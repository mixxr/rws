#!/usr/bin/env bash

INPUT_FILE=${1:-next_isins.txt}

tr '\n' '|' < "$INPUT_FILE" | sed 's/|$//'