#!/bin/bash
# if last command failed, exit with error
if [ $? -ne 0 ]; then
  echo "Previous command failed. Exiting."
  exit 1
fi
echo "Appending $1 to $2"
echo $1 >> $2
