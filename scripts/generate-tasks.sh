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

echo "Generating tasks"
./generate-tasks.js .tmp/network.geojson > .tmp/tasks.json
