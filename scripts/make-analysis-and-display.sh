#!/bin/sh
set -e

<<<<<<< HEAD
echo "Ensure the necessary environment variables are set"
# Credentials
: "${DATABASE_URL:?}"
: "${AWS_ACCESS_KEY_ID:?}"
: "${AWS_SECRET_ACCESS_KEY:?}"
: "${MAPBOX_ACCESS_TOKEN:?}"
# Paths
: "${S3_DUMP_BUCKET:?}"
: "${S3_PROPERTIES_BUCKET:?}"
: "${MAPBOX_ACCOUNT:?}"
=======
# Ensure the necessary environment variables are set
: "${DATABASE_URL:?}"
: "${AWS_ACCESS_KEY_ID:?}"
: "${AWS_SECRET_ACCESS_KEY:?}"
: "${MAPBOX_ACCOUNT:?}"
: "${MAPBOX_ACCESS_TOKEN:?}"
>>>>>>> develop

# Change to script's directory
cd "${0%/*}"

mkdir -p .tmp

<<<<<<< HEAD
echo "Dumping ways from database"
psql "$DATABASE_URL" < ways.sql

echo "Converting network to GeoJSON"
=======
echo "Dumping ways, from $DATABASE_URL"
psql "$DATABASE_URL" < ways.sql

echo "Converting to GeoJSON"
>>>>>>> develop
mkdir .tmp/network
./to-geojson.js .tmp/waynodes.csv .tmp/waytags.csv > .tmp/network.geojson
split --lines 1 .tmp/network.geojson ".tmp/network/"
../node_modules/.bin/geojson-merge \
    .tmp/network/* \
    > .tmp/network-merged.geojson

<<<<<<< HEAD
echo "Get all point-property data from S3"
mkdir .tmp/points
aws s3 cp \
    --recursive --include "*.geojson" \
    "s3://${S3_PROPERTIES_BUCKET}/points" \
=======
echo "Get all point data from S3"
mkdir .tmp/points
aws s3 cp \
    --recursive --include "*.geojson" \
    s3://openroads-vn-properties/points \
>>>>>>> develop
    .tmp/points
../node_modules/.bin/geojson-merge \
    .tmp/points/*.geojson \
    > .tmp/points.geojson
../node_modules/.bin/reproject \
    --use-spatialreference --from EPSG:32648 --to EPSG:4326 \
    .tmp/points.geojson \
    > .tmp/points-wgs84.geojson

<<<<<<< HEAD
echo "Conflate point data's core OR attributes onto network lines"
=======
echo "Conflate point data onto network lines"
>>>>>>> develop
./conflate-points-lines.js \
    .tmp/network-merged.geojson \
    .tmp/points-wgs84.geojson \
    .tmp/conflated.geojson

<<<<<<< HEAD
=======
echo "Run analytics on output, and update database"
# ADD ANALYTICS CODE

>>>>>>> develop
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

<<<<<<< HEAD
echo "There is currently no analytics processing, but it would be insterted here"

echo "Dump un-conflated, by-province data to S3, for public consumption"
mkdir .tmp/by-province-id
# ./to-admin-geojson.js .tmp/network-merged.geojson .tmp/by-province-id
./to-admin-csv.js .tmp/network-merged.geojson .tmp/by-province-id
aws s3 cp \
    --recursive \
    .tmp/by-province-id \
    "s3://${S3_DUMP_BUCKET}/by-province-id" \
    --acl public-read

echo "Successfully finished"
=======
echo "Dump un-conflated, by-province data to S3, for public consumption"
mkdir .tmp/by-province-name
./to-admin-geojson.js .tmp/network-merged.geojson .tmp/by-province-name
aws s3 cp \
    --recursive \
    .tmp/by-province-name \
    s3://openroads-vn-dumps/by-province-name \
    --acl public-read

echo "Finished"
>>>>>>> develop
