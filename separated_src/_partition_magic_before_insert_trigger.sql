CREATE OR REPLACE FUNCTION _partition_magic_before_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  hasMeta      BOOLEAN;
  meta         RECORD;
  partition_id INTEGER;
  itable       TEXT;
  partitionRes BOOLEAN;
BEGIN
  hasMeta := FALSE;
  FOR meta IN SELECT *
              FROM _partition_magic_meta m
              WHERE m.table_name = TG_TABLE_NAME
  LOOP
    hasMeta := TRUE;
  END LOOP;

  IF hasMeta
  THEN
    EXECUTE format('SELECT ($1).%I', meta.action_field)
    USING NEW INTO partition_id;
    itable := meta.partition_table_prefix || partition_id :: TEXT;

    IF (NOT EXISTS(SELECT 1
                   FROM pg_tables t
                   WHERE t.schemaname = meta.schema_name AND t.tablename = itable))
    THEN
      partitionRes := _partition_magic(meta.parent_table_name, meta.action_field, partition_id, meta.schema_name,
                                       meta.partition_table_prefix, FALSE);
    END IF;

    EXECUTE 'INSERT INTO ' || itable || ' VALUES (($1).*) '
    USING NEW;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;