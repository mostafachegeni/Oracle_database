-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- 1. IM Area Status:
select  pool, 
        ROUND(alloc_bytes/1024/1024/1024)               allocated_GB, 
        ROUND(used_bytes/1024/1024/1024)                used_GB, 
        ROUND((alloc_bytes-used_bytes)/1024/1024/1024)    free_GB, 
        populate_status, 
        con_id 
    from V$INMEMORY_AREA;



-- Function to convert high_value from "LONG" to "DATE":
CREATE OR REPLACE FUNCTION partition_hv_to_date (p_table_owner    IN VARCHAR2,
                                                 p_table_name     IN VARCHAR2,
                                                 p_partition_name IN VARCHAR2)
  RETURN DATE
AS
    l_high_value VARCHAR2(1000);
    l_date DATE;
BEGIN
    -- As "LONG" cannot be passed as a parameter, we should re-select the value from the view.
    SELECT high_value INTO   l_high_value
        FROM        dba_tab_partitions
        WHERE       table_owner    = p_table_owner
            AND     table_name     = p_table_name
            AND     partition_name = p_partition_name;

    EXECUTE IMMEDIATE 'SELECT ' || l_high_value || ' FROM dual' INTO l_date;
    RETURN l_date;
END;



-- List of In-Memory Tables:
SELECT distinct OWNER, TABLE_NAME FROM V$IM_COLUMN_LEVEL;



-- List of "Partitioned Tables" in In-Memory Area:
SELECT  a.owner                                                         table_owner, 
        a.SEGMENT_NAME                                                  table_name, 
        a.PARTITION_NAME                                                Partition_name, 
        star_etl.partition_hv_to_date(a.owner, a.SEGMENT_NAME, a.PARTITION_NAME) high_value_date, 
        round(a.BYTES/1024/1024/1024,1)                                 Bytes_GB, 
        round(a.INMEMORY_SIZE/1024/1024/1024,1)                         INMEMORY_SIZE_GB, 
        round(a.BYTES_NOT_POPULATED/1024/1024/1024,1)                   BYTES_NOT_POPULATED_GB, 
        a.POPULATE_STATUS                                               POPULATE_STATUS, 
        a.INMEMORY_COMPRESSION                                          INMEMORY_COMPRESSION, 
        a.INMEMORY_PRIORITY                                             INMEMORY_PRIORITY 
    FROM    V$IM_SEGMENTS a, 
            dba_tab_partitions b
    where   a.owner = b.TABLE_OWNER 
        AND a.SEGMENT_NAME = b.TABLE_NAME 
        AND a.PARTITION_NAME = b.PARTITION_NAME 
        --AND a.POPULATE_STATUS not like '%COMPLETE%' 
        --AND partition_hv_to_date(a.owner, a.SEGMENT_NAME, a.PARTITION_NAME) < sysdate-6 
    ORDER BY 2;



-- List of all "Segments" in In-Memory Area:
SELECT  a.owner                                                         table_owner, 
		a.SEGMENT_NAME                                                  table_name, 
		a.PARTITION_NAME                                                Partition_name, 
		mosch.partition_hv_to_date(a.owner, a.SEGMENT_NAME, a.PARTITION_NAME) high_value_date, 
	 	round(a.BYTES/1024/1024/1024)                                   Bytes_GB, 
		round(a.INMEMORY_SIZE/1024/1024/1024)                           INMEMORY_SIZE_GB, 
		round(a.BYTES_NOT_POPULATED/1024/1024/1024)                     NOT_POPULATED_GB, 
		a.POPULATE_STATUS                                               POPULATE_STATUS, 
		a.INMEMORY_COMPRESSION                                          INMEMORY_COMPRESSION, 
        a.INMEMORY_PRIORITY                                             INMEMORY_PRIORITY 
	FROM    V$IM_SEGMENTS a
	--where   a.POPULATE_STATUS not like '%COMPLETE%' 
	--where   partition_hv_to_date(a.owner, a.SEGMENT_NAME, a.PARTITION_NAME) < sysdate-6 
	--ORDER BY INMEMORY_SIZE_GB desc, high_value_date desc;
	ORDER BY high_value_date desc, INMEMORY_SIZE_GB desc;


-- List of all Tables and all Partitions that have some columns in "V$IM_COLUMN_LEVEL":
SELECT  /*+ parallel(DBA_SEGMENTS,32) */
        T.TABLE_NAME,
        T.PARTITION_NAME, 
        inventive.PARTITION_HV_TO_DATE(T.TABLE_OWNER, T.TABLE_NAME, T.PARTITION_NAME) HIGH_VALUE_DATE, 
        ROUND(S.BYTES/1024/1024/1024) Size_GB 
    FROM    (SELECT distinct OWNER , TABLE_NAME FROM V$IM_COLUMN_LEVEL) C,
            DBA_TAB_PARTITIONS T,
            DBA_SEGMENTS S
    WHERE   T.TABLE_OWNER = S.OWNER
        AND T.TABLE_OWNER = C.OWNER
        AND T.TABLE_NAME = S.SEGMENT_NAME
        AND T.TABLE_NAME = C.TABLE_NAME
        AND T.PARTITION_NAME = S.PARTITION_NAME 
        --AND S.BYTES > 20 *1024 *1024 *1024 
    ORDER BY 1, 3 desc, 4 desc;




-- List of "In-Memory Partitions" from a specific Table;
SELECT  a.owner                                                         table_owner, 
        a.SEGMENT_NAME                                                  table_name, 
        a.PARTITION_NAME                                                Partition_name, 
        mosch.partition_hv_to_date(a.owner, a.SEGMENT_NAME, a.PARTITION_NAME) high_value_date, 
        round(a.BYTES/1024/1024)                                        Bytes_MB, 
        round(a.INMEMORY_SIZE/1024/1024)                                INMEMORY_SIZE_MB, 
        round(a.BYTES_NOT_POPULATED/1024/1024)                          BYTES_NOT_POPULATED_MB, 
        a.POPULATE_STATUS                                               POPULATE_STATUS, 
        a.INMEMORY_COMPRESSION                                          INMEMORY_COMPRESSION,
        a.INMEMORY_PRIORITY                                             INMEMORY_PRIORITY 
    FROM    V$IM_SEGMENTS a
    where a.SEGMENT_NAME like ( 'REF_CBS_DATA%'
                            )
    order by a.SEGMENT_NAME, high_value_date desc;


-- Average size of "Completed In-Memory Partitions" from a specific Table;
SELECT  a.owner                                                         table_owner, 
        a.SEGMENT_NAME                                                  table_name, 
        round(avg(a.INMEMORY_SIZE/1024/1024/1024),2)                                INMEMORY_SIZE_GB
    FROM    V$IM_SEGMENTS a
    where   a.populate_status='COMPLETED'
        and a.BYTES_NOT_POPULATED = 0
        and a.SEGMENT_NAME in 
(
'REF_MSC'              ,
'REF_CBS_REC'          
)
    group by a.owner, a.SEGMENT_NAME
    order by a.owner, a.SEGMENT_NAME;



-- List of "In-Memory Columns" of a specific Table:
select a.owner, a.table_name, column_name, INMEMORY_COMPRESSION 
    from    V$IM_COLUMN_LEVEL a
    where   owner      = 'ETL_USER'
        and table_name = 'REF_CBS_REC'
    order by INMEMORY_COMPRESSION, a.owner, a.table_name, column_name;





-- NO InMemory a Partition:
declare 
    stmt varchar2(1000);
begin 
    --stmt := 'ALTER TABLE ETL_USER.REF_MSC	     MODIFY PARTITION SYS_P92693 NO INMEMORY';
    for i in 1 .. 20
    loop 
        begin 
            EXECUTE IMMEDIATE stmt;
            exit;
        exception
            when others then 
            dbms_output.put_line('Error: ' || SQLERRM );
        end;
    end loop;
end;



-- 2. "STAR", "CENTSTAR"   --->  Check "REF%" Tables In-Memory:
with REF_PARTS as (
    SELECT  a.table_owner                                                       table_owner, 
            a.table_NAME                                                        table_name, 
            a.PARTITION_NAME                                                    Partition_name, 
            mosch.partition_hv_to_date(a.table_owner, a.table_NAME, a.PARTITION_NAME) high_value_date,
            b.OBJECT_TYPE                                                       OBJECT_TYPE,
            b.created                                                           created 
        FROM    dba_tab_partitions a,
                dba_objects b
        where   a.table_owner=b.owner 
            and a.table_NAME=b.OBJECT_NAME
            and a.PARTITION_NAME=b.SUBOBJECT_NAME
            and a.TABLE_NAME like 'REF%'
            and mosch.partition_hv_to_date(a.table_owner, a.table_NAME, a.PARTITION_NAME) > sysdate - 1
            and mosch.partition_hv_to_date(a.table_owner, a.table_NAME, a.PARTITION_NAME) < sysdate
            and b.OBJECT_TYPE = 'TABLE PARTITION'
        order by 1, 2, 4 desc
    ) 
(
    select a.table_owner, a.table_name, a.PARTITION_NAME, a.high_value_date, a.OBJECT_TYPE, a.created, 
        case when b.populate_status is null then '(null)'
             else b.populate_status  end populate_status 
        from    REF_PARTS a left join V$IM_SEGMENTS b 
            on  a.table_owner=b.owner 
            and a.table_NAME=b.SEGMENT_NAME
            and a.PARTITION_NAME=b.PARTITION_NAME
        where b.SEGMENT_NAME is null 
);



-- 3. List of "STAR" Critical In-Memory Tables (5 days):
SELECT  a.owner                                                         table_owner, 
        a.SEGMENT_NAME                                                  table_name, 
        a.PARTITION_NAME                                                Partition_name, 
        partition_hv_to_date(a.owner, a.SEGMENT_NAME, a.PARTITION_NAME) high_value_date, 
        round(a.BYTES/1024/1024)                                        Bytes_MB, 
        round(a.INMEMORY_SIZE/1024/1024)                                INMEMORY_SIZE_MB, 
        round(a.BYTES_NOT_POPULATED/1024/1024)                          BYTES_NOT_POPULATED_MB, 
        a.POPULATE_STATUS                                               POPULATE_STATUS, 
        a.INMEMORY_COMPRESSION                                          INMEMORY_COMPRESSION, 
        a.INMEMORY_PRIORITY                                             INMEMORY_PRIORITY 
    FROM    V$IM_SEGMENTS a
    where a.SEGMENT_NAME in ( 'TBL_BEHSA_USDP_ONLINE_STAR' ,
                              'TBL_BEHSA_USDP_DETAIL_ONLINE_STAR'
                            )
    order by 1,2,4 desc;



-- 4. List of "CENTSTAR" Critical In-Memory Tables (7 days):
SELECT  a.owner                                                         table_owner, 
        a.SEGMENT_NAME                                                  table_name, 
        a.PARTITION_NAME                                                Partition_name, 
        partition_hv_to_date(a.owner, a.SEGMENT_NAME, a.PARTITION_NAME) high_value_date, 
        round(a.BYTES/1024/1024)                                        Bytes_MB, 
        round(a.INMEMORY_SIZE/1024/1024)                                INMEMORY_SIZE_MB, 
        round(a.BYTES_NOT_POPULATED/1024/1024)                          BYTES_NOT_POPULATED_MB, 
        a.POPULATE_STATUS                                               POPULATE_STATUS, 
        a.INMEMORY_COMPRESSION                                          INMEMORY_COMPRESSION, 
        a.INMEMORY_PRIORITY                                             INMEMORY_PRIORITY 
    FROM    V$IM_SEGMENTS a
    where a.SEGMENT_NAME in ('REF_CRM_DUMP',
                             'TBL_HSS',
                             'REF_CBS_STATUS_DUMP',
                             'REF_UVC_ACTIVE')
    order by high_value_date desc;


-- 5. List of Expired In-Memory Partitions:
select 'ALTER TABLE ' || table_owner || '.' || table_name || ' MODIFY PARTITION ' || partition_name || ' NO INMEMORY;' cmd, to_char(high_value_date, 'YYYY-MM-DD')      high_value
--select  table_owner, 
--        table_name, 
--        partition_name, 
--        to_char(high_value_date, 'YYYY-MM-DD')      high_value,   
--        round(BYTES/1024/1024/1024)                 Bytes_GB, 
--        round(INMEMORY_SIZE/1024/1024/1024)         INMEMORY_SIZE_GB, 
--        round(BYTES_NOT_POPULATED/1024/1024/1024)   BYTES_NOT_POPULATED_GB, 
--        POPULATE_STATUS                             POPULATE_STATUS, 
--        INMEMORY_COMPRESSION                        INMEMORY_COMPRESSION, 
--        INMEMORY_PRIORITY                           INMEMORY_PRIORITY 
    from    (SELECT a.owner                                                         table_owner, 
                    a.SEGMENT_NAME                                                  table_name, 
                    a.PARTITION_NAME                                                Partition_name, 
                    mosch.partition_hv_to_date(a.owner, a.SEGMENT_NAME, a.PARTITION_NAME) high_value_date, 
                    a.BYTES                                                         Bytes, 
                    a.INMEMORY_SIZE                                                 INMEMORY_SIZE, 
                    a.BYTES_NOT_POPULATED                                           BYTES_NOT_POPULATED, 
                    a.POPULATE_STATUS                                               POPULATE_STATUS, 
                    a.INMEMORY_COMPRESSION                                          INMEMORY_COMPRESSION, 
                    a.INMEMORY_PRIORITY                                             INMEMORY_PRIORITY 
        FROM    V$IM_SEGMENTS a, 
                dba_tab_partitions b
        where   a.owner = b.TABLE_OWNER 
            AND a.SEGMENT_NAME = b.TABLE_NAME 
            AND a.PARTITION_NAME = b.PARTITION_NAME 
        ORDER BY 2) table_parts
    where   high_value_date < sysdate + 1 - 5
    order by high_value_date desc, high_value_date desc;


-- 6. List of No In-Memory Partitions:
declare 
    part_name varchar2(128 byte);
    h_val date;
    date_value          DATE;
    mFlag boolean;
    cursor c1 is select a.OWNER, a.table_name from V$IM_COLUMN_LEVEL a group by a.OWNER, a.table_name;
begin 
    mFlag := false;
    
    for J in C1
    loop
        mFlag := true;
        
        for i in 1 .. 6
        loop 
            date_value := sysdate - i+1;
            
            Begin 
                select partition_name, high_value_date into part_name, h_val 
                    from    (SELECT /*+ PARALLEL(a,20) */ 
                                    a.owner                    table_owner, 
                                    a.SEGMENT_NAME             table_name, 
                                    a.PARTITION_NAME           Partition_name, 
                                    mosch.partition_hv_to_date(a.owner, a.SEGMENT_NAME, a.PARTITION_NAME) high_value_date, 
                                    a.BYTES                    Bytes, 
                                    a.INMEMORY_SIZE            INMEMORY_SIZE, 
                                    a.BYTES_NOT_POPULATED      BYTES_NOT_POPULATED, 
                                    a.POPULATE_STATUS          POPULATE_STATUS, 
                                    a.INMEMORY_COMPRESSION     INMEMORY_COMPRESSION, 
                                    a.INMEMORY_PRIORITY        INMEMORY_PRIORITY 
                        FROM    V$IM_SEGMENTS a, 
                                dba_tab_partitions b
                        where   a.owner = b.TABLE_OWNER 
                            AND a.SEGMENT_NAME = b.TABLE_NAME 
                            AND a.PARTITION_NAME = b.PARTITION_NAME 
                        ORDER BY 2) t
                    where   t.table_owner = J.OWNER 
                        AND t.table_name = J.table_name 
                        AND t.high_value_date < date_value + 1
                        AND t.high_value_date > date_value;
            EXCEPTION 
                when TOO_MANY_ROWS then 
                    dbms_output.put_line('''TOO_MANY_ROWS Exception'' for Table: ' || J.table_name);
                    EXIT;
                when NO_DATA_FOUND then 
                    if(mFlag)
                    then 
                        mFlag := false;
                        dbms_output.put_line('===============');
                    end if;
                    dbms_output.put_line('No In-Memory Partition for Table(' || J.table_name || ') -> high_value(' || to_char(date_value+1, 'YYYY-MM-DD') || ')');
                    NULL;
                when others then 
                    dbms_output.put_line('''OTHER'' Exception for Table: ' || J.table_name);
                    EXIT;
            END;
        end loop;
        
    end loop;
end;



