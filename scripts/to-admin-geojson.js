#!/usr/bin/env node
'use strict';
// writes road geojsons grouped by admin.

var map = require('lodash.map');
var groupBy = require('lodash.groupby');
var featureCollection = require('@turf/helpers').featureCollection;
var fs = require('fs');
var geojsonStream = require('geojson-stream');

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
      const adminID = feature.properties.or_vpromms.slice(0, 2);
      rollupObj['admin'] = adminID;
>>>>>>> d3e032927b34708b09bf4c985013d5ad4656d893
      rollupObj['feature'] = feature;
      mappedFeatures.push(rollupObj);
    }
  })
  .on('end', () => {
    // group mappedFeatures by admin
    mappedFeatures = groupBy(mappedFeatures, (mappedFeature) => {
      return mappedFeature.admin;
    });
    // for each group, write features as feature collection to geojson.

    Promise.each(Object.keys(mappedFeatures), (key) => {
      const fc = featureCollection(
        map(mappedFeatures[key], 'feature')
      );
      const fileName = `${process.argv[3]}/${mappedFeatures[key][0].admin}.geojson`;
      fs.writeFileSync(fileName, JSON.stringify(fc));
>>>>>>> d3e032927b34708b09bf4c985013d5ad4656d893
    }).then(() => {
      console.log('end');
    });
  });
