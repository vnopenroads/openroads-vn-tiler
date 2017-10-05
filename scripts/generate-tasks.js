#!/usr/bin/env node

'use strict'

var fs = require('fs')
var collect = require('stream-collect')
var match = require('networkmatch')
var linestring = require('turf-linestring')
var ndjson = require('ndjson')

// 50m threshold
var THRESHOLD = 0.005

var input = fs.createReadStream(process.argv[2])
.pipe(ndjson.parse())
collect(input, function (i) {
  i.forEach(feature => { feature._id = feature.way_id })
  var network = {
    type: 'FeatureCollection',
    features: i
  }

  function lookForIntersections (feature) {
    var start = linestring(feature.geometry.coordinates.slice(0, 2))
    var end = linestring(feature.geometry.coordinates.slice(-2, 0))
    start._id = end._id = feature.way_id

    var neighbors = match.match(start, THRESHOLD)
    .concat(match.match(end, THRESHOLD))
    .map(c => c[2])

    if (neighbors.length) {
      let ids = neighbors.join(',')
      return { way_id: feature.way_id, neighbors: `"{${ids}}"` }
    }
    return null
  }

  match.index(network)
  var result = network.features.map(lookForIntersections).filter(Boolean)

  var headers = ['way_id', 'neighbors']
  result.forEach(result => {
    console.log(headers.map(h => result[h]).join(','))
  })
})

function dblQuote (s) {
  return " + s + "
}
