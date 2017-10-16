#!/usr/bin/env node

'use strict';
// writes road csvs grouped by admin.

var map = require('lodash.map');
var groupBy = require('lodash.groupby');
var featureCollection = require('@turf/helpers').featureCollection;
var fs = require('fs');
var geojsonStream = require('geojson-stream');
var json2csv = require('json2csv');
var wkx = require('wkx');

Promise = require('bluebird');

const parser = geojsonStream.parse();

let mappedFeatures = [];

// for each feature, push obj to mappedFeatures w/adminCode and feature
fs.createReadStream(process.argv[2])
  .pipe(parser)
  .on('data', (feature) => {
    const rollupObj = {};
    // only push features to mappedFeatures where or_vpromms exist.
    if (feature.properties.or_vpromms) {
      const adminCode = feature.properties.or_vpromms.slice(0, 2);
      rollupObj['admin'] = adminCode;
      rollupObj['feature'] = feature;
      mappedFeatures.push(rollupObj);
    }
  })
  .on('end', () => {
    // group mappedFeatures by admin
    mappedFeatures = groupBy(mappedFeatures, (mappedFeature) => {
      return mappedFeature.admin;
    });
    // for each group, write features as csv
    Promise.each(Object.keys(mappedFeatures), (key, i) => {
      // map features to the admin area
      let features = map(mappedFeatures[key], 'feature')
      // fields used in json2csv
      let fields = new Set(['geometry']);
      // for each feature, return an object with geometry as wkt And that will work with json2csv
      features = features.map(feature => {
        const f = feature.properties;
        Object.keys(feature.properties).forEach(k => fields.add(k));
        f.geometry = wkx.Geometry.parseGeoJSON(feature.geometry).toWkt();
        return f;
      })
      // generate csv to write
      var featuresCSV = json2csv({ data: features, fields: Array.from(fields) });
      // generate filename to write
      const fileName = `${process.argv[3]}/${key}.csv`;
      // write the csv to a file
      fs.writeFileSync(fileName, featuresCSV);
    });
  });
