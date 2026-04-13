#!/bin/bash
echo "==== Setup running... ===="
TYPE="certificates"
STATUS="ge"
STATUS_TO="bq"
mntdir=${MOUNT_DIR:-.}/${TYPE}
bucket=${MOUNT_BUCKET}/${TYPE}
datetime=$(date -u +"%Y-%m-%dT%H-%M-%S")
MANIFEST="$mntdir/jobs/$STATUS_TO/$datetime.txt"

echo "Mount Dir: $mntdir -> $bucket"
echo "Manifest file: $MANIFEST"
rm ./run.sh
#rm -f "$MANIFEST*"

echo "#!/bin/bash" > ./run.sh
for filepath in "$mntdir/jobs/$STATUS"/*.uri; do
  if [ -f "$filepath" ]; then
	  file="$(basename "$filepath")"
    isin="${file%%.*}"
    echo "Processing $isin $filepath"
    
	  read -r line < "$filepath"
    echo "geminicert -n $isin -i $line -o $mntdir/output -l $mntdir/config/models.csv -p 1" >> ./run.sh
    echo "if [ \$? -eq 0 ]; then 
      mv $filepath $filepath.done 
      echo $bucket/output/$isin-tickers.json >> $MANIFEST
    else
      echo 'ERROR: $filepath'
    fi" >> ./run.sh 
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
