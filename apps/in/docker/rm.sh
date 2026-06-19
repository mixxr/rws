#!/bin/bash
# usage: ./rm.sh <isin | sep list> file

isin_list="$1"
file="$2"
grep -i -v -E "$isin_list" "$file" > "${file}.tmp" 
mv "${file}.tmp" "$file"
