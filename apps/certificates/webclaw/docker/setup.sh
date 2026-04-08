#!/bin/bash
echo "Setup running..."
mntdir=${MOUNT_DIR:-.}
echo "Mount Dir: $mntdir"
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
chmod +x run.sh
echo "Setup completed: $(cat ./run.sh)"
./run.sh
echo "Run completed."
echo "Create semaphore file $mntdir/jobs/$datetime.f2"
touch "$mntdir/jobs/$datetime.f2"