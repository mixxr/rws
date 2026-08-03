#!/bin/bash
VERSION=${APPVERSION:-0.1}
echo "BQ Update Script Step 2 - Version $VERSION"
echo "Usage: $0 [table_name] [csv_updates_file]"

set -e
cd scripts
./create_merge_sql.sh $1 $2 > updates.sql
./update_bq.sh updates.sql

echo "Done, SQL used:"
cat updates.sql