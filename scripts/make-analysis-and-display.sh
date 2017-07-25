#!/bin/sh
set -e

# Ensure the necessary environment variables are set
: "${DATABASE_URL:?}"
: "${AWS_ACCESS_KEY_ID:?}"
: "${AWS_SECRET_ACCESS_KEY:?}"
: "${$S3_TEMPLATE:?}"
: "${MAPBOX_ACCOUNT:?}"
: "${MAPBOX_ACCESS_TOKEN:?}"

# Change to script's directory
cd "${0%/*}"

mkdir -p .tmp

echo "Dumping ways, from $DATABASE_URL"
psql "$DATABASE_URL" < ways.sql

echo "Converting to GeoJSON"
mkdir .tmp/network
./to-geojson.js .tmp/waynodes.csv .tmp/waytags.csv > .tmp/network.geojson
split --lines 1 .tmp/network.geojson ".tmp/network/"
../node_modules/.bin/geojson-merge \
    .tmp/network/* \
    > .tmp/network-merged.geojson

echo "Get all point data from S3"
mkdir .tmp/points
aws s3 cp \
    --recursive --include "*.geojson" \
    s3://openroads-vn-properties/points \
    .tmp/points
../node_modules/.bin/geojson-merge \
    .tmp/points/*.geojson \
    > .tmp/points.geojson
../node_modules/.bin/reproject \
    --use-spatialreference --from EPSG:32648 --to EPSG:4326 \
    .tmp/points.geojson \
    > .tmp/points-wgs84.geojson

echo "Conflate point data onto network lines"
./conflate-points-lines.js \
    .tmp/network-merged.geojson \
    .tmp/points-wgs84.geojson \
    .tmp/conflated.geojson

echo "Run analytics on output, and update database"
# ADD ANALYTICS CODE

echo "Convert to vector tiles, and upload to Mapbox"
tippecanoe \
    --layer "conflated" \
    --minimum-zoom 0 --maximum-zoom 16 \
    --drop-smallest-as-needed \
    --force --output ".tmp/conflated.mbtiles" \
    ".tmp/conflated.geojson"
mapbox upload \
    "${MAPBOX_ACCOUNT}.vietnam-conflated" \
    ".tmp/conflated.mbtiles"

echo "Finished"
