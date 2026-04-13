#!/bin/bash
set -a
source .env.local
cargo run -- -i /tmp/data/certificates/input/DE000VH68M19.md -o /tmp/data/certificates/output -l config/models.csv -n DE000VH68M19 -p 1
set +a
