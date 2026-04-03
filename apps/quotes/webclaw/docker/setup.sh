#!/bin/bash
echo "Setup running..."
TYPE="quotes"
mntdir=${MOUNT_DIR:-.}/${TYPE}
#bucket=${MOUNT_BUCKET}/${TYPE}
echo "Mount Dir: $mntdir"
webclaw --version
rm ./run.sh
datetime=$(date -u +"%Y-%m-%dT%H-%M-%S")
for filepath in "$mntdir"/config/*.urls.txt; do
  if [ -f "$filepath" ]; then
	  file="$(basename "$filepath")"
    echo "basename $file"
	  issuer="${file%%.*}"
	  echo "webclaw --urls-file $filepath --output-dir $mntdir/output/$issuer/$datetime/ --only-main-content" >> ./run.sh
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
  echo "Create semaphore file $mntdir/jobs/$datetime.format2"
  touch "$mntdir/jobs/$datetime.format2"
else 
  echo "Run ERROR on $mntdir/jobs/$datetime" 
  exit 1
fi
