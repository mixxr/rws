#!/bin/bash
ERROR_COUNT=0
echo ERROR COUNTER: $ERROR_COUNT
if [ $ERROR_COUNT -gt 0 ]; then
  exit 2
fi
