#!/bin/bash
echo "Setup running..."
TYPE="quotes"
STATUS=1
STATUS_TO=2
mntdir=${MOUNT_DIR:-.}/${TYPE}
#bucket=${MOUNT_BUCKET}/${TYPE}
echo "Mount Dir: $mntdir"
webclaw --version
mkdir -p "$mntdir/jobs/$STATUS_TO"
datetime=$(date -u +"%Y-%m-%dT%H-%M-%S")
echo "#!/bin/bash" > ./run.sh
for filepath in "$mntdir"/config/*.urls.*; do
  if [ -f "$filepath" ]; then
	  file="$(basename "$filepath")"
    echo "basename $file"
	  issuer="${file%%.*}"
    output_format="${file##*.}"
    # if output_format is md, then set it to markdown
    if [ "$output_format" = "md" ]; then
      output_format="markdown"
    elseif [ "$output_format" = "txt" ]; then
      output_format="text"
    fi

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
