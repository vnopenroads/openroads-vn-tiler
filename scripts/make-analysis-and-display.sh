#!/bin/sh
set -e

echo "Ensure the necessary environment variables are set"
# Credentials
: "${DATABASE_URL:?}"
: "${MAPBOX_ACCESS_TOKEN:?}"
: "${MAPBOX_ACCOUNT:?}"

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
./to-geojson.js $WORKDIR/waynodes.csv $WORKDIR/waytags.csv $WORKDIR/road_properties.csv $WORKDIR/waysadmin.csv > $WORKDIR/network.geojson

# geojson-stream-merge --input $WORKDIR/network.geojson --output $WORKDIR/network-merged.geojson

# echo "Adding IRI data to GeoJSON"
# ./add-iri-to-geojson.js $WORKDIR/network.geojson $WORKDIR/points.geojson > $WORKDIR/orma-sections.geojson

cp $WORKDIR/network.geojson $WORKDIR/orma-sections.geojson

echo "Creating CSV for CBA export"
./create-cba-export.js $WORKDIR/orma-sections.geojson > $WORKDIR/orma-sections.csv

## echo "Creating CSV for province CBA export"
## ./create-cba-export-by-province.js $WORKDIR/orma-sections.csv > "../backup/cba/provinces/orma-sections.csv"

# echo "save to local. Note that this needs to be changes to a location accessible by CBA scripts."
## mkdir -p ../backup/cba
## cp "${WORKDIR}/orma-sections.csv" "../backup/cba/orma-sections-$(date +%Y-%m-%d).csv"

echo "Creating GeoJSON with extra properties stripped out"
./strip-extra-properties.js $WORKDIR/orma-sections.geojson > $WORKDIR/orma-sections-trimmed.geojson


echo "Convert to vector tiles, and upload to Mapbox"
tippecanoe \
    --layer "conflated" \
    --minimum-zoom 0 --maximum-zoom 16 \
    --drop-smallest-as-needed \
    --force --output "$WORKDIR/conflated.mbtiles" \
    "$WORKDIR/orma-sections-trimmed.geojson"

export MapboxAccessToken=$MAPBOX_ACCESS_TOKEN
mapbox-upload \
    "${MAPBOX_ACCOUNT}.vietnam-conflated-1" \
    "$WORKDIR/conflated.mbtiles"

echo "Successfully finished"
