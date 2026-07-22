#!/bin/bash

input="${1:-./_work/stock_index_adjusted.csv}"
output="${2:-./_work/sunburst_sectors.csv}"
ID_SEP="|"
DELIM=";"

echo "Reading $input... > $output"

declare -A exchanges
declare -A industries
declare -A sectors
declare -A tickers

normalize_exchange() {
    local ex="$1"
    ex="${ex%% *}"     # rimuove dopo spazio
    ex="${ex%%(*}"     # rimuove dopo parentesi
    echo "${ex^^}"     # uppercase
}

sanitize() {
    local s="$1"
    s="${s//,/}"   # rimuove virgole
    s="${s//;/}"   # rimuove punti e virgola
    s="${s//:/}"   # rimuove due punti
    s="$(echo "$s" | tr -s ' ')"   # squeeze repeated spaces
    echo "$s"
}

{
    read -r header

    while IFS="${DELIM}" read -r ticker name exchange isin industry sector; do

        ex_norm=$(normalize_exchange "$exchange")

        # ❗ Sanifica industry e sector
        industry_clean=$(sanitize "$industry")
        sector_clean=$(sanitize "$sector")

        # Filtri
        [[ "$industry_clean" == "Not specified" || "$industry_clean" == "N/A" ]] && continue
        [[ "$sector_clean" == "Not specified" || "$sector_clean" == "N/A" ]] && continue
        [[ "$ex_norm" == "NOT" || "$ex_norm" == "N/A" ]] && continue

        # Livello 1: exchange
        exchanges["$ex_norm"]=1

        # Livello 2: industry-exchange
        ind_id="${industry_clean}${ID_SEP}${ex_norm}"
        industries["$ind_id"]="$industry_clean${DELIM}$ex_norm"

        # Livello 3: sector-industry-exchange
        sec_parent="${industry_clean}${ID_SEP}${ex_norm}"
        sec_id="${sector_clean}${ID_SEP}${sec_parent}"
        sectors["$sec_id"]="$sector_clean${DELIM}$sec_parent"

        # ⭐ Livello 4: ticker-sector-industry-exchange
        tick_id="${ticker}${ID_SEP}${sec_id}"
        tickers["$tick_id"]="$ticker${DELIM}$sec_id"

    done
} < "$input"

{
    echo "ids${DELIM}labels${DELIM}parents"

    # Livello 1
    for ex in "${!exchanges[@]}"; do
        echo "$ex${DELIM}$ex${DELIM}"
    done

    # Livello 2
    for ind in "${!industries[@]}"; do
        IFS="${DELIM}" read -r label parent <<< "${industries[$ind]}"
        echo "$ind${DELIM}$label${DELIM}$parent"
    done

    # Livello 3
    for sec in "${!sectors[@]}"; do
        IFS="${DELIM}" read -r label parent <<< "${sectors[$sec]}"
        echo "$sec${DELIM}$label${DELIM}$parent"
    done

    # Livello 4
    for tk in "${!tickers[@]}"; do
        IFS="${DELIM}" read -r label parent <<< "${tickers[$tk]}"
        echo "$tk${DELIM}$label${DELIM}$parent"
    done
} > "$output"
