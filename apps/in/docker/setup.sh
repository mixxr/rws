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
for type in "${TYPES[@]}"; do
  echo "Processing TYPE=$type"

  case "$type" in

    # --------------------
    # DETAILS / TICKERS
    # --------------------
    details|tickers)
      for isin in "${ISINS[@]}"; do
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
        echo "Written $DEST"
      done

      # trigger downstream job
      gcloud run jobs execute "${type}-wc-s1-job" \
        --region europe-west1 
      ;;

    # --------------------
    # QUOTES
    # --------------------
    quotes)
      TMP_FILE=$(mktemp)

      for isin in "${ISINS[@]}"; do
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

      echo "Updated $DEST"
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