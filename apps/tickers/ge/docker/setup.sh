#!/bin/bash
echo "==== Setup running... ===="
TYPE="tickers"
STATUS="ge"
STATUS_TO="bq"
mntdir=${MOUNT_DIR:-.}/${TYPE}
bucket=${MOUNT_BUCKET}/${TYPE}
datetime=$(date -u +"%Y-%m-%dT%H-%M-%S")
MANIFEST="$mntdir/jobs/$STATUS_TO/$datetime.txt"

echo "Mount Dir: $mntdir -> $bucket"
echo "Manifest file: $MANIFEST"
#rm -f "$MANIFEST*"

echo "#!/bin/bash" > ./run.sh
echo "ERROR_COUNT=0" >> ./run.sh
for filepath in "$mntdir/jobs/$STATUS"/*.uri; do
  if [ -f "$filepath" ]; then
	  file="$(basename "$filepath")"
    isin="${file%%.*}"
    isin=${isin^^}
    echo "Processing $isin $filepath"
    # .uri files contain 1 line like "/data/certificates/input/DE000VG656A7.md"
	  read -r line < "$filepath"
    echo "geminicert -n $isin -i $line -o $mntdir/output -l $mntdir/config/models.csv -t $TYPE-only" >> ./run.sh
    echo "if [ \$? -eq 0 ]; then 
      mv $filepath $filepath.done 
      # a MANIFEST file contains N lines like "gs://bucket/tickers/output/DE000VG656A7-tickers.json"
      echo $bucket/output/$isin-$TYPE.json >> $MANIFEST
    else
      echo 'ERROR: $filepath'
      ((ERROR_COUNT++))
    fi" >> ./run.sh 
  fi
done
echo "echo "ERROR COUNTER: $ERROR_COUNT"
if [ \$ERROR_COUNT -gt 0 ]; then
  exit 2
fi" >> ./run.sh

if ! test -f ./run.sh; then
  echo "No execution to build."
  exit 1
fi
chmod +x ./run.sh
echo -e "Setup completed:\n $(cat ./run.sh)"
./run.sh
echo "==== Execution completed ===="
