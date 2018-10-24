#!/usr/bin/env node

// Stream a CSV and sort into provincial CSVs to prepare dumps.

const fs = require('fs');
const csv = require('csv-parser');
const group = require('group-stream');
const stringifier = require('csv-stringify');
const through = require('through2')
const _ = require('lodash');

const headers = ["province", "vpromm_id", "way_id", "geom", "iri_min", "iri_max", "iri_mean", "iri_med", "iri_stdev", "speed_mean", "length"];

const props = ["iri_min", "iri_max", "iri_mean", "iri_med", "iri_stdev", "speed_mean", "length"];
let provinceFilesRemoved = [];

const OUTPUT_DIR = '.tmp/provinces/';

function getProvincePath(id) {
    return OUTPUT_DIR + id + '.csv';
}

// cleanup the JSON from the database to be able to parse it
function unescapeJSON(s) {
    const regex = /[\"]{2}([a-zA-Z0-9]{1,})[\"]{2}/g;
    return s.replace(regex, (p) => `"${p}"`);
}

var roads = fs.createReadStream(process.argv[2])
    .pipe(csv())
    .pipe(through.obj((obj, enc, next) => {
        var row = {};
        if (obj.properties) {
            let thisProps = JSON.parse(unescapeJSON(obj.properties));
            props.forEach(p => {
                row[p] = thisProps[p];
            });
        }
        row['province'] = obj['province'];
        row['vpromm_id'] = obj['vpromm_id'];
        row['way_id'] = obj['way_id'];
        row['geom'] = obj['geom'];
        next(null, row);
    }))

    .pipe(through.obj((obj, enc, next) => {
        const arr = headers.map(col => {
            return obj[col] || '';
        });
        stringifier([arr], (err, output) => {
            const filePath = getProvincePath(obj['province']);
            // remove previous province file if exists and not already created in this run
            if (provinceFilesRemoved.indexOf(obj['province']) === -1 && fs.existsSync(filePath)) {
                fs.unlinkSync(filePath);
                provinceFilesRemoved.push(obj['province']);
                fs.appendFileSync(filePath, headers.join(',') + '\n');
            }
            return next(null, {
                province: obj['province'],
                data: output
            });
        });
    }))
    .pipe(through.obj((obj, enc, next) => {
        const provinceId = obj['province'];
        const csvString = obj['data'];
        const filePath = getProvincePath(provinceId);
        fs.appendFileSync(filePath, csvString);
        next();
    }));
