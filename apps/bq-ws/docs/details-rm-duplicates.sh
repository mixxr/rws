#!/bin/bash
echo "Remove duplicates based on ISIN"
awk -F';' '!seen[$1]++' input.csv > output.csv