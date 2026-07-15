#!/bin/bash

file1="$1"
file2="$2"

# Crea un dizionario ISIN → descrizione
declare -A MAP

while IFS=";" read -r isin desc; do
    MAP["$isin"]="$desc"
done < "$file1"

# Legge file2 e sostituisce <some text> con la descrizione corretta
while IFS=";" read -r isin name ask_old ask_new diff flag; do
    if [[ -n "${MAP[$isin]}" ]]; then
        name="${MAP[$isin]}"
    fi
    echo "$isin;$name;$ask_old;$ask_new;$diff;$flag"
done < "$file2"
