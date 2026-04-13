#!/bin/bash
set -a
source .env.local
cargo run -- -i config/bnp-1.csv -o ./data/bnp -p 5
set +a
