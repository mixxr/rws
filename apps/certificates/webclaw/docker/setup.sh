#!/bin/bash
echo "Setup running..."
TYPE="certificates"
STATUS="wf"
STATUS_TO="ge"
mntdir=${MOUNT_DIR:-.}/${TYPE}
echo "Mount Dir: $mntdir"
webclaw --version
rm ./run.sh

for filepath in "$mntdir"/jobs/"$STATUS"/*.csv; do
  if [ -f "$filepath" ]; then
	  file="$(basename "$filepath")"
    echo "Processing $file"
    isin="${file%%.*}"
	  while IFS=',' read -r url file_to_save start_pos end_pos; do
      # Skip empty lines
      [[ -z "$url$file_to_save$start_pos$end_pos" ]] && continue

      echo "webclaw $url --only-main-content | cut -c $start_pos-$end_pos > $mntdir/input/$file_to_save" >> ./run.sh
      echo "if [ $? -ne 0 ]; then 
        mv $filepath $filepath.done 
        echo $mntdir/input/$file_to_save > $mntdir/jobs/$STATUS_TO/$isin.uri
      else
        echo 'ERROR: $filepath'
      fi" >> ./run.sh 
    done < "$filepath"
  fi
done
if ! test -f ./run.sh; then
  echo "No execution to build."
  exit 1
fi
chmod +x ./run.sh
echo "Setup completed: $(cat ./run.sh)"
./run.sh