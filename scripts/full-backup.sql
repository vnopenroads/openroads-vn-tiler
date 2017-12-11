BEGIN;

	-- These are all the tables currently in use by ORMA–VN,
	-- as of December 2017. More may be needed later on.
	-- Cannot simply run a full database dump with `pg_dump`,
	-- since certain tables in the scema have odd permissions,
	-- due to the PostGIS Docker image used to initially create the db.

	\copy users TO './make-full-backup.tmp/users.copy';
	\copy changesets TO './make-full-backup.tmp/changesets.copy';
	\copy current_nodes TO './make-full-backup.tmp/current_nodes.copy';
	\copy current_way_nodes TO './make-full-backup.tmp/current_way_nodes.copy';
	\copy current_way_tags TO './make-full-backup.tmp/current_way_tags.copy';
	\copy current_ways TO './make-full-backup.tmp/current_ways.copy';
	\copy field_data_geometries TO './make-full-backup.tmp/field_data_geometries.copy';
	\copy point_properties TO './make-full-backup.tmp/point_properties.copy';
	\copy road_properties TO './make-full-backup.tmp/road_properties.copy';
	\copy tasks TO './make-full-backup.tmp/tasks.copy';

COMMIT;
