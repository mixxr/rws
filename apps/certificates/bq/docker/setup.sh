#!/bin/bash
echo "==== Setup running...===="
TYPE="certificates"
STATUS="bq"
mntdir=${MOUNT_DIR:-.}/${TYPE}
bucket=${MOUNT_BUCKET}/${TYPE}
echo "Mount Dir: $mntdir -> $bucket"
echo "Reading manifest files from $mntdir/jobs/$STATUS/*.txt"

echo "#!/bin/bash" > ./run.sh
echo "ERROR_COUNT=0" >> ./run.sh
for manifest_file in "$mntdir/jobs/$STATUS"/*.uri; do
  echo "Processing manifest file $manifest_file"
  log_file="$manifest_file".log
  datetime=$(basename "$manifest_file" .txt)
  echo "bq load \\
    --autodetect=false --source_format=NEWLINE_DELIMITED_JSON \\
    --schema_update_option=ALLOW_FIELD_ADDITION \\
    --file_set_spec_type=NEW_LINE_DELIMITED_MANIFEST \\
    ISINs.isin_ticker \\
    $bucket/jobs/$STATUS/$datetime.txt 2>> $log_file" >> ./run.sh
  echo "if [ \$? -eq 0 ]; then
    mv $manifest_file $manifest_file.done
  else 
    echo 'ERROR loading $manifest_file' 
    mv $manifest_file $manifest_file.error
    ((ERROR_COUNT++))
  fi" >> ./run.sh
done

echo "echo ERROR COUNTER: \$ERROR_COUNT
if [ \$ERROR_COUNT -gt 0 ]; then
  exit 2
fi" >> ./run.sh

chmod +x ./run.sh
echo -e "Setup completed:\n $(cat ./run.sh)"
./run.sh
echo "==== Execution completed ===="