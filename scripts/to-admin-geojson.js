'use strict';
// writes road geojsons grouped by admin.

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
    // for each group, write features as feature collection to geojson.
    Promise.each(Object.keys(mappedFeatures), (key, i) => {
      let features = map(mappedFeatures[key], 'feature')
      let fields;
      features = features.map((feature, i) => {
        var f = feature;
        var newF = {};
        var geometry = wkx.Geometry.parseGeoJSON(feature.geometry).toWkt()
        delete f.geometry
        f = flatten(f)
        f.geometry = geometry
        // remove properties from object keys
        f = Object.keys(f).forEach((k) => {
          let newK = k;
          if (/properties/.test(k)) {
            newK = k.replace('properties.', '')
          }
          newF[newK] = f[k];
          if (i === 0) { fields = Object.keys(newF) }
        })
        return newF
      })
      var featuresCSV = json2csv({ data: features, fields: fields });
      const fileName = `${process.argv[3]}/${mappedFeatures[key][0].admin}.csv`;
      fs.writeFileSync(fileName, featuresCSV);
    }).then(() => {
      console.log('end');
    });
  });
