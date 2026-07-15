#!/bin/bash

input="$1"
OUTPUT_FOLDER="${2:-./work}"

echo "Reading $input..."

# Trova tutte le radici (id==labels e parents vuoto)
roots=()
while IFS=";" read -r id label parent; do
    [[ "$id" == "$label" && -z "$parent" ]] && roots+=("$id")
done < "$input"

echo "Found roots: ${roots[*]}"

# Per ogni root crea un CSV
for root in "${roots[@]}"; do
    outfile="${root}.csv"
    echo "id;labels;parents" > "$OUTPUT_FOLDER/$outfile"

    # Aggiungi tutte le righe che appartengono a questo root
    while IFS=";" read -r id label parent; do
        # root: id==label and no parent
        if [[ "$id" == "$label" && -z "$parent" && "$id" == "$root" ]]; then
            echo "$id;$label;$parent" >> "$OUTPUT_FOLDER/$outfile"
            continue
        fi

        # livelli successivi: parent termina con il root
        if [[ "$parent" == *"$root" ]]; then
            echo "$id;$label;$parent" >> "$OUTPUT_FOLDER/$outfile"
        fi

    done < "$input"

    echo "Created $OUTPUT_FOLDER/$outfile"
done
