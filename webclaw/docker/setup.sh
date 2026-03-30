#!/bin/bash
echo "Setup running..."
mntdir=${MOUNT_DIR:-.}
echo "Mount Dir: $mntdir"
rm ./run.sh
for filepath in "$mntdir"/*.urls.txt; do
  if [ -f "$filepath" ]; then
	file="$(basename "$filepath")"
    echo "basename $file"
	issuer="${file%%.*}"
	datetime=$(date -u +"%Y-%m-%dT%H-%M-%S")
	echo "webclaw --urls-file $filepath --output-dir $mntdir/output/$issuer/$datetime/ --only-main-content" >> ./run.sh
  fi
done
chmod +x run.sh
echo "Setup completed."
cat ./run.sh
./run.sh
echo "Run completed."