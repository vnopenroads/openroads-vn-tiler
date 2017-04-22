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
.pipe(through.obj(function ({value:nodeArr}, _, next) {
  var way_id = nodeArr[0] ? nodeArr[0].way_id : null
  next(null, {
    way_id: way_id,
    coordinates: nodeArr.map(nodeCoordinates)
  })
}))

// a stream of properties object for each way, from its 'tags'
var tags = fs.createReadStream(process.argv[3]).pipe(csv({escape: '`'}))
.pipe(group(toKey))
.pipe(through.obj(function ({value:tagArr}, _, next) {
  var obj = { way_id: tagArr[0] ? tagArr[0].way_id : null, properties: {} }
  tagArr.forEach(function (tag) {
    obj.properties[tag.k] = tag.v
  })
  next(null, obj)
}))

// merge the two streams using way_id, and emit geojson
merge(ways, tags, toKey)
.pipe(group(toKey))
.pipe(through.obj(function ({value: wayArr}, _, next) {
  next(null, {
    type: 'Feature',
    properties: wayArr[0].properties,
    geometry: {
      type: 'LineString',
      coordinates: wayArr[1].coordinates
    }
  })
}))
.pipe(jsonstream.stringify('', '\n', ''))
.pipe(process.stdout)

function nodeCoordinates (node) {
  return [
    parseInt(node.longitude, 10) / 10000000,
    parseInt(node.latitude, 10) / 10000000
  ]
}
