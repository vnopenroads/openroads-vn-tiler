#!/bin/sh
set -e

cd "${0%/*}"

WORKDIR=make-network.tmp
mkdir -p $WORKDIR

if [ -n "${DATABASE_URL}" ]; then
  echo "Dumping ways"
  echo $DATABASE_URL
  cat ways.sql | sed -e 's/.tmp/'"$WORKDIR"'/g' ways.sql | psql $DATABASE_URL
else
  echo "environment variable DATABASE_URL is not defined"
  exit 1;
fi

echo "Converting to GeoJSON"
./to-geojson.js $WORKDIR/waynodes.csv $WORKDIR/waytags.csv $WORKDIR/road_properties.csv > $WORKDIR/network.geojson

echo "Converting to vector tiles"
tippecanoe -l network -z 16 -f -P -o $WORKDIR/network.mbtiles $WORKDIR/network.geojson

echo "Output basemap tiles"
pwd
if [ -n "${AWS_ACCESS_KEY_ID}" ]; then
    echo "Pushing to $S3_TEMPLATE"
    AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY ../node_modules/.bin/mapbox-tile-copy $PWD/$WORKDIR/network.mbtiles $S3_TEMPLATE
else
  echo "environment variable AWS_ACCESS_KEY_ID is not defined"
  exit 1;
fi

rm -rf tmp-network

echo "Done"
