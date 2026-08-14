#!/bin/bash
cargo run -- -s data/sources-bnp.csv
node compare.js data/output/bnp -fall -w
cargo run -- -s data/sources-mx.csv
node compare.js data/output/marex -fall -w