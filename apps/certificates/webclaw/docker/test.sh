#!/bin/bash
url="https://123.com"
start_pos=100
end_pos=500
mntdir="/data/certs"
file_to_save="pippo.md"
filepath="/data/certs/jobs/123"
STATUS_TO="ge"
isin="PIPPO"

echo "webclaw $url --only-main-content | cut -c $start_pos-$end_pos > $mntdir/input/$file_to_save" >> ./run.sh
echo "if [ $? -ne 0 ]; then 
        mv $filepath $filepath.done 
        echo $mntdir/input/$file_to_save > $mntdir/jobs/$STATUS_TO/$isin.uri
    else
        echo 'ERROR: $filepath'
    fi" >> ./run.sh 