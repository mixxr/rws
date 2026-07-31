#!/bin/bash
cargo run -- -s data/sources-bnp.csv
node compare.js data/output/bnp -fall -w