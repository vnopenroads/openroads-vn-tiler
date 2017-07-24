#!/usr/bin/env node

// copies closest matching vpproms point's iri value to to linestring.

var includes = require('lodash.includes');
var reduce = require('lodash.reduce');
var assign = require('lodash.assign');
var utm = require('geodesy/utm');
var distance = require('@turf/distance')
var nearest = require('@turf/nearest');
var point = require('@turf/helpers').point;
var lineString = require('@turf/helpers').lineString;
var featureCollection = require('@turf/helpers').featureCollection;
var fs = require('fs');
Promise = require('bluebird');

let roads = JSON.parse(fs.readFileSync(process.argv[2]).toString())
let points = JSON.parse(fs.readFileSync(process.argv[3]).toString());

const pointProperties = ['iri', 'or_width', 'or_class', 'or_surface'];

const utmToWGS84 = (coordinate) => {
  return utm.parse('48 N ' + coordinate.join(' '))
  .toLatLonE()
  .toString('d',10)
  .split(', ')
  .map((coord) => {
    return parseFloat(
      coord.split('°')[0]
    )
  });
}

const getClosestAttributes = (midpoint, possiblePoints) => {
  // get list of attribute objects for nearest point per pointGroup
  let points = possiblePoints.map((pointGroup) => {
    const closestPoint = nearest(midpoint, pointGroup);
    const closestDist = distance(midpoint, closestPoint)
    closestPoint.properties['distance'] = closestDist;
    return closestPoint;
  })
  let pointAttribs = points.map((point) => {
    return point.properties
  })
  // reduce that list to a single obj.
  pointAttribs = reduce(pointAttribs, (pointAttribObj, pointAttrib) => {
    return assign(pointAttribObj, pointAttrib)
  }, {})

  // replace time with time from closest point, if it exists
  let closestTime = points.filter((point) => {
    if (point.properties.time) {
      return point
    }
  })
  if (closestTime.length >= 1) {
    if (closestTime.length > 1) {
      closestTime = closestTime.sort((a, b) => {
        a.properties.distance - b.properties.distance
      })
    }
    closestTime = closestTime.map((orderedPoints) => {
      return orderedPoints.properties.time
    })[0]
    pointAttribs['time'] = closestTime;
  }
  delete pointAttribs['distance'];
  return pointAttribs;
}

// subset points to only include those with vpromms ids
points = points.features.filter((point) => {
  if (includes(Object.keys(point.properties), 'or_vpromms')) {
    point.geometry.coordinates = utmToWGS84(point.geometry.coordinates)
    return point
  }
});

// transform features into lists of lineStrings
// when feature and points' vromms id match
Promise.map(roads.features, (feature) => {
  // remove duplicate points. this is occurs due to RoadLabs' format
  let coordinates = feature.geometry.coordinates
  coordinates = Array.from(
    new Set(coordinates.map(JSON.stringify)), JSON.parse
  ).map((coordinates) => {
    return utmToWGS84(coordinates)
  })
  // make the array of coordinates basis for linestrings
  let chunkedPoints = [];
  for (var i = 0; i < coordinates.length - 1; i++) {
    chunkedPoints.push([
      coordinates[i],
      coordinates[i+1]
    ]);
  }
  // return list of 'possiblePoint' groups only if feature has vpromms id.
  // points in point groups share the same id as roads.
  let possiblePoints;
  if (includes(Object.keys(feature.properties)), 'or_vpromms') {
    // filter list to only those with vrpomms id that matches feature's
    possiblePoints = points.filter((point) => {
      if (point.properties['or_vpromms'] === feature.properties['or_vpromms']) {
        return point
      }
    })
    possiblePoints = pointProperties.map((property) => {
      return possiblePoints.filter((point) => {
        if (includes(Object.keys(point.properties), property)) {
          return point
        }
      })
    }).filter((features) => {
      return features.length > 0
    })
    if( possiblePoints.length > 0) {
      possiblePoints = possiblePoints.map((pointGroup) => {
        return featureCollection(
          pointGroup
        )
      })
    }
  }
  // return list of lineStrings that include properties from closest possiblePoints
  // if there are no possiblePoints, make the lineString 'attributeless'
  return chunkedPoints.map((pointChunk) => {
    const yCoords = (pointChunk[0][0] + pointChunk[1][0]) / 2
    const xCoords = (pointChunk[0][1] + pointChunk[1][1]) / 2
    const midpoint = point([yCoords, xCoords]);
    return lineString(
      pointChunk,
      possiblePoints.length > 0 ? getClosestAttributes(midpoint, possiblePoints) : {}
    )
  })
}).then((features) => {
  // merge each feature's list of features
  features = [].concat.apply([], features);
  console.log(features);
  // make it a feature collection and return
  features = featureCollection(features)
  fs.writeFileSync('output.geojson', JSON.stringify(features));
});
