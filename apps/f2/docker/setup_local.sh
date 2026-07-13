#!/bin/bash
echo "Setup Local running...NOTE: IT IS NEEDED **ONLY** WHEN setup.sh runs locally!!"
TYPE="quotes"
BUCKET_URI="gs://rws-data"
BUCKET_URI_OUTPUT="$BUCKET_URI/$TYPE/output"
BUCKET_URI_JOBS="$BUCKET_URI/$TYPE/jobs/2"
WORKDIR="."
WORKDIR_OUTPUT="$WORKDIR/$TYPE/output/*"
WORKDIR_JOBS="$WORKDIR/$TYPE/jobs/2"

./setup.sh

for f in "$WORKDIR_JOBS"/*.f2.done; do
    # Extract base filename without .done
    base=$(basename "$f" .done)

    # Remote file.f2 to delete
    remote="$BUCKET_URI_JOBS/$base"
    echo "Deleting $remote..."
    gcloud storage rm "$remote" || true

    echo "Uploading $WORKDIR_JOBS/$base.done → $remote.done..."
    gcloud storage cp $WORKDIR_JOBS/$base.done $remote.done
done

echo "Uploading $WORKDIR_OUTPUT → $BUCKET_URI_OUTPUT..."
gcloud storage cp --recursive $WORKDIR_OUTPUT $BUCKET_URI_OUTPUT/ || true