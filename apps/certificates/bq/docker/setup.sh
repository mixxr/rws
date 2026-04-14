#!/bin/bash
echo "==== Setup running...===="
TYPE="certificates"
STATUS="bq"
mntdir=${MOUNT_DIR:-.}/${TYPE}
echo $mntdir
echo "#!/bin/bash" > ./run.sh
echo "ERROR_COUNT=0" >> ./run.sh
echo "Reading manifest file from $mntdir/jobs/$STATUS/*.txt"
manifest_file=$(ls "$mntdir/jobs/$STATUS"/*.txt 2>/dev/null | head -n 1)
if [ -z "$manifest_file" ]; then
  echo "No manifest file found. Exiting."
  exit 1
fi
echo "Processing manifest file $manifest_file"
log_file="$manifest_file".log
while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | tr -d '\r' | xargs)
    echo "bq load \\
      --autodetect=false --source_format=NEWLINE_DELIMITED_JSON \\
      --schema_update_option=ALLOW_FIELD_ADDITION \\
      --file_set_spec_type=NEW_LINE_DELIMITED_MANIFEST \\
      ISINs.isin_ticker \\
      $line 2>> $log_file" >> ./run.sh
    echo "if [ \$? -ne 0 ]; then 
      echo 'ERROR loading $line' 
      ((ERROR_COUNT++))
    fi" >> ./run.sh
done < "$manifest_file"
echo "echo 'ERROR COUNTER: \$ERROR_COUNT'
if [ \$ERROR_COUNT -gt 0 ]; then
  mv $manifest_file $manifest_file.error
  exit 2
else
  mv $manifest_file $manifest_file.done
fi" >> ./run.sh

if ! test -f ./run.sh; then
  echo "No execution to build."
  exit 1
fi
chmod +x ./run.sh
echo -e "Setup completed:\n $(cat ./run.sh)"
#./run.sh
echo "==== Execution completed ===="