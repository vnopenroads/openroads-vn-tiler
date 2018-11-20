#!/usr/bin/env node

'use strict'
const fs = require('fs')
const ndjson = require('ndjson')
const collect = require('stream-collect')
// const stringify = require('csv-stringify');
const turfBuffer = require('@turf/buffer').default;
const pointsWithinPolygon = require('@turf/points-within-polygon').default;
const _ = require('lodash');
let points = JSON.parse(fs.readFileSync(process.argv[3], {'encoding': 'utf-8'}));
points.features = _.filter(points.features, p => {
    return p.properties['or_vpromms'];
});


// read all sections from the network
const input = fs.createReadStream(process.argv[2])
.pipe(ndjson.parse())

const iriProps = ['iri_max', 'iri_min', 'iri_mean', 'iri_med'];

const getIriSummary = (points, section) => {
    const summary = points.features.reduce((result, value) => {
        let thisIri = parseFloat(value.properties.iri);
        result.values.push(thisIri);
        result.count = result.count + 1;
        result.sum = result.sum + thisIri;
        result.iri_max = thisIri > result.iri_max ? thisIri : result.iri_max;
        result.iri_min = thisIri < result.iri_min ? thisIri : result.iri_min;
        return result;
    }, {
        'iri_max': 0,
        'iri_min': 0,
        'iri_mean': 0,
        'iri_med': 0,
        'count': 0,
        'sum': 0,
        'values': []
    });

    // mean
    summary.iri_mean = summary.sum / summary.count;

    // median
    summary.values.sort((a, b) => { return a - b; });
    const middle = Math.floor(summary.values.length/2);
    if (summary.values.length % 2) {
        summary.iri_med = summary.values[middle];
    } else {
        summary.iri_med = (summary.values[middle - 1] + summary.values[middle]) / 2.0;
    }

    section.properties['iri_max'] = summary['iri_max'];
    section.properties['iri_min'] = summary['iri_min'];
    section.properties['iri_med'] = summary['iri_med'];
    section.properties['iri_mean'] = summary['iri_mean'];
    return section;
}

// console.log(headers.join(','));
collect(input, (i) => {
    // we export only sections with vpromm ids.
    const sections = _.filter(i, s => {
        return s.geometry.coordinates.length > 2;
    });
    sections.forEach(feature => {
        // get all points that fall on this line.
        let bufferedLine = turfBuffer(feature.geometry, 0.03);
        let fieldPoints = pointsWithinPolygon(points, bufferedLine.geometry);

        // clear road level iri info
        iriProps.forEach(prop => {
            feature.properties[prop] = ''
        });

        // get iri summary from points
        if (fieldPoints.features.length) {
            feature = getIriSummary(fieldPoints, feature);
        }
        console.log(JSON.stringify(feature));
    });
});

