#!/bin/bash
# if [[ -d $1 ]]; then
#     for f in "$1"/* ; do
#         echo "Pre-process $f"
#         sed -i -E 's/([0-9]+),([0-9]+) EUR/\1.\2 EUR/g' "$f"
#     done
# else
#     echo "Pre-process $1"
#     sed -i -E 's/([0-9]+),([0-9]+) EUR/\1.\2 EUR/g' "$1"
# fi