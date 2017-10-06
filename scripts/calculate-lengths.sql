BEGIN;

  CREATE TEMP VIEW points AS
    SELECT wn.way_id,
      ST_MAKEPOINT(
        n.longitude::FLOAT / 10000000,
        n.latitude::FLOAT / 10000000
      ) AS geom
    FROM current_way_nodes AS wn
    LEFT JOIN current_ways AS w ON wn.way_id = w.id
    LEFT JOIN current_nodes AS n ON wn.node_id = n.id
    WHERE w.visible IS TRUE
    ORDER BY way_id,
      sequence_id;

  CREATE TEMP VIEW lines AS
    SELECT way_id,
      ST_MAKELINE(ARRAY_AGG(geom)) AS geom
    FROM points
    GROUP BY way_id;

  CREATE TEMP VIEW lengths AS
    SELECT wt.v AS or_vpromms,
      AVG(ST_LENGTH(l.geom::GEOGRAPHY)) / 1000 AS length
    FROM lines AS l
    LEFT JOIN current_way_tags AS wt ON
      wt.way_id = l.way_id AND
      wt.k = 'or_vpromms'
    WHERE wt.v IS NOT NULL
    GROUP BY wt.v;

  UPDATE road_properties
  SET properties = properties || JSONB_BUILD_OBJECT('length', lengths.length)
  FROM lengths
  WHERE id = lengths.or_vpromms;

COMMIT;
