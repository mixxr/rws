#!/usr/bin/env bash
echo "compares 2 input files $1 $2 and prints the rows that exist in file $1 but not in file $2"
FILE1=$1
FILE2=$2

# ensure sorted input
sort "$FILE1" > /tmp/f1.sorted
sort "$FILE2" > /tmp/f2.sorted

# show only ISINs in file1 but NOT in file2
comm -23 /tmp/f1.sorted /tmp/f2.sorted