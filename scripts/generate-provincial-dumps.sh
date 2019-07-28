#!/bin/sh
set -e

echo "Ensure the necessary environment variables are set"
: "${DATABASE_URL:?}"
: "${AWS_ACCESS_KEY_ID:?}"
: "${AWS_SECRET_ACCESS_KEY:?}"
: "${S3_DUMP_BUCKET:?}"

# Change to script's directory
cd "${0%/*}"

OUTPUT_DIR='.tmp/provinces/'
mkdir -p $OUTPUT_DIR

echo "Map all roads to provinces and join properties"
psql "${DATABASE_URL}" -f generate-provincial-dumps.sql 

# Read .tmp/provincial_dump.csv, csv stringify and write to the respective province CSV.
echo "Preparing CSV per province"
./provincial-sort.js .tmp/provincial_dump.csv

echo "Uploading to s3"
aws s3 cp --recursive \
    .tmp/provinces/ \
    "s3://${S3_DUMP_BUCKET}/by-province-id/"