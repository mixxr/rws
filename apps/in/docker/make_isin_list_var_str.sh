#!/usr/bin/env bash

INPUT_FILE=$1

tr '\n' '|' < "$INPUT_FILE" | sed 's/|$//'