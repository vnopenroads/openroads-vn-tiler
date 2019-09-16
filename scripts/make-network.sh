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

echo "extract mbtiles to local"
../node_modules/.bin/mapbox-tile-copy $PWD/$WORKDIR/network.mbtiles "file://../backup/mbtiles?filetype=vector.pbf"

rm -rf tmp-network

echo "Done"
