#!/bin/bash
gsutil -m cp \
    ./data/json/* \
  "gs://rws-data/quotes/output"