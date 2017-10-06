#!/usr/bin/env node

'use strict';
// writes road csvs grouped by admin.

var map = require('lodash.map');
var groupBy = require('lodash.groupby');
var flatten = require('flat');
var featureCollection = require('@turf/helpers').featureCollection;
var fs = require('fs');
var geojsonStream = require('geojson-stream');
var json2csv = require('json2csv');
var wkx = require('wkx');

Promise = require('bluebird');

const parser = geojsonStream.parse();
const mappedSubadmin = JSON.parse(fs.readFileSync('lib/vietnam-admin.subadmin.json').toString());

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
    // for each group, write features as csv
    Promise.each(Object.keys(mappedFeatures), (key, i) => {
      // map features to the admin area
      let features = map(mappedFeatures[key], 'feature')
      // fields used in json2csv
      let fields;
      // for each feature, return an object with geometry as wkt And that will work with json2csv
      features = features.map((feature, i) => {
        // make a new copy of f we can 'flatten' with f in line 56
        var f = feature;
        // convert geometry to wkt text
        f.geometry = wkx.Geometry.parseGeoJSON(feature.geometry).toWkt();
        f = flatten(f);
        // remove leading properties
        f = removeProperties('properties', f);
        if (i === 0) { fields = Object.keys(f) }
        // return new feature object
        return f;
      })
      // generate csv to write
      var featuresCSV = json2csv({ data: features, fields: fields });
      // generate filename to write
      const fileName = `${process.argv[3]}/${mappedFeatures[key][0].admin}.csv`;
      // write the csv to a file
      fs.writeFileSync(fileName, featuresCSV);
    }).then(() => {
      console.log('end');
    });
  });

  /**
   * removes properties from object keys after being flattened
   * @param {string} leading a string to remove from property keys
   * @param {object} feature a feature object
   * @return feature with changed property names
   */
  function removeProperties (name, feature) {
    var newF = {};
    Object.keys(feature).forEach((k) => {
      let newK = k;
      if (/properties/.test(k)) {
        newK = k.replace('properties.', '')
      }
      newF[newK] = feature[k];
    })
    return newF
  }
