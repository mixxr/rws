#!/bin/bash
# set -euo pipefail
set -u 

# usage:
# ISSUER=leonteq TYPE_LIST="details|quotes|issuer" ISIN_LIST="CH1525083577|CH1550421528" START_JOBS="details|issuer" BUCKET="gs://rws-data" ./setup.sh

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

IFS='|' read -ra START_TYPES <<< "${START_JOBS:-}"

# check if START_JOBS is set and not empty, if it is set then check if it is details or issuer, if not then exit with error
for t in "${START_TYPES[@]}"; do
  if [[ "$t" != "details" && "$t" != "issuer" ]]; then
    echo "Error: START_JOBS must be a comma separated list of details and issuer. Got: $START_JOBS"
    exit 1
  fi
done

# check BUCKET env var is set, if not use default value gs://rws-data
BUCKET="${BUCKET:-gs://rws-data}"

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

# ------------------------
# CONFIRMATION / SILENT MODE
# ------------------------

SILENT_MODE="${SILENT_MODE:-false}"

echo "----------------------------------------"
echo "Configuration:"
echo "ISSUER=$ISSUER"
echo "BUCKET=$BUCKET"
echo "ISIN_LIST    = ${ISIN_LIST_PAR}"
echo "TYPE_LIST    = ${TYPE_LIST}"
echo "START_JOBS   = ${START_JOBS:-<empty>}"
echo "SILENT_MODE  = ${SILENT_MODE}"
echo "- Calculated:
FORMAT=$FORMAT"
echo "ISINS=${ISINS[*]}"
echo "TYPES=${TYPES[*]}"

echo "----------------------------------------"

if [[ "$SILENT_MODE" != "true" ]]; then
  read -p "Continue? [y/N]: " answer

  case "$answer" in
    [yY]|[yY][eE][sS])
      echo "Proceeding..."
      ;;
    *)
      echo "Aborted by user."
      exit 1
      ;;
  esac
else
  echo "Silent mode enabled → proceeding without confirmation"
fi

# ------------------------
# Job trigger helper
# ------------------------
should_start_job() {
  local type=$1

  for t in "${START_TYPES[@]}"; do
    [[ "$t" == "$type" ]] && return 0
  done

  return 1
}

# ------------------------
# URL builder
# ------------------------

    # Issuer all:
    # url="https://www.certificatiederivati.it/db_bs_scheda_certificato.asp?isin=${isin}"
    # Details BNP
    # url="https://kid.bnpparibas.com/${isin}-IT.pdf"
    # Details KID Leonteq
    # url="https://structuredproducts-ch.leonteq.com/isin/${isin}/kid/it"
build_url() {
  local type=$1
  local isin=$2

  case "$type" in
    quotes)
      case "$ISSUER" in
        bnp) echo "https://investimenti.bnpparibas.it/product-details/${isin}" ;;
        leonteq) echo "https://certificati.leonteq.com/api/product-model/details/isin/${isin}" ;;
        marex) echo "https://certificati.marex.com/it/products/${isin}" ;;
        vontobel) echo "https://markets.vontobel.com/it-it/prodotti/investment/multi-cash-collect-certificate-con-barriera/${isin}" ;;
        # bnp) echo "https://live.euronext.com/it/ajax/getOrderBook/${isin}-ETLX" ;;
        # leonteq) echo "https://live.euronext.com/it/ajax/getOrderBook/${isin}-ETLX" ;;
        # marex) echo "https://live.euronext.com/it/ajax/getOrderBook/${isin}-ETLX" ;; 
        unicredit) echo "https://live.euronext.com/it/ajax/getOrderBook/${isin}-SEDX" ;;
        *) echo "https://live.euronext.com/it/ajax/getOrderBook/${isin}-ETLX" ;;
      esac
      ;;
    details)
      case "$ISSUER" in
        bnp) echo "https://kid.bnpparibas.com/${isin}-IT.pdf" ;;
        leonteq) echo "https://structuredproducts-ch.leonteq.com/isin/${isin}/kid/it" ;;
        marex) echo "https://certificati.marex.com/it/products/${isin}" ;;
        vontobel) echo "https://derinet.vontobel.ch/api/kid?isin=${isin}&language=it" ;;
        mediobanca) echo "https://certificates.mediobanca.com/it/certificati/${isin}" ;;
      esac
      ;;
    issuer)
      case "$ISSUER" in
        *) echo "https://www.certificatiederivati.it/db_bs_scheda_certificato.asp?isin=${isin}" ;;
      esac
      ;;
  esac
}

validate_isin() {
  local isin="$1"

  # Must be exactly 12 chars: 2 letters + 9 alphanumerics + 1 digit
  [[ "$isin" =~ ^[A-Z]{2}[A-Z0-9]{9}[0-9]$ ]] || return 1

  # Expand letters to numbers (A=10 … Z=35)
  local expanded=""
  for ((i=0; i<${#isin}; i++)); do
    c="${isin:$i:1}"
    if [[ "$c" =~ [A-Z] ]]; then
      expanded+=$((10 + $(printf "%d" "'$c") - 65))
    else
      expanded+="$c"
    fi
  done

  # Apply Luhn mod‑10
  local sum=0
  local rev=$(echo "$expanded" | rev)
  for ((i=0; i<${#rev}; i++)); do
    d="${rev:$i:1}"
    if (( i % 2 == 1 )); then
      d=$((d * 2))
      (( d > 9 )) && d=$((d - 9))
    fi
    sum=$((sum + d))
  done

  (( sum % 10 == 0 ))
}

declare -A RANGE_MAP=(
  ["bnp_details"]="9,420"
  ["marex_details"]="5,490"
  ["vontobel_details"]="5,490"
  ["leonteq_details"]="5,500"
  ["mediobanca_details"]="5,500"
  ["marex_issuer"]="5,35"
  ["bnp_issuer"]="5,35"
  ["vontobel_issuer"]="5,35"
  ["leonteq_issuer"]="5,500"
  ["mediobanca_issuer"]="5,500"
)

# ------------------------
# MAIN LOOP
# ------------------------
echo "==== Processing ISSUER=$ISSUER"

for type in "${TYPES[@]}"; do
  echo "== Processing TYPE=$type"

  case "$type" in

    # --------------------
    # DETAILS / issuer
    # --------------------
    details|issuer)
      ISIN_PROCESSED=0
      
      echo "Total ISINs to process: ${#ISINS[@]}"
      for isin in "${ISINS[@]}"; do
        if ! validate_isin "$isin"; then
          echo "WARNING: Invalid ISIN for $ISSUER: $isin. Skipping..."
          continue
        fi
        ((ISIN_PROCESSED++))
        url=$(build_url "$type" "$isin")

        key="${ISSUER}_${type}"
        range="${RANGE_MAP[$key]:-1,500}"

        startline="${range%,*}"
        endline="${range#*,}"

        content="${url},${isin}.md,${startline},${endline}"

        tmp_local=$(mktemp)
        echo "$content" > "$tmp_local"

        DEST="${BUCKET}/${type}/jobs/1/${isin}.csv"

        # atomic write
        gcloud storage cp "$tmp_local" "$DEST"
        #gcloud storage mv "${DEST}.tmp" "$DEST"

        rm "$tmp_local"
        echo "Completed $type $isin"
      done
      echo "Total ISINs processed: $ISIN_PROCESSED"
      # trigger downstream job
      if should_start_job "$type"; then
        echo "Starting downstream job ${type}-wc-s1-job"

        gcloud run jobs execute "${type}-wc-s1-job" --region europe-west1 
      else
        echo "Skipping job auto-start for $type"
      fi
      ;;

    # --------------------
    # QUOTES
    # --------------------
    quotes)  
      ISIN_PROCESSED=0
      echo "Total ISINs to process: ${#ISINS[@]}"
      # if total ISINs is 0, then exit with warning
      if [ ${#ISINS[@]} -eq 0 ]; then
        echo "WARNING: No ISINs to process for quotes. Skipping..."
        continue
      fi

      DEST="${BUCKET}/quotes/config/${ISSUER}.urls.${FORMAT}"

      EXISTING=$(mktemp)
      TMP_FILE=$(mktemp)

      if gcloud storage ls "$DEST" >/dev/null 2>&1; then
        gcloud storage cat "$DEST" > "$EXISTING"
      fi

      for isin in "${ISINS[@]}"; do
        if ! validate_isin "$isin"; then
          echo "WARNING: Invalid ISIN for $ISSUER: $isin. Skipping..."
          continue
        fi
        # Check if ISIN exists anywhere in the file
        if [[ -s "$EXISTING" ]] && grep -q "$isin" "$EXISTING"; then
          echo "Skipping $isin (already present in $DEST)"
          continue
        fi
        ((ISIN_PROCESSED++))
        url=$(build_url "quotes" "$isin")
        echo "${url},${isin}.${FORMAT}" >> "$TMP_FILE"
      done

      # if TEMP_FILE is empty, then exit with warning
      if [ ! -s "$TMP_FILE" ]; then
        echo "WARNING: No new ISINs to process for quotes. Skipping..."
      else
        cat "$TMP_FILE" >> "$EXISTING"
        gcloud storage cp "$EXISTING" "$DEST"
      fi
      
      rm "$TMP_FILE" "$EXISTING"

      echo "Completed quotes: ISINs processed $ISIN_PROCESSED, check $DEST"
      ;;

    # --------------------
    # ERROR
    # --------------------
    *)
      echo "Unknown TYPE: $type"
      exit 1
      ;;
  esac

done

echo "==== INitiator completed."
