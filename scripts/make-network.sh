#!/bin/sh
set -e

cd "${0%/*}"

mkdir -p .tmp

if [ -n "${DATABASE_URL}" ]; then
  echo "Dumping ways"
  echo $DATABASE_URL
  cat ways.sql | psql $DATABASE_URL
else
  echo "environment variable DATABASE_URL is not defined"
  exit 1;
fi

echo "Converting to GeoJSON"
./to-geojson.js .tmp/waynodes.csv .tmp/waytags.csv .tmp/road_properties.csv > .tmp/network.geojson

echo "Converting to vector tiles"
tippecanoe -l network -z 16 -f -P -o .tmp/network.mbtiles .tmp/network.geojson

echo "Output basemap tiles"
pwd
if [ -n "${AWS_ACCESS_KEY_ID}" ]; then
    echo "Pushing to $S3_TEMPLATE"
    AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY ../node_modules/.bin/mapbox-tile-copy $PWD/.tmp/network.mbtiles $S3_TEMPLATE --timeout 20
else
  echo "environment variable AWS_ACCESS_KEY_ID is not defined"
  exit 1;
fi

echo "Done"
