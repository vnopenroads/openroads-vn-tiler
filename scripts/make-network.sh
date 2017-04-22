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
./to-geojson.js .tmp/waynodes.csv .tmp/waytags.csv > .tmp/network.geojson

echo "Converting to vector tiles"
tippecanoe -l network -z 16 -f -P -o network.mbtiles .tmp/network.geojson

echo "Output basemap tiles"
if [ -n "${AWS_ACCESS_KEY_ID}" ]; then
    AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY ../node_modules/.bin/mapbox-tile-copy network.mbtiles s3://$BUCKET/{z}/{x}/{y}.vector.pbf
else
  echo "environment variable AWS_ACCESS_KEY_ID is not defined"
  exit 1;
fi

echo "Done"
