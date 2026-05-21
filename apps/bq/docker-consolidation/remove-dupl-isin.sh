#!/bin/bash
echo "Remove duplicates based on ISIN"
awk -F';' '!seen[$1]++' $1 > $2

