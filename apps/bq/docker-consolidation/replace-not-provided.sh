#!/bin/bash
echo "Replaces various forms of 'not provided' with 'N/A' for better normalization"

input="$1"
output="${2:-normalized.csv}"

awk -F';' -v OFS=';' '

function trim(s) {
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    return s
}

{
    for (i = 1; i <= NF; i++) {

        value = trim($i)
        upper = toupper(value)

        # normalize unwanted values
        if (value == "\"\"" ||
            value == "" ||
            upper == "NULL" ||
            upper == "NONE" ||
            upper == "UNKNOWN" ||
            upper == "NOT PROVIDED" ||
            upper == "NOT PROVID" ||
            upper  ~  /DOES NOT CONTAIN/) {

            $i = "N/A"
        }
        else {
            $i = value
        }
    }

    print
}

' "$input" > "$output"

echo "Saved to: $output"