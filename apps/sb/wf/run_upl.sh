#!/usr/bin/env bash

cd ./scripts
datetime=$(TZ="Europe/Rome" date +"%Y-%m-%dT%H-%M-%S")
echo "Copying ./_sectors/* to rws/ws/sectors/$datetime/ ..."
# for f in ./_sectors/*; do
#     filename="$(basename "$f")"
#     npx wrangler r2 object put rws/ws/sectors/$datetime/$filename --file "$f" --remote
# done
rclone copy ./_sectors/ r2:rws/ws/sectors/$datetime/

