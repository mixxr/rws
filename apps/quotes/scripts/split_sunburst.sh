#!/bin/bash

input="${1:-sunburst_sectors.csv}"
OUTPUT_FOLDER="${2:-./sectors}"
DELIM=","

echo "Reading $input... > $OUTPUT_FOLDER/"

# Trova tutte le radici (id==labels e parents vuoto)
roots=()
while IFS="${DELIM}" read -r id label parent; do
    [[ "$id" == "$label" && -z "$parent" ]] && roots+=("$id")
done < "$input"

echo "Found roots: ${roots[*]}"

mkdir -p "$OUTPUT_FOLDER"

# Per ogni root crea un CSV
for root in "${roots[@]}"; do
    outfile="${root}.csv"
    echo "id${DELIM}labels${DELIM}parents" > "$OUTPUT_FOLDER/$outfile"

    # Aggiungi tutte le righe che appartengono a questo root
    while IFS="${DELIM}" read -r id label parent; do
        # root: id==label and no parent
        if [[ "$id" == "$label" && -z "$parent" && "$id" == "$root" ]]; then
            echo "$id${DELIM}$label${DELIM}$parent" >> "$OUTPUT_FOLDER/$outfile"
            continue
        fi

        # livelli successivi: parent termina con il root
        if [[ "$parent" == *"$root" ]]; then
            echo "$id${DELIM}$label${DELIM}$parent" >> "$OUTPUT_FOLDER/$outfile"
        fi

    done < "$input"

    echo "Created $OUTPUT_FOLDER/$outfile"
done
