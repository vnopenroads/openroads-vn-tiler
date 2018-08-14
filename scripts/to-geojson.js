#!/usr/bin/env node

// Streams geojson of the entire network to stdout
// Usage:

var fs = require('fs')
var csv = require('csv-parser')
var group = require('group-stream')
var merge = require('sorted-merge-stream')
var through = require('through2')
var jsonstream = require('JSONStream');

var toKey = function (obj) {
  return +obj.way_id
}

// a stream of {way_id, coordinates}
var ways = fs.createReadStream(process.argv[2]).pipe(csv({escape: '`'}))
.pipe(group(toKey))
.pipe(through.obj(function (kv, _, next) {
  var nodeArr = kv.value;
  var way_id = nodeArr[0] ? nodeArr[0].way_id : null
  next(null, {
    way_id: way_id,
    coordinates: nodeArr.map(nodeCoordinates)
  })
}))

// a stream of properties object for each way, from its 'tags'
var tags = fs.createReadStream(process.argv[3]).pipe(csv({escape: '`'}))
.pipe(group(toKey))
.pipe(through.obj(function (kv, _, next) {
  var tagArr = kv.value;
  var obj = { way_id: tagArr[0] ? tagArr[0].way_id : null, properties: {} }
  tagArr.forEach(function (tag) {
    obj.properties[tag.k] = tag.v
  })
  next(null, obj)
}))

// a stream of properties for each way, from its road-id-level properties table
const properties = fs.createReadStream(process.argv[4])
  .pipe(csv({escape: '"'}))
  .pipe(group(toKey))
  .pipe(through.obj(function (kv, _, next) {
    const way_id = kv.value[0].way_id
    const properties = JSON.parse(kv.value[0].road_properties)
    const obj = {way_id, properties}
    next(null, obj)
  }))

const mergedProperties = merge(tags, properties, toKey)
  .pipe(group(toKey))
  .pipe(through.obj(function (kv, _, next) {
    // If a road only exists in one of these, then we've probably
    // hit a database-read race condition; don't save properties
    if (!kv.value[0] || !kv.value[1]) { return next(null, null); }
    const way_id = kv.value[0].way_id
    const properties = Object.assign(
      kv.value[0].properties,
      kv.value[1].properties
    )
    next(null, {way_id, properties})
  }))

// merge the streams using way_id, and emit geojson
merge(ways, mergedProperties, toKey)
.pipe(group(toKey))
.pipe(through.obj(function (kv, _, next) {
  var wayArr = kv.value;
  var properties = (wayArr[0] && wayArr[0].properties) || (wayArr[1] && wayArr[1].properties) || {};
  var coordinates = wayArr[0] && wayArr[0].coordinates || wayArr[1] && wayArr[1].coordinates;
  if (coordinates) {
    next(null, {
      type: 'Feature',
      properties: properties,
      way_id: wayArr[0].way_id,
      geometry: {
        type: 'LineString',
        coordinates: coordinates
      }
    });
  } else {
    next();
  }
}))
.pipe(jsonstream.stringify('', '\n', ''))
.pipe(process.stdout)

function nodeCoordinates (node) {
  return [
    parseInt(node.longitude, 10) / 10000000,
    parseInt(node.latitude, 10) / 10000000
  ]
}
