#!/bin/sh
set -e
source .env
# Ensure the necessary environment variables are set
: "${DATABASE_URL:?}"

# Change to script's directory
cd "${0%/*}"

mkdir -p .tmp

echo "Dumping ways, from $DATABASE_URL"
psql "$DATABASE_URL" < ways.sql

echo "Converting to GeoJSON"
mkdir .tmp/network
./to-geojson.js .tmp/waynodes.csv .tmp/waytags.csv > .tmp/network.geojson
split -l 1 .tmp/network.geojson ".tmp/network/"
../node_modules/.bin/geojson-merge \
    .tmp/network/* \
    > .tmp/network-merged.geojson

