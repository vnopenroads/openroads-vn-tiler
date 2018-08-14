-- Grabs ways and waynodes from an OSM API v0.6 DB
-- Outputs into a .tmp directory

-- get ways that changed in the last 24 hours
  -- get ways with way timestamp < 24hours
  -- get nodes with timestamp < 24hours
     -- find all ways these nodes are members of
     -- get all nodes of the ways

BEGIN;

  CREATE TEMP VIEW all_waynodes AS
  SELECT wn.*, all_nodes.latitude, all_nodes.longitude FROM current_way_nodes wn 
  JOIN (SELECT distinct(new_ways.way_id) from (SELECT n.id, n.longitude, n.latitude from current_nodes n where (n.timestamp > NOW() - INTERVAL '24 hour')) new_nodes 
    INNER JOIN (SELECT way_id, node_id from current_way_nodes) new_ways ON new_nodes.id=new_ways.node_id
    UNION (select id from current_ways where (timestamp > NOW() - INTERVAL '24 hour'))) latest_ways ON wn.way_id=latest_ways.way_id
  JOIN current_nodes all_nodes ON wn.node_id=all_nodes.id
  ORDER BY way_id, sequence_id;

  CREATE TEMP VIEW all_waytags AS
  SELECT wt.* FROM current_way_tags wt
    JOIN current_ways w ON (wt.way_id = w.id)
    WHERE w.visible IS TRUE
    ORDER BY way_id;

  CREATE TEMP VIEW point_features AS
    SELECT JSONB_BUILD_OBJECT(
      'type', 'Feature',
      'geometry', ST_ASGEOJSON(geom)::JSONB,
      'properties', properties || JSONB_BUILD_OBJECT('or_vpromms', road_id)
    ) AS feature
    FROM point_properties;
  CREATE TEMP VIEW point_featurecollection AS
    SELECT JSONB_BUILD_OBJECT (
      'type', 'FeatureCollection',
      'features', JSONB_AGG(feature)
    )
    FROM point_features;

  CREATE TEMP VIEW ways_with_road_ids AS
    SELECT wt.way_id,
      self.vpromms_id
    FROM (
      SELECT DISTINCT wt.way_id
      FROM current_way_tags AS wt
    ) AS wt
    LEFT JOIN (
      SELECT way_id,
        v AS vpromms_id
      FROM current_way_tags
      WHERE k = 'or_vpromms'
    ) AS self ON wt.way_id = self.way_id;
  CREATE TEMP VIEW all_properties AS
    SELECT wt.way_id,
      COALESCE(rp.properties, '{}'::JSONB) AS road_properties
    FROM ways_with_road_ids AS wt
    LEFT JOIN road_properties AS rp ON rp.id = wt.vpromms_id
    ORDER BY wt.way_id;


\copy (SELECT * FROM all_waynodes) to .tmp/waynodes.csv CSV HEADER
\copy (SELECT * FROM all_waytags) to .tmp/waytags.csv CSV HEADER
\copy (SELECT * FROM point_featurecollection) to .tmp/points.geojson
\copy (SELECT * FROM all_properties) to .tmp/road_properties.csv CSV HEADER

COMMIT;
