#!/usr/bin/env node

// copies closest matching vpproms point's iri value to to linestring.

var includes = require('lodash.includes');
var reduce = require('lodash.reduce');
var assign = require('lodash.assign');
var utm = require('geodesy/utm');
var distance = require('@turf/distance')
var nearest = require('@turf/nearest');
var point = require('@turf/helpers').point;
var lineString = require('@turf/helpers').lineString;
var featureCollection = require('@turf/helpers').featureCollection;
var fs = require('fs');
Promise = require('bluebird');

let roads = JSON.parse(fs.readFileSync(process.argv[2]).toString())

// group by that slice of property

// take those sliced groups and group up by larger admin

console.log(roads);
