BEGIN;

  DROP VIEW vpromm_lengths;
  DROP MATERIALIZED VIEW lines_admin;
  DROP MATERIALIZED VIEW lines;
  DROP MATERIALIZED VIEW points;

  CREATE MATERIALIZED VIEW points AS
  SELECT wn.way_id,
      ST_MAKEPOINT(
      n.longitude::FLOAT / 10000000,
      n.latitude::FLOAT / 10000000
      ) AS geom
  FROM current_way_nodes AS wn
  LEFT JOIN current_ways AS w ON wn.way_id = w.id
  LEFT JOIN current_nodes AS n ON wn.node_id = n.id
  WHERE w.visible IS TRUE
  ORDER BY wn.way_id,
      wn.sequence_id;

  CREATE index points_geom_idx on points using gist(geom);

  CREATE MATERIALIZED VIEW lines AS
  SELECT way_id,
      ST_MAKELINE(ARRAY_AGG(geom)) AS geom
  FROM points
  GROUP BY way_id;

  CREATE index lines_geom_idx on lines using gist(geom);

  CREATE MATERIALIZED VIEW lines_admin AS
  SELECT l.way_id, l.geom,
  AVG(ST_LENGTH(l.geom::GEOGRAPHY)) / 1000 AS length,
  a.id as district, a.parent_id as province
  FROM lines AS l, admin_boundaries AS a
  WHERE ST_Intersects(a.geom, l.geom) AND a.type='district'
  GROUP BY way_id, l.geom, a.id, a.parent_id;

  CREATE VIEW vpromm_lengths AS
    SELECT wt.v AS or_vpromms,
    l.district, l.province, SUM(l.length) as length
    FROM lines_admin AS l
    LEFT JOIN current_way_tags AS wt ON
      wt.way_id = l.way_id AND
      wt.k = 'or_vpromms'
    WHERE wt.v IS NOT NULL
    GROUP BY wt.v, l.district, l.province;

  UPDATE road_properties
  SET properties = properties || JSONB_BUILD_OBJECT('length', vpromm_lengths.length)
  FROM vpromm_lengths
  WHERE id = vpromm_lengths.or_vpromms;

  UPDATE admin_boundaries a
  SET total_length = l.sum
  FROM (SELECT district, SUM(length) FROM lines_admin GROUP BY district) AS l
  WHERE l.district = a.id;

  UPDATE admin_boundaries a
  SET total_length = l.sum
  FROM (SELECT province, SUM(length) FROM lines_admin GROUP BY province) AS l
  WHERE l.province = a.id;

  UPDATE admin_boundaries a
  SET vpromm_length = l.sum
  FROM (SELECT district, SUM(length) FROM vpromm_lengths GROUP BY district) AS l
  WHERE l.district = a.id;

  UPDATE admin_boundaries a
  SET vpromm_length = l.sum
  FROM (SELECT province, SUM(length) FROM vpromm_lengths GROUP BY province) AS l
  WHERE l.province = a.id;

COMMIT;
