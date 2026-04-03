#!/bin/bash
if [[ -d $1 ]]; then
    for f in "$1"/* ; do
        echo "Post-process $f"
        sed -i -E 's/\"([0-9]+),([0-9]+)\"/\"\1.\2\"/g' "$f"
    done
else
    echo "Post-process $1"
    sed -i -E 's/\"([0-9]+),([0-9]+)\"/\"\1.\2\"/g' "$1"
fi
