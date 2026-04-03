#!/bin/bash
echo "Setup running..."
TYPE="quotes"
mntdir=${MOUNT_DIR:-.}/${TYPE}
bucket=${MOUNT_BUCKET}/${TYPE}
echo "Mount Dir: $mntdir -> $bucket"
rm ./run.sh
echo "#!/bin/bash" > ./run.sh
# "Read semaphore file, its filename is <dt>.bq, where <dt> is the datetime in format YYYY-MM-DDTHH-MM-SS, eg. 2024-06-01T12-00-00.bq"
echo "Read <datetime>.bq semaphore file to get datetime for processing"
semaphore_file=$(ls "$mntdir"/jobs/*.bq 2>/dev/null | head -n 1)
if [ -z "$semaphore_file" ]; then
  echo "No semaphore file found. Exiting."
  exit 1
fi
datetime=$(basename "$semaphore_file" .bq)
echo "Datetime for processing: $datetime"
if [ -e ./pre-cmd.sh ]; then
  echo "./pre-cmd.sh $semaphore_file" >> ./run.sh
fi
read -r -d '' bq_cmd <<-EOF
  bq load \
      --autodetect=true --source_format=NEWLINE_DELIMITED_JSON \
      --schema_update_option=ALLOW_FIELD_ADDITION \
      --file_set_spec_type=NEW_LINE_DELIMITED_MANIFEST \
      ISINs.quote \
      $bucket/jobs/$datetime.bq 2>> $semaphore_file
EOF
echo "$bq_cmd" >> ./run.sh
if [ -e ./post-cmd.sh ]; then
  echo "./post-cmd.sh $semaphore_file" >> ./run.sh
fi
chmod +x run.sh
echo "Setup completed: $(cat ./run.sh)"
#gcloud auth list
./run.sh
if [ $? -eq 0 ]; then 
  echo "Run completed."
  echo "Rename semaphore file $semaphore_file"
  mv $semaphore_file $semaphore_file.done
else 
  echo "Run ERROR on $semaphore_file" 
  exit 1
fi
