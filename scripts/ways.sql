-- Grabs ways and waynodes from an OSM API v0.6 DB
-- Outputs into a .tmp directory

BEGIN;
  CREATE TEMP VIEW all_waynodes AS
  SELECT wn.*, n.longitude, n.latitude FROM current_way_nodes wn
    JOIN current_ways w ON (wn.way_id = w.id)
    JOIN current_nodes n ON (wn.node_id = n.id)
    WHERE w.visible IS TRUE
    ORDER BY way_id, sequence_id;

  CREATE TEMP VIEW all_waytags AS
  SELECT wt.* FROM current_way_tags wt
    JOIN current_ways w ON (wt.way_id = w.id)
    WHERE w.visible IS TRUE
    ORDER BY way_id;


\copy (SELECT * FROM all_waynodes) to .tmp/waynodes.csv CSV HEADER
\copy (SELECT * FROM all_waytags) to .tmp/waytags.csv CSV HEADER

COMMIT;
