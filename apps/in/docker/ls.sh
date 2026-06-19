#!/bin/bash
# usage: ./ls.sh <isin | sep list> file

isin_list="$1"
file="$2"
grep -i -E "$isin_list" "$file" 
