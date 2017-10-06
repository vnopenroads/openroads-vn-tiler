-- Calculate IRI summary statistics for each road ID
-- Source: `point_properties` table, all field-data runs for that road ID
-- Destination: update `road_properties` properties object

BEGIN;

	CREATE TEMP VIEW iri_stats AS
		SELECT road_id,
			JSONB_BUILD_OBJECT(
				'iri_min', MIN((properties ->> 'iri')::FLOAT),
				'iri_mean', AVG((properties ->> 'iri')::FLOAT),
				'iri_med', PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY (properties ->> 'iri')::FLOAT),
				'iri_max', MAX((properties ->> 'iri')::FLOAT)
			) AS iri_properties
		FROM point_properties
		WHERE road_id IS NOT NULL
		GROUP BY road_id;

	UPDATE road_properties
	SET properties = properties || iri_properties
	FROM iri_stats AS iri
	WHERE id = iri.road_id;

COMMIT;
