#!/bin/sh
set -e

echo "Ensure the necessary environment variables are set"
: "${DATABASE_URL:?}"

# Change to script's directory
cd "${0%/*}"

OUTPUT_DIR='.tmp/provinces/'
mkdir -p $OUTPUT_DIR

echo "Map all roads to provinces and join properties"
psql "${DATABASE_URL}" -f generate-provincial-dumps.sql 

# Read .tmp/provincial_dump.csv, csv stringify and write to the respective province CSV.
echo "Preparing CSV per province"
./provincial-sort.js .tmp/provincial_dump.csv

echo "Backup..."
mkdir -p ../backup/by-province-id/
cp -r .tmp/provinces ../backup/by-province-id/