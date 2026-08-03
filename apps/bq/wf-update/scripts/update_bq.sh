#!/usr/bin/env bash
bq query \
  --use_legacy_sql=false \
  < $1