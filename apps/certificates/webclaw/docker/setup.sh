#!/bin/bash
echo "==== Setup running... ===="
TYPE="certificates"
STATUS="wf"
STATUS_TO="ge"
mntdir=${MOUNT_DIR:-.}/${TYPE}
echo "Mount Dir: $mntdir"
webclaw --version
mkdir -p $mntdir/input/
rm ./run.sh

for filepath in "$mntdir"/jobs/"$STATUS"/*.csv; do
  if [ -f "$filepath" ]; then
	  file="$(basename "$filepath")"
    isin="${file%%.*}"
    echo "Processing $isin $filepath"
	  while IFS=',' read -r url file_to_save start_line lines_to_read || [[ -n "$lines_to_read" ]]; do
      # Skip empty lines
      [[ -z "$url$file_to_save$start_line$lines_to_read" ]] && continue
      url="${url#"${url%%[![:space:]]*}"}"
      file_to_save="${file_to_save#"${file_to_save%%[![:space:]]*}"}"
      start_line="${start_line#"${start_line%%[![:space:]]*}"}"
      lines_to_read="${lines_to_read#"${lines_to_read%%[![:space:]]*}"}"
      echo "webclaw $url --only-main-content | tail -n +$start_line | head -n +$lines_to_read > $mntdir/input/$file_to_save" >> ./run.sh
      echo "if [ \$? -eq 0 ]; then 
        mv $filepath $filepath.done 
        echo $mntdir/input/$file_to_save > $mntdir/jobs/$STATUS_TO/$isin.uri
      else
        echo 'ERROR: $filepath'
      fi" >> ./run.sh 
    done < <(head -n 1 "$filepath")
  fi
done
if ! test -f ./run.sh; then
  echo "No execution to build."
  exit 1
fi
chmod +x ./run.sh
echo -e "Setup completed:\n $(cat ./run.sh)"
./run.sh
echo "==== Execution completed ===="