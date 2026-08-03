#!/bin/bash
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <input_file> <output_file> <col1> [col2]..."
    exit 1
fi
csv_file="$1"
out_file="$2"
shift 2

all_cols="$@"

awk -v want="$all_cols" '
BEGIN {
    FS=";"
    split(want, W, " ")
}
NR==1 {
    # Map header names to column numbers
    for (i=1; i<=NF; i++) H[$i] = i

    # Build ordered list of column positions
    idx = 0
    for (i=1; i<=length(W); i++) {
        colname = W[i]
        idx++
        C[idx] = (colname in H ? H[colname] : -1)
    }
}
{
    out = ""
    for (i=1; i<=length(C); i++) {
        pos = C[i]
        val = (pos > 0 ? $pos : "")
        out = out (i==1 ? "" : FS) val
    }
    print out
}
' "$csv_file" > $out_file
