#!/bin/bash
# set -euo pipefail
set -u 

# usage:
# ISSUER=leonteq TYPE_LIST="quotes" ISIN_LIST="CH1525083577|CH1550421528"

# ------------------------
# ISSUER normalizer
# ------------------------
# name=$(normalize_name "BNP Paribas")
# echo "$name"   # bnp

normalize_name() {
    local input="$1"

    # lowercase
    input="${input,,}"

    # remove non‑alphanumeric except spaces
    input="$(printf "%s" "$input" | tr -cd 'a-z0-9 ')"

    # trim leading/trailing spaces
    input="$(printf "%s" "$input" | sed 's/^ *//; s/ *$//')"

    # extract first token
    set -- $input
    printf "%s\n" "$1"
}
echo "----------------------------------------"
echo "Configuration:"
echo "ISSUER    =$ISSUER"
echo "ISIN_LIST =${ISIN_LIST}"
echo "TYPE_LIST =${TYPE_LIST}"
# ------------------------
# INPUT
# ------------------------
ISIN_LIST_PAR="${ISIN_LIST:-$(./make_isin_list_var_str.sh)}" || {
    echo "ERROR: make_isin_list_var_str.sh failed and ISIN_LIST not set" >&2
    exit 1
}
IFS='|' read -ra ISINS <<< "${ISIN_LIST_PAR}"

TYPE_LIST_PAR="${TYPE_LIST:-$(cat ./type_list.txt)}" || {
    echo "ERROR: type_list.txt missing and TYPE_LIST not set" >&2
    exit 1
}
TYPE_LIST="${TYPE_LIST_PAR}"
IFS='|' read -ra TYPES <<< "${TYPE_LIST}"

#ISSUER_PAR="${ISSUER:-$(cat ./issuer.txt)}"
ISSUER_PAR="${ISSUER:-$(cat issuer.txt)}" || {
    echo "ERROR: issuer.txt missing and ISSUER not set" >&2
    exit 1
}
ISSUER=$(normalize_name "$ISSUER_PAR")

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

# -----------------------
# CONFIG 
# -----------------------
echo "- Calculated:
ISSUER=$ISSUER
FORMAT=$FORMAT"
echo "ISINS=${ISINS[*]}"
echo "TYPES=${TYPES[*]}"
echo "----------------------------------------"

./cp.sh $ISSUER quotes down
./rm.sh $ISIN_LIST $ISSUER quotes
./cp.sh $ISSUER quotes up