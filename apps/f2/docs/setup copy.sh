#!/bin/bash
echo "Setup running..."
TYPE="quotes"
STATUS=2
STATUS_TO=3
mntdir=${MOUNT_DIR:-.}/${TYPE}
bucket=${MOUNT_BUCKET}/${TYPE}

# if $DATETIME_ONREQUEST is set, then semaphore file is $mntdir/jobs/$STATUS/$DATETIME_ONREQUEST.f2, otherwise it is the first .f2 file in $mntdir/jobs/$STATUS/
semaphore_file=${DATETIME_ONREQUEST:+$mntdir/jobs/$STATUS/$DATETIME_ONREQUEST.f2}
if [ -z "$semaphore_file" ]; then
  semaphore_file=$(ls "$mntdir"/jobs/$STATUS/*.f2 2>/dev/null | head -n 1)
fi
datetime=$(basename "$semaphore_file" .f2)
echo "Datetime: $datetime, Mount Dir: $mntdir, Bucket: $bucket, Semaphore file: $semaphore_file"
# rm -f $mntdir/jobs/$datetime.bq.partial

echo "#!/bin/bash" > ./run.sh
for filepath in "$mntdir"/config/*.rx.txt; do
  if [ -f "$filepath" ]; then
	  file="$(basename "$filepath")"
    echo "basename $file"
	  issuer="${file%%.*}"
    if [ -e ./pre-cmd.sh ]; then
   	  echo "./pre-cmd.sh $mntdir/input/$issuer/$datetime" >> ./run.sh
    fi
	  echo "format2 --config $filepath --input-dir $mntdir/input/$issuer/$datetime --output-dir $mntdir/output/$issuer-$datetime-$TYPE.json -f ndjson 2>>$semaphore_file" >> ./run.sh
    if [ -e ./post-cmd.sh ]; then
   	  echo "./post-cmd.sh $mntdir/output/$issuer-$datetime-$TYPE.json" >> ./run.sh
    fi
    # echo "./append-to-bq.sh $bucket/output/formatted/$issuer/$datetime.json $mntdir/jobs/$datetime.bq.partial \$?" >> ./run.sh
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
  #echo "Creating semaphone file for BQ: $mntdir/jobs/$datetime.bq"
  #mv $mntdir/jobs/$datetime.bq.partial  $mntdir/jobs/$datetime.bq
  echo "Rename semaphore file $semaphore_file"
  mv $semaphore_file $semaphore_file.done
else 
  echo "Run ERROR on $semaphore_file" 
  echo "Rename semaphore file $semaphore_file as partially done:"
  cat $semaphore_file
  mv $semaphore_file $semaphore_file.partial
  exit 1
fi
