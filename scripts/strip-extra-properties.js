#!/usr/bin/env node
'use strict'
const fs = require('fs')
const ndjson = require('ndjson')
const collect = require('stream-collect')
const _ = require('lodash');

// read all sections from the network
const input = fs.createReadStream(process.argv[2])
.pipe(ndjson.parse())

// const headers = ['orma_way_id', 'vpromm_id', 'iri_mean', 'or_section_delivery_vehicle'];

collect(input, (sections) => {

    sections.forEach(feature => {
        const allProps = JSON.parse(JSON.stringify(feature.properties));
        feature.properties = {};
        feature.properties['orma_way_id'] = feature.way_id;
        feature.properties['vpromm_id'] = allProps.or_vpromms || null;
        feature.properties['iri_mean'] = allProps.iri_mean || null;
        feature.properties['or_section_delivery_vehicle'] = parseFloat(allProps.or_section_delivery_vehicle) || 0;
        process.stdout.write(JSON.stringify(feature));
        process.stdout.write('\n'); 
    });
});

