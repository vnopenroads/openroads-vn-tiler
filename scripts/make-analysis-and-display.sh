#!/bin/sh
set -e

echo "Ensure the necessary environment variables are set"
# Credentials
: "${DATABASE_URL:?}"
: "${AWS_ACCESS_KEY_ID:?}"
: "${AWS_SECRET_ACCESS_KEY:?}"
: "${MAPBOX_ACCESS_TOKEN:?}"
: "${MAPBOX_ACCOUNT:?}"
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
cat ways.sql | sed -e 's/.tmp/'"$WORKDIR"'/g' ways.sql | psql "$DATABASE_URL"

echo "Converting network to GeoJSON"
mkdir -p $WORKDIR/network
./to-geojson.js $WORKDIR/waynodes.csv $WORKDIR/waytags.csv $WORKDIR/road_properties.csv > $WORKDIR/network.geojson
split --lines 1 $WORKDIR/network.geojson "$WORKDIR/network/"
../node_modules/.bin/geojson-merge \
    $WORKDIR/network/* \
    > $WORKDIR/network-merged.geojson

echo "Downloading national highways, which aren't tracked in ORMA"
aws s3 cp \
    "s3://$S3_DUMP_BUCKET/private-fixture-data/National_network.geojson" \
    "$WORKDIR/National_network.geojson"

echo "Conflate point data's core OR attributes onto network lines"
./conflate-points-lines.js \
    $WORKDIR/network-merged.geojson \
    $WORKDIR/points.geojson \
    $WORKDIR/conflated.geojson

echo "Merging conflated ORMA roads and national highways into one network file"
../node_modules/.bin/geojson-merge \
    $WORKDIR/National_network.geojson \
    $WORKDIR/conflated.geojson > \
    $WORKDIR/all-roads.geojson

echo "Convert to vector tiles, and upload to Mapbox"
tippecanoe \
    --layer "conflated" \
    --minimum-zoom 0 --maximum-zoom 16 \
    --drop-smallest-as-needed \
    --force --output "$WORKDIR/conflated.mbtiles" \
    "$WORKDIR/all-roads.geojson"

export MapboxAccessToken=$MAPBOX_ACCESS_TOKEN
mapbox-upload \
    "${MAPBOX_ACCOUNT}.vietnam-conflated-1" \
    "$WORKDIR/conflated.mbtiles"

echo "Successfully finished"
