#!/bin/bash
echo "Copy ticker from column 5 to 4 if column 4 is invalid"

input="$1"
fromCol="5"
toCol="4"
output="${2:-updated.csv}"

awk -F';' -v OFS=';' \
    -v from="$fromCol" \
    -v to="$toCol" '

function trim(s) {
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    return s
}

NR==1 {
    print
    next
}

{
    # Ensure columns exist
    if (from <= NF && to <= NF) {

        target = toupper(trim($(to)))

        if (target == "N/A" ||
        length(target) < 2 ||
        length(target) > 12) {
            $(to) = $(from)
        }
    }

    print
}
' "$input" > "$output"

echo "Saved to: $output"