#!/bin/bash
echo "Replaces all occurrences of $2 with $3"
# test if the correct number of arguments is provided
if [ "$#" -lt 3 ]; then
    echo "Error: Not enough arguments provided."
    echo "usage: $0 input.csv search_string replace_string [output.csv]"
    exit 1
fi
input="$1"
search="$2"
replace="$3"
output="${4:-replaced.csv}"

sed "s|$search|$replace|g" "$input" > "$output"

echo "Saved to: $output"