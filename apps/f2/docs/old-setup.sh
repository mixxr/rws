#!/bin/bash
echo "Setup running..."
TYPE="quotes"
mntdir=${MOUNT_DIR:-.}/${TYPE}
bucket=${MOUNT_BUCKET}/${TYPE}
echo "Mount Dir: $mntdir -> $bucket"
rm ./run.sh
echo "#!/bin/bash" > ./run.sh
# "Read semaphore file, its filename is <dt>.f2, where <dt> is the datetime in format YYYY-MM-DDTHH-MM-SS, eg. 2024-06-01T12-00-00.f2"
echo "Read <datetime>.f2 semaphore file to get datetime for processing"
semaphore_file=$(ls "$mntdir"/jobs/*.f2 2>/dev/null | head -n 1)
if [ -z "$semaphore_file" ]; then
  echo "No semaphore file found. Exiting."
  exit 1
fi
datetime=$(basename "$semaphore_file" .f2)
echo "Datetime for processing: $datetime"
rm -f $mntdir/jobs/$datetime.bq.partial
for filepath in "$mntdir"/config/*.rx.txt; do
  if [ -f "$filepath" ]; then
	  file="$(basename "$filepath")"
    echo "basename $file"
	  issuer="${file%%.*}"
    if [ -e ./pre-cmd.sh ]; then
   	  echo "./pre-cmd.sh $mntdir/output/$issuer/$datetime" >> ./run.sh
    fi
	  echo "format2 --config $filepath --input-dir $mntdir/output/$issuer/$datetime --output-dir $mntdir/output/formatted/$issuer/$datetime.json -f ndjson 2>>$semaphore_file" >> ./run.sh
    if [ -e ./post-cmd.sh ]; then
   	  echo "./post-cmd.sh $mntdir/output/formatted/$issuer/$datetime.json" >> ./run.sh
    fi
    echo "./append-to-bq.sh $bucket/output/formatted/$issuer/$datetime.json $mntdir/jobs/$datetime.bq.partial \$?" >> ./run.sh
  fi
done
if ! test -f ./run.sh; then
  echo "No execution to build."
  exit 1
fi
chmod +x ./run.sh
echo "Setup completed: $(cat ./run.sh)"
./run.sh
if [ $? -eq 0 ]; then 
  echo "Run completed."
  echo "Creating semaphone file for BQ: $mntdir/jobs/$datetime.bq"
  mv $mntdir/jobs/$datetime.bq.partial  $mntdir/jobs/$datetime.bq
  echo "Rename semaphore file $semaphore_file"
  mv $semaphore_file $semaphore_file.done
else 
  echo "Run ERROR on $semaphore_file" 
  echo "Rename semaphore file $semaphore_file as partially done"
  mv $semaphore_file $semaphore_file.partial
  exit 1
fi
