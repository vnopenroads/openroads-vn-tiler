#!/usr/bin/env node

// Identify which national roads pass through an area,
// and append those geometries to a CSV with WKT geometries

const dsv = require('d3-dsv');
const fs = require('fs');
const inside = require('@turf/inside');
const length = require('@turf/length');
const lineString = require('@turf/helpers').lineString;
const point = require('@turf/helpers').point;
const wellknown = require('wellknown');

const nationalRoads = JSON.parse(fs.readFileSync(process.argv[2], 'utf-8'));
const boundary = JSON.parse(fs.readFileSync(process.argv[3], 'utf-8'));
const csvToAppendTo = process.argv[4];

const intersectingRoads = nationalRoads.features.reduce((acc, val) =>
  // All roads in the national roads GeoJSON are MultiLineStrings
  acc.concat(val.geometry.coordinates.map(c => lineString(c, val.properties)))
, []).filter(f =>
  f.geometry.coordinates.some(c => inside(point(c), boundary))
);

const existingData = dsv.csvParse(fs.readFileSync(csvToAppendTo, 'utf-8'));
const maxExistingId = Math.max(...existingData.map(r => Number(r.ID)));

const rowsToAppend = intersectingRoads.map((r, idx) => {
  return {
    Line_Geometry: wellknown.stringify(r),
    // Give a fake integer ID, that doesn't conflict with any
    // roads already in the dump
    ID: maxExistingId + 1 + idx,
    iri_mean: null,
    iri_med: null,
    iri_min: null,
    iri_max: null,
    VPROMMS_ID: null,
    // Default units are kilometers, conveniently
    length: length(r)
  };
});

const COLUMNS = [
  'Line_Geometry',
  'ID',
  'iri_mean',
  'iri_med',
  'iri_min',
  'iri_max',
  'VPROMMS_ID',
  'length'
];
// Gosh, `d3-dsv` has pretty janky formatting
// If you don't format, it's all serialized as strings, though!
const output = dsv.csvFormatRows([COLUMNS].concat(
  existingData.concat(rowsToAppend).map(r => [
    r.Line_Geometry,
    Number(r.ID),
    r.iri_mean !== null ? Number(r.iri_mean) : null,
    r.iri_med !== null ? Number(r.iri_med) : null,
    r.iri_min !== null ? Number(r.iri_min) : null,
    r.iri_max !== null ? Number(r.iri_max) : null,
    r.VPROMMS_ID,
    r.length !== null ? Number(r.length) : null
  ])
));

fs.writeFileSync(csvToAppendTo, output);
