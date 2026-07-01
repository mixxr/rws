#!/bin/bash
# usage: ./rm.sh <isin | sep list> <issuer> [quotes]

isin_list="$1"
ISSUER="$2"

# ------------------------
# FORMAT MAP (future-proof)
# ------------------------
declare -A FORMAT_MAP=(
  [leonteq]="json"
  [bnp]="md"
  [marex]="md"
  [vontobel]="md"
  [mediobanca]="md"
)

FORMAT="${FORMAT_MAP[$ISSUER]:-md}"
LDEST="${ISSUER}.urls.${FORMAT}"

grep -i -v -E "$isin_list" "$LDEST" > "${LDEST}.tmp" 
mv "${LDEST}.tmp" "$LDEST"
