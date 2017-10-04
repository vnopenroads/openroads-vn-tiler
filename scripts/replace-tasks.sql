-- Truncate and upload new tasks

BEGIN;
  TRUNCATE TABLE tasks;
  \copy tasks(way_id, neighbors) from .tmp/tasks.csv WITH (FORMAT csv)

COMMIT;
