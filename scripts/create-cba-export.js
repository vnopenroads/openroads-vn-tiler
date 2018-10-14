#!/usr/bin/env node

'use strict'
var fs = require('fs')
var ndjson = require('ndjson')
var collect = require('stream-collect')

// read all sections from the network
var input = fs.createReadStream(process.argv[2])
.pipe(ndjson.parse())

const headers = ['way_id', 'vpromm_id', 'section_id', 'link_id', 'PCS', 'length', 'iri_max', 'iri_med', 'iri_min', 'iri_mean', 'Road Name', 'Road Type', 'Risk Score', 'Road Number', 'Surface Type', 'Poverty Score', 'Terrain Class', 'Traffic Level', 'End Point Name', 'Moisture Class', 'Road Class Code', 'Roughness Score', 'Start Point Name', 'Criticality Score', 'Structural Number', 'Temperature Class', 'Accessibility Score', 'Large Bus (veh/day)', 'Pavement Age (year)', 'Small Bus (veh/day)', 'Small Car (veh/day)', 'Embankment Width (m)', 'Medium Bus (veh/day)', 'Medium Car (veh/day)', 'Motorcycle (veh/day)', 'Carriageway Width (m)', 'Heavy Truck (veh/day)', 'Light Truck (veh/day)', 'Management Class Code', 'Number of Lanes Class', 'Road Length (VProMMS)', 'Medium Truck (veh/day)', '4 Wheel Drive (veh/day)', 'Total Traffic (veh/day)', 'Drainage Condition Class', 'Pavement Condition Class', 'Delivery Vehicle (veh/day)', 'Articulated Truck (veh/day)', 'Traffic Annual Growth Scenario'];

console.log(headers.join(','));
collect(input, (i) => {
    i.forEach(feature => {
        // we export only sections with vpromm ids.
        if (feature.properties.hasOwnProperty('or_vpromms')) {
            feature.properties['way_id'] = feature.way_id;
            console.log(headers.map(h => feature.properties[h]).join(','));
        }
    });
});