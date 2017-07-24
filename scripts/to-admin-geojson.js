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
const mappedSubadmin = JSON.parse(fs.readFileSync('scripts/lib/vietnam-admin.subadmin.json').toString());

let mappedFeatures = [];

// for each feature, push obj to mappedFeatures w/adminCode and feature
fs.createReadStream(process.argv[2])
  .pipe(parser)
  .on('data', (feature) => {
    const rollupObj = {};
    // only push features to mappedFeatures where or_vpromms exist.
    if (feature.properties.or_vpromms) {
      const subCode = feature.properties.or_vpromms.slice(3, 5);
      let adminCode = mappedSubadmin.filter((mapObj) => {
        if (mapObj.subCode === subCode) {
          return mapObj.adminCode;
        }
      })[0].adminCode;
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
    // for each group, write features as feature collection to geojson.
    Promise.each(Object.keys(mappedFeatures), (key) => {
      const fc = featureCollection(
        map(mappedFeatures[key], 'feature')
      );
      const fileName = 'scripts/output/' + mappedFeatures[key][0].admin.replace(' ', '-') + '.geojson';
      fs.writeFileSync(fileName, JSON.stringify(fc));
    }).then(() => {
      console.log('end');
    });
  });
