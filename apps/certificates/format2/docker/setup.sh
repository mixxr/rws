#!/bin/bash
echo "Setup running..."
mntdir=${MOUNT_DIR:-.}
bucket=${MOUNT_BUCKET}
echo "Mount Dir: $mntdir -> $bucket"
rm ./run.sh
echo "#!/bin/bash" > ./run.sh
# "Read semaphore file, its filename is <dt>.format2, where <dt> is the datetime in format YYYY-MM-DDTHH-MM-SS, eg. 2024-06-01T12-00-00.format2"
echo "Read <datetime>.format2 semaphore file to get datetime for processing"
semaphore_file=$(ls "$mntdir"/jobs/*.format2 2>/dev/null | head -n 1)
if [ -z "$semaphore_file" ]; then
  echo "No semaphore file found. Exiting."
  exit 1
fi
datetime=$(basename "$semaphore_file" .format2)
echo "Datetime for processing: $datetime"
for filepath in "$mntdir"/config/*.rx.txt; do
  if [ -f "$filepath" ]; then
	  file="$(basename "$filepath")"
    echo "basename $file"
	  issuer="${file%%.*}"
    if [ -e ./pre-cmd.sh ]; then
   	  echo "./pre-cmd.sh $mntdir/output/$issuer/$datetime" >> ./run.sh
    fi
	  echo "format2 --config $filepath --input-dir $mntdir/output/$issuer/$datetime --output-dir $mntdir/output/formatted/$issuer/$datetime.json -f ndjson -l 3000 2>>$semaphore_file" >> ./run.sh
    if [ -e ./post-cmd.sh ]; then
   	  echo "./post-cmd.sh $mntdir/output/formatted/$issuer/$datetime.json" >> ./run.sh
    fi
    echo "$bucket/output/formatted/$issuer/$datetime.json" >> $mntdir/jobs/$datetime.bq.partial
  fi
done
chmod +x run.sh
echo "Setup completed: $(cat ./run.sh)"
./run.sh
echo "Run completed."
echo "Creating semaphone file for BQ: $mntdir/jobs/$datetime.bq"
mv $mntdir/jobs/$datetime.bq.partial  $mntdir/jobs/$datetime.bq
echo "Rename semaphore file $semaphore_file"
mv $semaphore_file $semaphore_file.done