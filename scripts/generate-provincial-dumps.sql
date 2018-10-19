-- Generate provincial data dumps

BEGIN;

\copy (SELECT cwt.v as vpromm_id, l.way_id as way_id, ST_AsText(l.geom) as geom, l.province as province, rp.properties as properties FROM lines_admin l LEFT JOIN (SELECT way_id, v FROM current_way_tags WHERE k='or_vpromms') AS cwt ON l.way_id = cwt.way_id LEFT JOIN (SELECT id, COALESCE(properties, '{}'::JSONB) AS properties FROM road_properties) AS rp ON cwt.v = rp.id) to .tmp/provincial_dump.csv CSV HEADER

COMMIT;