#!/usr/bin/env node

// Stream a CSV and sort into provincial CSVs to prepare dumps.

const fs = require('fs');
const csv = require('csv-parser');
const group = require('group-stream');
const stringifier = require('csv-stringify');
const through = require('through2')
const _ = require('lodash');

let provinceFilesRemoved = [];

const OUTPUT_DIR = './cba/provinces/';

function getProvincePath(id) {
    return OUTPUT_DIR + id + '.csv';
}

const headers = ['orma_way_id', 'vpromm_id', 'section_id', 'link_id', 'province', 'PCS', 'length', 'iri_max', 'iri_med', 'iri_min', 'iri_mean', 'Road Name', 'Road Type', 'Risk Score', 'Road Number', 'Surface Type', 'Poverty Score', 'Terrain Class', 'Traffic Level', 'End Point Name', 'Moisture Class', 'Road Class Code', 'Roughness Score', 'Start Point Name', 'Criticality Score', 'Structural Number', 'Temperature Class', 'Accessibility Score', 'Large Bus (veh/day)', 'Pavement Age (year)', 'Small Bus (veh/day)', 'Small Car (veh/day)', 'Embankment Width (m)', 'Medium Bus (veh/day)', 'Medium Car (veh/day)', 'Motorcycle (veh/day)', 'Carriageway Width (m)', 'Heavy Truck (veh/day)', 'Light Truck (veh/day)', 'Management Class Code', 'Number of Lanes Class', 'Road Length (VProMMS)', 'Medium Truck (veh/day)', '4 Wheel Drive (veh/day)', 'Total Traffic (veh/day)', 'Drainage Condition Class', 'Pavement Condition Class', 'Delivery Vehicle (veh/day)', 'Articulated Truck (veh/day)', 'Traffic Annual Growth Scenario', 'or_section_large_bus', 'or_link_class', 'or_link_direct_population', 'or_link_district_gso', 'or_link_indirect_population', 'or_link_length', 'or_link_name', 'or_section_articulated_truck', 'or_section_carriageway', 'or_section_commune_gso', 'or_section_delivery_vehicle', 'or_section_four_wheel', 'or_section_heavy_truck', 'or_section_lanes', 'or_section_length', 'or_section_light_truck', 'or_section_medium_bus', 'or_section_medium_car', 'or_section_medium_truck', 'or_section_moisture', 'or_section_motorcycle', 'or_section_name', 'or_section_pavement', 'or_section_pavement_age', 'or_section_pavement_condition', 'or_section_sequence', 'or_section_small_bus', 'or_section_small_car', 'or_section_surface', 'or_section_temperature', 'or_section_terrain', 'or_section_traffic', 'or_section_traffic_growth'];

// cleanup the JSON from the database to be able to parse it
function unescapeJSON(s) {
    const regex = /[\"]{2}([a-zA-Z0-9]{1,})[\"]{2}/g;
    return s.replace(regex, (p) => `"${p}"`);
}

fs.createReadStream(process.argv[2])
    .pipe(csv())
    .pipe(through.obj((obj, enc, next) => {
        const arr = headers.map(col => {
            return obj[col] || '';
        });
        stringifier([arr], (err, output) => {
            console.log('1', obj['province'])
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
