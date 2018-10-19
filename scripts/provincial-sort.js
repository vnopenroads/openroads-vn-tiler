#!/usr/bin/env node

// Stream a CSV and sort into provincial CSVs to prepare dumps.

const fs = require('fs');
const csv = require('csv-parser');
const group = require('group-stream');
const stringifier = require('csv-stringify');
const through = require('through2')
const _ = require('lodash');

const headers = ["province", "vpromm_id", "way_id", "geom", "iri_min", "iri_max", "iri_mean", "iri_med", "iri_stdev", "speed_mean", "length"];

const properties = ["iri_min", "iri_max", "iri_mean", "iri_med", "iri_stdev", "speed_mean", "length"];
var roads = fs.createReadStream(process.argv[2])
    .pipe(csv())
    .pipe(through.obj((obj, enc, next) => {
        var row = [];
        properties.forEach(p => {
            row[p] = obj.properties[p] ? obj.properties[p] : "";
        });
        row['province'] = obj['province'];
        row['vpromm_id'] = obj['vpromm_id'];
        row['way_id'] = obj['way_id'];
        row['geom'] = obj['geom'];
        next(null, row)
    }))

    // to-do: stringify but write to a file based on province
    .pipe(stringifier({columns: headers}))
    .pipe(process.stdout);
