#!/bin/bash
set -euo pipefail

# ------------------------
# INPUT
# ------------------------
IFS='|' read -ra ISINS <<< "${ISIN_LIST}"
IFS='|' read -ra TYPES <<< "${TYPE_LIST}"
ISSUER="${ISSUER}"

# check BUCKET env var is set, if not use default value gs://rws-data
BUCKET="${BUCKET:-gs://rws-data}"

echo "ISSUER=$ISSUER"
echo "ISINS=${ISINS[*]}"
echo "TYPES=${TYPES[*]}"

# ------------------------
# FORMAT MAP (future-proof)
# ------------------------
declare -A FORMAT_MAP=(
  [leonteq]="json"
  [bnp]="md"
  [marex]="md"
  [vontobel]="md"
)

FORMAT="${FORMAT_MAP[$ISSUER]:-md}"

# ------------------------
# Job trigger helper
# ------------------------
IFS='|' read -ra START_TYPES <<< "${START_JOBS:-}"
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

    # Tickers all
    # url="https://www.certificatiederivati.it/db_bs_scheda_certificato.asp?isin=${isin}"
    # Details BNP
    # url="https://kid.bnpparibas.com/${isin}-IT.pdf"
    # Details KID Leonteq
    # url="https://structuredproducts-ch.leonteq.com/isin/${isin}/kid/it"
build_url() {
  local type=$1
  local isin=$2

  case "$type" in
    details)
      case "$ISSUER" in
        bnp) echo "https://kid.bnpparibas.com/${isin}-IT.pdf" ;;
        leonteq) echo "https://structuredproducts-ch.leonteq.com/isin/${isin}/kid/it" ;;
        marex) echo "https://fp.marex.com/file/${isin}/186886/WSD%20Generated%20File" ;;
        vontobel) echo "https://derinet.vontobel.ch/api/kid?isin=${isin}&language=it" ;;
      esac
      ;;
    tickers)
      echo "https://www.certificatiederivati.it/db_bs_scheda_certificato.asp?isin=${isin}"
      ;;
  esac
}

validate_isin() {
  local isin=$1

  case "$ISSUER" in
    marex)
      [[ "$isin" == IT* ]] || return 1
      ;;
    bnp)
      [[ "$isin" == NL* || "$isin" == XS* ]] || return 1
      ;;
    leonteq)
      [[ "$isin" == CH* ]] || return 1
      ;;
    vontobel)
      [[ "$isin" == DE* ]] || return 1
      ;;
    *)
      return 0  # allow unknown issuers
      ;;
  esac
}

declare -A RANGE_MAP=(
  ["bnp_details"]="9,320"
  ["marex_details"]="5,490"
  ["vontobel_details"]="5,490"
  ["leonteq_details"]="5,500"
  ["marex_tickers"]="5,35"
  ["bnp_tickers"]="5,35"
  ["vontobel_tickers"]="5,35"
  ["leonteq_tickers"]="5,35"
)

# ------------------------
# MAIN LOOP
# ------------------------
echo "==== Processing ISSUER=$ISSUER"

for type in "${TYPES[@]}"; do
  echo "Processing TYPE=$type"

  case "$type" in

    # --------------------
    # DETAILS / TICKERS
    # --------------------
    details|tickers)
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
        echo "Completed $type $isin: written $DEST"
      done
      echo "Total ISINs processed: $ISIN_PROCESSED"
      # trigger downstream job
      if should_start_job "$type"; then
        echo "Starting downstream job ${type}-wc-s1-job"

        gcloud run jobs execute "${type}-wc-s1-job" --region europe-west1 
      else
        echo "Skipping job start for TYPE=$type"
      fi
      ;;

    # --------------------
    # QUOTES
    # --------------------
    quotes)
      TMP_FILE=$(mktemp)
      ISIN_PROCESSED=0
      echo "Total ISINs to process: ${#ISINS[@]}"
      for isin in "${ISINS[@]}"; do
        if ! validate_isin "$isin"; then
          echo "WARNING: Invalid ISIN for $ISSUER: $isin. Skipping..."
          continue
        fi
        ((ISIN_PROCESSED++))
        url=$(build_url "quotes" "$isin")
        echo "${url},${isin}.${FORMAT}" >> "$TMP_FILE"
      done

      DEST="${BUCKET}/quotes/config/${ISSUER}.urls.${FORMAT}"

      EXISTING=$(mktemp)

      if gcloud storage ls "$DEST" >/dev/null 2>&1; then
        gcloud storage cat "$DEST" > "$EXISTING"
      fi

      cat "$TMP_FILE" >> "$EXISTING"

      gcloud storage cp "$EXISTING" "$DEST"

      rm "$TMP_FILE" "$EXISTING"

      echo "Completed quotes: ISINs processed $ISIN_PROCESSED, updated $DEST"
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

echo "INitiator completed."