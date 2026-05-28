#!/bin/bash
VERSION=${APPVERSION:-0.1}
echo "BQ Setup Script - Version $VERSION"
# it needs to be executed TYPE [tickers|details], STATUS (number, typically it is 1), MOUNT_BUCKET, MOUNT_DIR
echo "==== Setup running... ===="
TABLE_PREFIX=$TABLE_PREFIX
TYPES=$APP_TYPES
# if APP_FOLDERS is not set, use APP_TYPES as folders, otherwise use the value of APP_FOLDERS
FOLDERS=${APP_FOLDERS:-$APP_TYPES}
CMD_NAME=${CMD_NAME:-bq_load}
STATUS=${STATUS:-3}
echo "[Configuration] 
Mount Dir: $MOUNT_DIR, 
TYPES: $TYPES, 
FOLDERS: $FOLDERS, 
CMD_NAME: $CMD_NAME, 
STATUS: $STATUS, 
MOUNT_BUCKET: $MOUNT_BUCKET"
ERROR_COUNT=0
TYPES_PROCESSED=0
#TYPES is a comma separated string, we need to split it into an array
IFS='|' read -r -a TYPES_ARRAY <<< "$TYPES"
#FOLDERS is a comma separated string, we need to split it into an array
IFS='|' read -r -a FOLDERS_ARRAY <<< "$FOLDERS"
datetime=$(TZ="Europe/Rome" date +"%Y-%m-%dT%H-%M-%S")
#loop through the array and create a manifest file containing lines like gs://rws-data/certificates/output/DE000VG656A7-tickers.json
i=0
for TYPE in "${TYPES_ARRAY[@]}"; do
  # FOLDER is the value in FOLDERS_ARRAY that corresponds to the index of TYPE in TYPES_ARRAY, for
  FOLDER=${FOLDERS_ARRAY[$i]}
  ((i++))
  mntdir=${MOUNT_DIR:-.}/${FOLDER}
  bucket=${MOUNT_BUCKET}/${FOLDER}
  
  mkdir -p $mntdir/jobs/$STATUS
  # the manifest file is the list of files that are located in $mntdir/$TYPE/output/*-$TYPE.json
  manifest_file="$mntdir/jobs/$STATUS/$TYPE-$datetime.txt"
  bucket_manifest_file="$bucket/jobs/$STATUS/$TYPE-$datetime.txt"
  echo "==== Processing $TYPE 
  Creating manifest $manifest_file 
  for $mntdir/output/*-$TYPE.json"
  
  # create the manifest file with files not zero lenght and located in $mntdir/output/*-$TYPE.json
  find $mntdir/output/*-$TYPE.json -size +0 > $manifest_file
  # if manifest file is empty, skip the loading 
  if [ ! -s $manifest_file ]; then
    echo "No files to load for $TYPE, skipping..."
    rm $manifest_file
    continue
  fi
  ((TYPES_PROCESSED++))
  # the manifest file should contain lines like gs://rws-data/certificates/output/DE000VG656A7-tickers.json, we need to replace the local path with the bucket path
  sed -i "s|$mntdir|$bucket|g" $manifest_file
  bq load \
    --autodetect=false --source_format=NEWLINE_DELIMITED_JSON \
    --schema_update_option=ALLOW_FIELD_ADDITION \
    --file_set_spec_type=NEW_LINE_DELIMITED_MANIFEST \
    ISINs.$TABLE_PREFIX$TYPE \
    $bucket_manifest_file 2> $manifest_file.log
  if [ $? -eq 0 ]; then
    echo "Successfully loaded $manifest_file, moving files to $mntdir/output/done/$datetime/"
    cat $manifest_file
    mkdir -p $mntdir/output/done/$datetime/
    # loop through the manifest file and move the files to the done folder
    while IFS= read -r line; do
      file=$(basename "$line")
      mv $mntdir/output/$file $mntdir/output/done/$datetime/
    done < $manifest_file
    mkdir -p $mntdir/jobs/$STATUS/done/$datetime/
    mv $manifest_file $mntdir/jobs/$STATUS/done/$datetime/$TYPE-$datetime.txt
    # mv $manifest_file $manifest_file.done
  else 
    echo "ERROR loading $manifest_file, check error folder for details" 
    cat $manifest_file
    cat $manifest_file.log
    mkdir -p $mntdir/jobs/$STATUS/error/$datetime/
    mv $manifest_file $mntdir/jobs/$STATUS/error/$datetime/$TYPE-$datetime.txt
    mv $manifest_file.log $mntdir/jobs/$STATUS/error/$datetime/$TYPE-$datetime.log
    ((ERROR_COUNT++))
  fi
done

echo "TYPES PROCESSED: $TYPES_PROCESSED"
echo "ERROR COUNTER: $ERROR_COUNT"
if [ $ERROR_COUNT -gt 0 ]; then
  exit 2
fi

echo "==== Execution completed ===="