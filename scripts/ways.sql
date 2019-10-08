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

  CREATE MATERIALIZED VIEW ways_admin AS
  SELECT l.way_id, a.id as district, a.parent_id as province
  FROM lines AS l, admin_boundaries AS a
  WHERE ST_Intersects(a.geom, l.geom) AND a.type='district'
  GROUP BY way_id, a.id, a.parent_id
  ORDER BY way_id


\copy (SELECT * FROM all_waynodes) to .tmp/waynodes.csv CSV HEADER
\copy (SELECT * FROM ways_admin) to .tmp/waysadmin.csv CSV HEADER
\copy (SELECT * FROM all_waytags) to .tmp/waytags.csv CSV HEADER
\copy (SELECT * FROM point_featurecollection) to .tmp/points.geojson
\copy (SELECT * FROM all_properties) to .tmp/road_properties.csv CSV HEADER

COMMIT;
