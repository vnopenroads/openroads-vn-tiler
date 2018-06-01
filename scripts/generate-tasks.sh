#!/bin/sh
set -e

cd "${0%/*}"

mkdir -p .tmp

if [ -n "${DATABASE_URL}" ]; then
  echo "Dumping ways"
  echo $DATABASE_URL
  cat ways-modified-24-hours.sql | psql $DATABASE_URL

  echo "Dumping provinces"
  cat provinces.sql | psql $DATABASE_URL
else
  echo "environment variable DATABASE_URL is not defined"
  exit 1;
fi

echo "Converting to GeoJSON"
./to-geojson.js .tmp/waynodes.csv .tmp/waytags.csv .tmp/road_properties.csv > .tmp/network.geojson

echo "Create FeatureCollection of provinces"
geojson-stream-merge --input .tmp/provinces.json --output .tmp/provinces.geojson

echo "Generating tasks"
./generate-tasks.js .tmp/network.geojson .tmp/provinces.geojson > .tmp/tasks.csv

echo "Replacing tasks table with new tasks"
cat replace-tasks.sql | psql $DATABASE_URL
