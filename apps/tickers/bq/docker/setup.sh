#!/bin/bash
VERSION="0.2"
echo "BQ Setup Script - Version $VERSION"
# it needs to be executed TYPE [tickers|details], STATUS (number, typically it is 1), MOUNT_BUCKET, MOUNT_DIR
echo "==== Setup running... ===="
TABLE_PREFIX=${TABLE_PREFIX:-}
TYPES=$APP_TYPES
CMD_NAME=${CMD_NAME:-gs_load}
STATUS=${STATUS:-3}
echo "[INFO] Mount Dir: $mntdir, TYPES: $TYPES, CMD_NAME: $CMD_NAME, STATUS: $STATUS, MOUNT_BUCKET: $bucket"
ERROR_COUNT=0
#TYPES is a comma separated string, we need to split it into an array
IFS=',' read -r -a TYPES_ARRAY <<< "$TYPES"
#loop through the array and create a manifest file containing lines like gs://rws-data/certificates/output/DE000VG656A7-tickers.json
for TYPE in "${TYPES_ARRAY[@]}"; do
  mntdir=${MOUNT_DIR:-.}/${TYPE}
  bucket=${MOUNT_BUCKET}/${TYPE}
  datetime=$(date +%Y%m%d%H%M%S)
  # the manifest file is the list of files that are located in $mntdir/$TYPE/output/*-$TYPE.json
  manifest_file="$mntdir/jobs/$STATUS/$TYPE-$datetime-manifest.txt"
  echo "Creating manifest $manifest_file for $mntdir/output/*-$TYPE.json"
  
  # create the manifest file
  find $mntdir/output/*-$TYPE.json > $manifest_file
  # the manifest file should contain lines like gs://rws-data/certificates/output/DE000VG656A7-tickers.json, we need to replace the local path with the bucket path
  sed -i "s|$mntdir|$bucket|g" $manifest_file
  # execute the bq load command for each manifest file, we need to use the --file_set_spec_type=NEW_LINE_DELIMITED_MANIFEST option to specify that the manifest file is a list of files to load
  bq load \
    --autodetect=false --source_format=NEWLINE_DELIMITED_JSON \
    --schema_update_option=ALLOW_FIELD_ADDITION \
    --file_set_spec_type=NEW_LINE_DELIMITED_MANIFEST \
    ISINs.${TABLE_PREFIX}$TYPE \
    $manifest_file >> $log_file
  if [ $? -eq 0 ]; then
    mv $manifest_file $manifest_file.done
  else 
    echo 'ERROR loading $manifest_file, renamed .error' 
    mv $manifest_file $manifest_file.error
    ((ERROR_COUNT++))
  fi
done

echo "ERROR COUNTER: $ERROR_COUNT"
if [ $ERROR_COUNT -gt 0 ]; then
  exit 2
fi

echo "==== Execution completed ===="