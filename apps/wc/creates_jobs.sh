#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: provide start_line and end_line."
  echo "Info: Details, BNP KID PDF is 9 220"
  echo "Info: Tickers, BNP Web URL is 5 35"
  
  exit 1
fi

# Nome del file di input (puoi passarlo come argomento o lasciarlo fisso)
INPUT_FILE="isins.txt"

# Verifica se il file di input esiste
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Errore: Il file $INPUT_FILE non esiste."
    exit 1
fi
N=0
# Leggi il file riga per riga
while IFS= read -r isin || [[ -n "$isin" ]]; do
    # Rimuovi eventuali spazi bianchi o caratteri di ritorno a capo invisibili (Windows style)
    isin=$(echo "$isin" | tr -d '\r' | xargs)
    isin=${isin^^}

    # Salta la riga se è vuota
    if [[ -z "$isin" ]]; then
        continue
    fi

    # Definisci il nome del file di output
    OUTPUT_FILE="jobs/${isin}.csv"

    # Definisci il contenuto della riga
    # Formato: URL, ISIN.md, 5, 35
    # Details BNP
    # CONTENT="https://kid.bnpparibas.com/${isin}-IT.pdf,${isin}.md, $1, $2"
    # Tickers BNP
    CONTENT="https://www.certificatiederivati.it/db_bs_scheda_certificato.asp?isin=${isin},${isin}.md, $1, $2"

    # Crea il file CSV e scrivi il contenuto
    echo "$CONTENT" > "$OUTPUT_FILE"

    echo "Job creato: $OUTPUT_FILE"
    ((N++))

done < "$INPUT_FILE"

echo "Operazione completata! Jobs creati: $N"