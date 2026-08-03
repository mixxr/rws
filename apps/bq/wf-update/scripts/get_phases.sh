#!/bin/bash
input_file="$1"
output_file="$2"

if [[ -z "$input_file" || -z "$output_file" ]]; then
    echo "Usage: $0 input.csv output.csv"
    exit 1
fi

if [[ ! -f "$input_file" ]]; then
    echo "Error: input file '$input_file' not found"
    exit 1
fi

echo "isin;phase" > "$output_file"

# Skip header and read rows
tail -n +2 "$input_file" | while IFS=";" read -r isin phase; do

    # Skip rimborsato
    if [[ "$phase" == "rimborsato" ]]; then
        continue
    fi

    url="https://www.certificatiederivati.it/db_bs_scheda_certificato.asp?isin=$isin"

    # Fetch page with headers to avoid bot detection
    html=$(curl -s \
        -H "Origin: https://www.certificatiederivati.it" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" \
        "$url")

    # Extract the FASE value
    new_phase=$(echo "$html" \
        | grep -o '<tr><th>FASE</th><td>[^<]*</td></tr>' \
        | sed -E 's/.*<td>([^<]+)<\/td>.*/\1/')
    
    # If extraction failed, skip
    if [[ -z "$new_phase" ]]; then
        continue
    fi

    # Compare
    if [[ "$new_phase" != "$phase" ]]; then
        echo "$isin;$new_phase" >> "$output_file"
    fi

    # Random wait 100–1000 ms
    sleep "$(awk -v min=0.1 -v max=1 'BEGIN{srand(); print min+rand()*(max-min)}')"

done

