-- Truncate and upload new tasks

BEGIN;
  TRUNCATE TABLE tasks;
  \copy tasks(way_id, neighbors, provinces) from .tmp/tasks.csv WITH (FORMAT csv)

COMMIT;
