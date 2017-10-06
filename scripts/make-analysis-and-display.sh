#!/bin/sh
set -e

echo "Ensure the necessary environment variables are set"
# Credentials
: "${DATABASE_URL:?}"
: "${AWS_ACCESS_KEY_ID:?}"
: "${AWS_SECRET_ACCESS_KEY:?}"
: "${MAPBOX_ACCESS_TOKEN:?}"
: "${MAPBOX_ACCOUNT:?}"
# Paths
: "${S3_DUMP_BUCKET:?}"

# Change to script's directory
cd "${0%/*}"

WORKDIR=make-analysis.tmp
mkdir -p $WORKDIR

echo "Run analytics calculations"
# This is the only location in this script where the database is _written to_
psql "$DATABASE_URL" < calculate-iri-summary-stats.sql
psql "$DATABASE_URL" < calculate-lengths.sql

echo "Dumping ways and properties from database"
cat ways.sql | sed -e 's/.tmp/'"$WORKDIR"'/g' ways.sql | psql $DATABASE_URL

echo "Converting network to GeoJSON"
mkdir -p $WORKDIR/network
./to-geojson.js $WORKDIR/waynodes.csv $WORKDIR/waytags.csv $WORKDIR/road_properties.csv > $WORKDIR/network.geojson
split --lines 1 $WORKDIR/network.geojson "$WORKDIR/network/"
../node_modules/.bin/geojson-merge \
    $WORKDIR/network/* \
    > $WORKDIR/network-merged.geojson

echo "Conflate point data's core OR attributes onto network lines"
./conflate-points-lines.js \
    $WORKDIR/network-merged.geojson \
    $WORKDIR/points.geojson \
    $WORKDIR/conflated.geojson

echo "Convert to vector tiles, and upload to Mapbox"
tippecanoe \
    --layer "conflated" \
    --minimum-zoom 0 --maximum-zoom 16 \
    --drop-smallest-as-needed \
    --force --output "$WORKDIR/conflated.mbtiles" \
    "$WORKDIR/conflated.geojson"
mapbox upload \
    "${MAPBOX_ACCOUNT}.vietnam-conflated" \
    "$WORKDIR/conflated.mbtiles"

echo "Dump un-conflated, by-province data to S3, for public consumption"
mkdir -p $WORKDIR/by-province-id
./to-admin-csv.js $WORKDIR/network-merged.geojson $WORKDIR/by-province-id
aws s3 cp \
    --recursive \
    $WORKDIR/by-province-id \
    "s3://${S3_DUMP_BUCKET}/by-province-id" \
    --acl public-read

rm -rf $WORKDIR

echo "Successfully finished"
