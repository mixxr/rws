#!/bin/bash
echo "Setup running..."
TYPE="quotes"
STATUS=1
STATUS_TO=2
datetime=$(date -u +"%Y-%m-%dT%H-%M-%S")
mntdir=${MOUNT_DIR:-.}/${TYPE}
#bucket=${MOUNT_BUCKET}/${TYPE}
echo "Mount Dir: $mntdir | Datetime: $datetime"
webclaw --version
mkdir -p "$mntdir/jobs/$STATUS_TO"
echo "#!/bin/bash" > ./run.sh
for filepath in "$mntdir"/config/*.urls.*; do
  if [ -f "$filepath" ]; then
	  file="$(basename "$filepath")"
	  issuer="${file%%.*}"
    output_format="${file##*.}"
    # if output_format is md, then set it to markdown
    if [ "$output_format" = "md" ]; then
      output_format="markdown"
    elif [ "$output_format" = "txt" ]; then
      output_format="text"
    fi
    echo "basename $file issuer $issuer output_format $output_format"
    mkdir -p "$mntdir/input/$issuer/$datetime"
	  echo "webclaw --urls-file $filepath --output-dir $mntdir/input/$issuer/$datetime/ --only-main-content -f $output_format" >> ./run.sh
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
  echo "Create semaphore file $mntdir/jobs/$STATUS_TO/$datetime.f2"
  touch "$mntdir/jobs/$STATUS_TO/$datetime.f2"
else 
  echo "Run ERROR on $datetime" 
  exit 1
fi
