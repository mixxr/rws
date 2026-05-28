#!/bin/bash
VERSION=${APPVERSION:-0.1}
run_job() {
  local job_name=$1
  PROJECT="invcerts"
  REGION="europe-west1"
  TOKEN=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata/computeMetadata/v1/instance/service-accounts/default/token \
  | jq -r .access_token)

  curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    "https://run.googleapis.com/v2/projects/$PROJECT/locations/$REGION/jobs/${job_name}:run"
}

echo "WebClaw Setup Script - Version $VERSION"
# it needs to be executed TYPE [issuer|details|quotes], STATUS (number, typically it is 1), CMD_NAME[curl|webclaw], MOUNT_DIR
echo "==== Setup running... ===="
TYPE=${APP_TYPE:-details}
CMD_NAME=${CMD_NAME:-webclaw}
STATUS=${STATUS:-1}
STATUS_TO=$((STATUS+1))
mntdir=${MOUNT_DIR:-.}/${TYPE}
datetime=$(TZ="Europe/Rome" date +"%Y-%m-%dT%H-%M-%S")
echo "[INFO] Mount Dir: $mntdir, TYPE: $TYPE, CMD_NAME: $CMD_NAME, STATUS: $STATUS"
$CMD_NAME --version
mkdir -p $mntdir/input/
mkdir -p $mntdir/jobs/$STATUS_TO/

echo "#!/bin/bash" > ./run.sh
echo "ERROR_COUNT=0" >> ./run.sh

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
      lines_to_read="${lines_to_read//$'\r'/}" 
      echo "Processing $url $file_to_save $start_line $lines_to_read:"
      # test if CMD_NAME is webclaw or curl
      if [ "$CMD_NAME" == "webclaw" ]; then
        echo "webclaw $url --only-main-content | tail -n +$start_line | head -n +$lines_to_read > $mntdir/input/$file_to_save" >> ./run.sh
      else
        echo "curl -s $url | tail -n +$start_line | head -n +$lines_to_read > $mntdir/input/$file_to_save" >> ./run.sh
      fi
      echo "if [ \$? -eq 0 ]; then 
        mkdir -p $mntdir/jobs/$STATUS/done/$datetime
        mv $filepath $mntdir/jobs/$STATUS/done/$datetime/$file 
        echo $mntdir/input/$file_to_save > $mntdir/jobs/$STATUS_TO/$isin.uri
      else
        echo 'ERROR: $filepath'
        ((ERROR_COUNT++))
      fi" >> ./run.sh 
    done < <(head -n 1 "$filepath")
  fi
done
echo "echo "ERROR COUNTER: \$ERROR_COUNT"
if [ \$ERROR_COUNT -gt 0 ]; then
  exit 2
fi" >> ./run.sh
if ! test -f ./run.sh; then
  echo "No execution to build."
  exit 1
fi
chmod +x ./run.sh
echo -e "Setup completed:\n $(cat ./run.sh)"
./run.sh
# if STATUS_TO is 2 and START_NEXT_JOB is true, then start the next job
if [ "$STATUS_TO" -eq 2 ]; then
  if [ "${START_NEXT_JOB:-false}" == "true" ]; then
    echo "Starting downstream job ${TYPE}-ge-s2-job"
    # gcloud run jobs execute "${TYPE}-ge-s2-job" --region europe-west1
    run_job "${TYPE}-ge-s2-job"
  else
    echo "Skipping job auto-start for $TYPE"
  fi
fi
echo "==== Execution completed ===="