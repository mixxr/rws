#!/bin/bash

echo "Copying rws/ws/$1 to ./$1 ..."
pwd
npx wrangler r2 object get rws/ws/$1 --file ./$1 --remote
ls -la

