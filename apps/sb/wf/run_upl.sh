#!/usr/bin/env bash

cd ./scripts
datetime=$(TZ="Europe/Rome" date +"%Y-%m-%dT%H-%M-%S")
echo "Copying ./_sunburst/* to rws/ws/sunburst/$datetime/ ..."
# for f in ./_sunburst/*; do
#     filename="$(basename "$f")"
#     npx wrangler r2 object put rws/ws/sunburst/$datetime/$filename --file "$f" --remote
# done
rclone copy ./_sunburst/ r2:rws/ws/sunburst/$datetime/

