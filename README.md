# openroads-tiler

Generates tiles from an OSM API v0.6 compatible database and pushes the tiles to S3.

## Running locally
### requirements
- psql
- tippecanoe
- node 6 & yarn

** Environment variables ** 
Set these in a `.env` file

```
DATABASE_URL=... # e.g. postgres://localhost/openroads
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=... 
S3_BUCKET=... # e.g. openroads-tiler
```

### install & run
```
yarn
yarn start
```

## docker 
For deployment a dockerfile is provided.

## license
MIT
