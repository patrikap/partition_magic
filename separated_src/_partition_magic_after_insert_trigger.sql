CREATE OR REPLACE FUNCTION _partition_magic_after_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  hasMeta BOOLEAN;
  meta    RECORD;
  itable  TEXT;
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
    EXECUTE 'DELETE FROM ONLY ' || meta.parent_table_name || ' WHERE id = ' || NEW.id || ';';
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;