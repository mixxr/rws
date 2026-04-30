#!/bin/bash
# use APPVERSION env var if set, otherwise 0.1
VERSION=${APPVERSION:-0.1}
echo "Gemini-cert Setup Script - Version $VERSION"
# it needs to be executed TYPE [issuer|details], STATUS (number, typically it is 1), MOUNT_BUCKET, MOUNT_DIR
echo "==== Setup running... ===="
TYPE=${APP_TYPE:-details}
CMD_NAME=${CMD_NAME:-geminicert}
STATUS=${STATUS:-2}
STATUS_TO=$((STATUS+1))
mntdir=${MOUNT_DIR:-.}/${TYPE}
mntoutdir=${MOUNT_DIR:-.}/${OUTPUT_DIR:-TYPE}
bucket=${MOUNT_BUCKET}/${TYPE}
datetime=$(date -u +"%Y-%m-%dT%H-%M-%S")
# MANIFEST="$mntdir/jobs/$STATUS_TO/$datetime.txt"
echo "[INFO] Type: $TYPE, Mount Dir: $mntdir, Output Dir: $mntoutdir, CMD_NAME: $CMD_NAME, STATUS: $STATUS, MOUNT_BUCKET: $MOUNT_BUCKET"
# echo "Manifest file to produce: $MANIFEST"
# rm -f "$MANIFEST*"

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
    echo "geminicert -n $isin -i $line -o $mntoutdir/output -l $mntdir/config/models.csv -t $TYPE-only -g English" >> ./run.sh
    # echo "geminicert -n $isin -i $line -o $mntoutdir/output -l $mntdir/config/models.csv -t all -g English" >> ./run.sh
    echo "if [ \$? -eq 0 ]; then 
      mkdir -p $mntdir/jobs/$STATUS/done/$datetime
      mv $filepath $mntdir/jobs/$STATUS/done/$datetime/$file
      # a MANIFEST file contains N lines like "gs://bucket/issuer/output/DE000VG656A7-issuer.json"
      # echo $bucket/output/$isin-$TYPE.json >> $MANIFEST
    else
      echo 'ERROR: $filepath'
      ((ERROR_COUNT++))
    fi" >> ./run.sh 
  fi
done
echo "echo "ERROR COUNTER: \$ERROR_COUNT"
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
