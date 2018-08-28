BEGIN;

  REFRESH MATERIALIZED VIEW points;
  REFRESH MATERIALIZED VIEW lines;
  REFRESH MATERIALIZED VIEW lines_admin;

  CREATE TEMP VIEW vpromm_lengths AS
    SELECT wt.v AS or_vpromms,
    l.district, l.province, l.length
    FROM lines_admin AS l
    LEFT JOIN current_way_tags AS wt ON
      wt.way_id = l.way_id AND
      wt.k = 'or_vpromms'
    WHERE wt.v IS NOT NULL
    GROUP BY wt.v, l.district, l.province, l.length;

  UPDATE road_properties
  SET properties = properties || JSONB_BUILD_OBJECT('length', lengths.length)
  FROM lengths
  WHERE id = lengths.or_vpromms;

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
