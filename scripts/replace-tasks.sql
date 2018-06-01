-- Truncate and upload new tasks

BEGIN;
  \copy tasks(way_id, neighbors, provinces) from .tmp/tasks.csv WITH (FORMAT csv)

COMMIT;
