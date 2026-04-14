#!/bin/bash
echo "==== Setup running... ====: $1"

FULL_PATH="$(cd "$(dirname "$1")" && pwd)"
echo $FULL_PATH

# Rimuove tutto ciò che sta prima di "apps/" incluso quest'ultimo
temp="${FULL_PATH##*/apps/}"
echo "Temp: $temp"

# Prende tutto ciò che sta prima dello slash successivo
TYPE="${temp%%/*}"
APPNAME="${temp##*/}"

echo "TYPE: $TYPE"
echo "==== Setup completed ===="