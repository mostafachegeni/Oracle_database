CREATE OR REPLACE FUNCTION INVENTIVE.hv_to_date (p_table_owner    IN  VARCHAR2,
                                            p_table_name     IN VARCHAR2,
                                            p_partition_name IN VARCHAR2)
  RETURN DATE
AS
  l_high_value VARCHAR2(32767);
  l_date DATE;
BEGIN
  SELECT high_value
  INTO   l_high_value
  FROM   all_tab_partitions
  WHERE  table_owner    = p_table_owner
  AND    table_name     = p_table_name
  AND    partition_name = p_partition_name;
  EXECUTE IMMEDIATE 'SELECT ' || l_high_value || ' FROM dual' INTO l_date;
  RETURN l_date;
END;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION INVENTIVE.partition_hv_to_date (p_table_owner    IN VARCHAR2,
                                                 p_table_name     IN VARCHAR2,
                                                 p_partition_name IN VARCHAR2)
  RETURN DATE
AS
    l_high_value VARCHAR2(1000);
    l_date DATE;
BEGIN
    SELECT high_value INTO   l_high_value
        FROM        dba_tab_partitions
        WHERE       table_owner    = p_table_owner
            AND     table_name     = p_table_name
            AND     partition_name = p_partition_name;

    EXECUTE IMMEDIATE 'SELECT ' || l_high_value || ' FROM dual' INTO l_date;
    RETURN l_date;
END;

