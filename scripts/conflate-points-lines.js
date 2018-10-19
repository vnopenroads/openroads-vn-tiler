#!/usr/bin/env node

// For each two-point segment of `current_ways` roads,
// find the geographically closest property values from
// `point_properties`, and attach it

const _ = require('lodash');
var distance = require('@turf/distance');
var nearest = require('@turf/nearest');
var point = require('@turf/helpers').point;
var lineString = require('@turf/helpers').lineString;
var featureCollection = require('@turf/helpers').featureCollection;
var fs = require('fs');

let roads = JSON.parse(fs.readFileSync(process.argv[2], 'utf-8'));
let points = JSON.parse(fs.readFileSync(process.argv[3], 'utf-8'));

const MAX_METERS_AWAY = 50;
const POINT_PROPERTIES = [
  'iri'
];

roads.features = roads.features.filter((r) => {
  return (r.geometry.coordinates.length >= 2);
});

const segments = roads.features.reduce((acc, val) => {
  // Explode any MultiLineStrings into LineStrings
  return val.geometry.type === 'LineString'
    ? acc.concat(val)
    : acc.concat(val.geometry.coordinates.map(c =>
      lineString(c, val.properties)
    ));
}, []).map(f =>
  lineString(
    // Remove consecutive identical coordinates from road path
    f.geometry.coordinates.reduce((acc, val) => {
      return (!acc.length || !_.isEqual(_.last(acc), val))
        ? acc.concat([val])
        : acc;
    }, []),
    // Keep only `or_vpromms` road property, for visualization
    _.pick(f.properties, ['or_vpromms'])
  )
).filter(c =>
  // Make sure there are enough points to create a line
  c.geometry.coordinates.length > 1
).map(c =>
  // These two-point segments will be the "roads" shown in the vector tiles
  Array(c.geometry.coordinates.length - 1).fill().reduce((acc, val, idx) => {
    return acc.concat(
      lineString(
        [c.geometry.coordinates[idx], c.geometry.coordinates[idx + 1]],
        c.properties
      )
    );
  }, [])
).reduce((acc, val) => {
  // Handle all two-point segments separately, insted of handling by-road
  return acc.concat(val);
}, []).map(s => {
  const midpoint = point([
    (s.geometry.coordinates[0][0] + s.geometry.coordinates[1][0]) / 2,
    (s.geometry.coordinates[0][1] + s.geometry.coordinates[1][1]) / 2
  ]);
  const pointProperties = POINT_PROPERTIES.reduce((acc, val) => {
    // Find and assign the nearest point's value
    const closest = nearest(
      midpoint,
      featureCollection(points.features.filter(p => p.properties[val]))
    );
    if (distance(midpoint, closest) * 1000 <= MAX_METERS_AWAY) {
      acc[val] = closest.properties[val];
    }
    return acc;
  }, {});
  // Also need to coerce any numeric point properties
  if (pointProperties.iri) { pointProperties.iri = Number(pointProperties.iri); }

  const properties = Object.assign({}, s.properties, pointProperties);
  return Object.assign(s, {properties});
});

fs.writeFileSync(process.argv[4], JSON.stringify(featureCollection(segments)));
