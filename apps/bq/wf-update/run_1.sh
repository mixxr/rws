#!/bin/bash
VERSION=${APPVERSION:-0.1}
echo "BQ Update Script Step 1 - Version $VERSION"
echo "Usage: $0 [file_to_download] [output_filename] [col1] [col2]..."
FILE_IN=$1
FILE_OUT=$2
shift 2
COL_NAMES=$@

set -e
cd scripts
./dwl.sh $FILE_IN
./reduce_input.sh $FILE_IN temp.csv $COL_NAMES
./get_phases.sh temp.csv $FILE_OUT

echo "Done, see updates at $FILE_OUT:"
cat $FILE_OUT