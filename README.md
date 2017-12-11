# OpenRoads Vietnam Tiler

A set of "worker" processes to support the OpenRoads website (repo `orma/openroads-vn-analytics`), drawing on the OpenRoads database.

Generates raster tiles from an OSM-API-v0.6-compatible database and pushes these tiles to a remote host. Additionally, runs geospatial processes and statistics, creating:

- vector tiles, that have field-data road properties conflated onto the OSM geometries
- routable dumps of the road geometries, with some properties attached, by admin area
- for each road ID in the OSM geometries, calculation of road length and summary statistics for [roughness](https://en.wikipedia.org/wiki/International_Roughness_Index), which get applied back to the database for display on the front-end
- generation of "tasks" where potential duplicate geometries are detected, or potential intersections
- a backup of the database's key tables

## Running locally

### Requirements

- `psql`
- `tippecanoe`
- `node` v6
- `yarn`

### Environment variables

The necessary environment variables are listed in the `cron.sh` file. Set these in a `.env` file when running locally.

### Setup and execution

```
yarn install
yarn start
```

To run particular processes/calculations in the `scripts` folder, first get a dump of production data using the `scripts/*.sql` commands (eg, `cd scripts; psql -d ${DATABASE_URL} -f ways.sql;`), then execute one of the scripts.

## Deployment

The worker tasks will be executed on a regular basis, as dictated in the `cron.sh` file, and all code will be packaged using the Dockerfile. To deploy to production, simply increment the version in `package.json`, push to `master`, and then update the version in the AWS configuration in the `orma/openroads-vn-api` repo accordingly (https://github.com/orma/openroads-vn-api/blob/develop/aws/app/config.yml).

## License

MIT
