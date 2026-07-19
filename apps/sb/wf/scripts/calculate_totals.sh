#!/usr/bin/env bash
INPUT="${1:-./_work/sunburst_sectors.csv}"
QUOTES_FOLDER="${2:-./_quotes}"
output_file="./_sunburst/ALL.csv"
mkdir -p _sectors

declare -A stock_total
declare -A sector_total
declare -A industry_total
declare -A root_total

declare -A sector_count
declare -A industry_count
declare -A root_count

declare -A sector_avg
declare -A industry_avg
declare -A root_avg

add() {
    jq -n "($1 + $2) * 100 | round / 100"
}


while IFS=',' read -r id labels parents; do
    [[ "$id" == "id" ]] && continue
    
    # tmp="${id//__/|}"     # replace __ with |
    IFS='|' read -ra parts <<< "$id"
    
    # Must be exactly 4 levels
    if [[ ${#parts[@]} -ne 4 ]]; then
        continue
    fi

    symbol="${parts[0]}"
    sector="${parts[1]}"
    industry="${parts[2]}"
    root="${parts[3]}"

    # Must not be empty
    if [[ -z "$symbol" || -z "$sector" || -z "$industry" || -z "$root" ]]; then
        continue
    fi
    
    json_file="$QUOTES_FOLDER/$symbol.json"
    [[ ! -f "$json_file" ]] && continue
    # echo "Processing $symbol $sector $industry $root...$json_file"

    change=$(jq -r '.regularMarketChangePercent // empty' "$json_file")
    change=$(jq -n "(${change:-0} * 100 | round) / 100")

    # echo $symbol $change
    [[ -z "$change" ]] && continue

    # Stock changes
    key_stock="$symbol|$sector|$industry|$root"
    stock_total["$key_stock"]=$change

    # Sector totals
    key_sector="$sector|$industry|$root"
    sector_total["$key_sector"]=$(add "${sector_total[$key_sector]:-0}" "$change")
    sector_count["$key_sector"]=$((sector_count[$key_sector] + 1))

    # Industry totals
    key_industry="$industry|$root"
    industry_total["$key_industry"]=$(add "${industry_total[$key_industry]:-0}" "$change")
    industry_count["$key_industry"]=$((industry_count[$key_industry] + 1))

    # Root total
    root_total["$root"]=$(add "${root_total[$root]:-0}" "$change")
    root_count["$root"]=$((root_count[$root] + 1))

done < "$INPUT"

for k in "${!stock_total[@]}"; do
    echo "$k" "${stock_total[$k]}"
done

echo "-sec....."
for k in "${!sector_total[@]}"; do
    # IFS='|' read -r sector industry <<< "$k"
    avg=$(jq -n "(${sector_total[$k]} / ${sector_count[$k]}) * 100 | round / 100")
    sector_avg["$k"]=$avg
    # printf "%s → %s: total=%s avg=%s\n" "$sector" "$industry" "${sector_total[$k]}" "$avg"
    echo "$k ${sector_total[$k]} ${sector_count[$k]} avg: $avg"
done
echo "-ind....."

for k in "${!industry_total[@]}"; do
    # IFS='|' read -r sector industry root <<< "$k"
    avg=$(jq -n "(${industry_total[$k]} / ${industry_count[$k]}) * 100 | round / 100")
    industry_avg["$k"]=$avg
    # printf "%s → %s → %s: total=%s avg=%s\n" \
    #     "$sector" "$industry" "$root" "${industry_total[$k]}" "$avg"
   echo "$k ${industry_total[$k]} ${industry_count[$k]} avg: $avg"
done
echo "-root....."
for k in "${!root_total[@]}"; do
    # IFS='|' read -r root <<< "$k"
    avg=$(jq -n "(${root_total[$k]} / ${root_count[$k]}) * 100 | round / 100")
    root_avg["$k"]=$avg
    echo "$k ${root_total[$k]} ${root_count[$k]} avg: $avg"
done

echo "ids,labels,parents,values,counts,avgs" > $output_file
while IFS=',' read -r id label parent; do
    [[ "$id" == "id" ]] && continue
    value="${root_total[$id]}""${sector_total[$id]}""${industry_total[$id]}""${stock_total[$id]}"
    [[ "$value" == "" ]] && continue
    count="${root_count[$id]:-${sector_count[$id]:-${industry_count[$id]:-1}}}"
    avg="${root_avg[$id]}""${sector_avg[$id]}""${industry_avg[$id]}""${stock_total[$id]}"
    
    echo "$id,$label,$parent,$value,$count,$avg" >> $output_file

done < "$INPUT"