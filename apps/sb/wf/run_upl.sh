#!/usr/bin/env bash

cd ./scripts
datetime=$(TZ="Europe/Rome" date +"%Y-%m-%dT%H-%M-%S")
echo "Copying ./_sectors/* to rws/ws/sectors/$datetime/ ..."
npx wrangler r2 object put rws/ws/sectors/$datetime/ --file ./_sectors/* --remote
