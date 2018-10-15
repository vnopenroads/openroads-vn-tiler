#!/usr/bin/env node

'use strict'
const fs = require('fs')
const ndjson = require('ndjson')
const collect = require('stream-collect')

// read all sections from the network
const input = fs.createReadStream(process.argv[2])
.pipe(ndjson.parse())

const headers = ['orma_way_id', 'vpromm_id', 'section_id', 'link_id', 'PCS', 'length', 'iri_max', 'iri_med', 'iri_min', 'iri_mean', 'Road Name', 'Road Type', 'Risk Score', 'Road Number', 'Surface Type', 'Poverty Score', 'Terrain Class', 'Traffic Level', 'End Point Name', 'Moisture Class', 'Road Class Code', 'Roughness Score', 'Start Point Name', 'Criticality Score', 'Structural Number', 'Temperature Class', 'Accessibility Score', 'Large Bus (veh/day)', 'Pavement Age (year)', 'Small Bus (veh/day)', 'Small Car (veh/day)', 'Embankment Width (m)', 'Medium Bus (veh/day)', 'Medium Car (veh/day)', 'Motorcycle (veh/day)', 'Carriageway Width (m)', 'Heavy Truck (veh/day)', 'Light Truck (veh/day)', 'Management Class Code', 'Number of Lanes Class', 'Road Length (VProMMS)', 'Medium Truck (veh/day)', '4 Wheel Drive (veh/day)', 'Total Traffic (veh/day)', 'Drainage Condition Class', 'Pavement Condition Class', 'Delivery Vehicle (veh/day)', 'Articulated Truck (veh/day)', 'Traffic Annual Growth Scenario', 'or_section_large_bus', 'or_link_class', 'or_link_direct_population', 'or_link_district_gso', 'or_link_indirect_population', 'or_link_length', 'or_link_name', 'or_section_articulated_truck', 'or_section_carriageway', 'or_section_commune_gso', 'or_section_delivery_vehicle', 'or_section_four_wheel', 'or_section_heavy_truck', 'or_section_lanes', 'or_section_length', 'or_section_light_truck', 'or_section_medium_bus', 'or_section_medium_car', 'or_section_medium_truck', 'or_section_moisture', 'or_section_motorcycle', 'or_section_name', 'or_section_pavement', 'or_section_pavement_age', 'or_section_pavement_condition', 'or_section_sequence', 'or_section_small_bus', 'or_section_small_car', 'or_section_surface', 'or_section_temperature', 'or_section_terrain', 'or_section_traffic', 'or_section_traffic_growth' ];

console.log(headers.join(','));
collect(input, (i) => {
    i.forEach(feature => {
        // we export only sections with vpromm ids.
        if (feature.properties.hasOwnProperty('or_vpromms')) {
            feature.properties['orma_way_id'] = feature.way_id;
            feature.properties['vpromm_id'] = feature.properties.or_vpromms;
            feature.properties['section_id'] = feature.properties.or_section;
            feature.properties['link_id'] = feature.properties.or_link;
            console.log(headers.map(h => feature.properties[h]).join(','));
        }
    });
});