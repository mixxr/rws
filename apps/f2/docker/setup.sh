#!/bin/bash
echo "Setup running..."
TYPE="quotes"
STATUS=2
STATUS_TO=3
mntdir=${MOUNT_DIR:-.}/${TYPE}
bucket=${MOUNT_BUCKET}/${TYPE}

if [ -n "$DATETIME_ONREQUEST" ]; then
  files=("$mntdir/jobs/$STATUS/$DATETIME_ONREQUEST.f2")
else
  files=("$mntdir"/jobs/$STATUS/*.f2)
fi
echo "Datetime on request: $DATETIME_ONREQUEST, Mount Dir: $mntdir, Bucket: $bucket"
# rm -f $mntdir/jobs/$datetime.bq.partial

for semaphore_file in "${files[@]}"; do
  [ -e "$semaphore_file" ] || continue

  datetime=$(basename "$semaphore_file" .f2)
  echo "================================ Processing: $datetime"

  echo "#!/bin/bash" > ./run.sh

  for filepath in "$mntdir"/config/*.rx.txt; do
    if [ -f "$filepath" ]; then
      file="$(basename "$filepath")"
      issuer="${file%%.*}"

      if [ -e ./pre-cmd.sh ]; then
        echo "./pre-cmd.sh $mntdir/input/$issuer/$datetime" >> ./run.sh
      fi

      echo "format2 --config $filepath --input-dir $mntdir/input/$issuer/$datetime --output-dir $mntdir/output/$issuer-$datetime-$TYPE.json -f ndjson 2>>$semaphore_file" >> ./run.sh

      if [ -e ./post-cmd.sh ]; then
        echo "./post-cmd.sh $mntdir/output/$issuer-$datetime-$TYPE.json" >> ./run.sh
      fi
    fi
  done

  chmod +x ./run.sh
  ./run.sh

  if [ $? -eq 0 ]; then 
    echo "Run completed for $semaphore_file"
    mv "$semaphore_file" "$semaphore_file.done"
  else 
    echo "Run ERROR on $semaphore_file"
    mv "$semaphore_file" "$semaphore_file.partial"
    exit 1
  fi
   echo "================================ Processing completed: $datetime"
done