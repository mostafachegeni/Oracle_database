--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SCHEMA.PROC_REBUILD_UNUSABLE_INDEXES_1
IS 
    v_username      varchar2(128 BYTE);
    v_err_code      NUMBER; 
    v_err_msg       varchar2(4000);
    stmt            varchar2(4000);
BEGIN 

    -- List of "Unusable" Index Partitions on "Non-InMemory" Table Partitions:
    for i in    (WITH unusable_index_parts AS 
                    (select a.owner, a.index_name, c.partition_name index_partition_name, a.table_name, b.object_type, c.status index_status, b.created CREATED 
                        from dba_indexes a, dba_objects b, dba_ind_partitions c
                        where   a.owner=b.owner 
                            and a.owner=c.index_owner
                            and a.index_name=b.object_name 
                            and a.index_name=c.index_name 
                            and b.subobject_name=c.partition_name 
                            and (a.owner = 'SCHEMA')
                            and a.partitioned = 'YES'
                            and c.status = 'UNUSABLE'
                        order by created desc
                    )
                    select  a.owner, a.table_name, a.INDEX_NAME, a.index_partition_name,  
                            case when b.populate_status is null then '(null)'
                                 else b.populate_status  end populate_status 
                            ,SCHEMA.partition_hv_to_date(a.owner, a.table_name, a.index_partition_name) high_value
                        from unusable_index_parts a left join v$im_segments b 
                            ON      a.owner=b.owner
                                AND a.table_name=b.SEGMENT_NAME
                                AND a.index_partition_name=b.partition_name
                        WHERE   b.POPULATE_STATUS IS NULL 
                            AND (a.table_name like ( 'TBL_%' ) AND a.table_name != 'TBL_PGW')
                            and SCHEMA.partition_hv_to_date(a.owner, a.table_name, a.index_partition_name) <> trunc(sysdate+1)
                            and NOT(
                                 (a.owner='SCHEMA' and a.table_name in('TBL_CBS_DATA_REJECT_PRE','TBL_CBS_DATA_REJECT_POST','TBL_VGS') and SCHEMA.partition_hv_to_date(a.owner, a.table_name, a.index_partition_name)<=trunc(sysdate+1-15)  ) OR 
                                 (a.owner='SCHEMA' and a.table_name in('TBL_VGS_PHL','TBL_VGS_KISH','TBL_PGW')                         and SCHEMA.partition_hv_to_date(a.owner, a.table_name, a.index_partition_name)<=trunc(sysdate+1-15)  ) OR 
                                 (a.owner='SCHEMA' and a.table_name in('TBL_CBS_DATA_PRE','TBL_CBS_DATA_POST')                         and SCHEMA.partition_hv_to_date(a.owner, a.table_name, a.index_partition_name)<=trunc(sysdate+1-15) ) OR 
                                 (a.owner='SCHEMA' and a.table_name in('TBL_MOBINNET')                                                 and SCHEMA.partition_hv_to_date(a.owner, a.table_name, a.index_partition_name)<=trunc(sysdate+1-15) )    
                            )
                 )
    loop
        Begin 
            stmt := 'ALTER INDEX ' || i.owner || '.' || i.INDEX_NAME || ' REBUILD PARTITION ' || i.index_partition_name || ' PARALLEL 20 NOLOGGING' ;
            EXECUTE IMMEDIATE stmt;
        EXCEPTION   
            when others then 
                v_err_code := SQLCODE;
                v_err_msg  := SUBSTR(SQLERRM, 1, 4000);
                select user into v_username from dual;
                INSERT INTO SCHEMA.TABLE_JOBS_ERR_LOG    (USERNAME, JOB_NAME, RUN_TIMESTAMP, STMT, ERROR_CODE, ERROR_MESSAGE) 
                            VALUES                          (v_username, 'JOB_REBUILD_UNUSABLE_INDEXES_1', SYSTIMESTAMP, stmt, v_err_code, v_err_msg);

                COMMIT;

        End;
    End loop; 

    --COMMIT;
END;

--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_PROGRAM (program_name => 'PROG_REBUILD_UNUSABLE_INDEXES_1'); END;
BEGIN
DBMS_SCHEDULER.CREATE_PROGRAM (
program_name      => 'PROG_REBUILD_UNUSABLE_INDEXES_1',
program_action    => 'PROC_REBUILD_UNUSABLE_INDEXES_1',
program_type      => 'STORED_PROCEDURE');
END;

-- BEGIN DBMS_SCHEDULER.DISABLE('PROG_REBUILD_UNUSABLE_INDEXES_1'); END;
BEGIN 
DBMS_SCHEDULER.ENABLE('PROG_REBUILD_UNUSABLE_INDEXES_1');
END; 


--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_SCHEDULE (schedule_name => 'SCHED_1DAY_REBUILD_UNUSABLE_INDEXES_1'); END;
BEGIN
DBMS_SCHEDULER.CREATE_SCHEDULE (
 schedule_name    => 'SCHED_1DAY_REBUILD_UNUSABLE_INDEXES_1',
 start_date       => SYSTIMESTAMP - INTERVAL '1' minute,
 repeat_interval  => 'FREQ=DAILY; ByHour=2,3,4; byminute=30; bysecond=0;',
 end_date         => SYSTIMESTAMP + INTERVAL '10000' day,
 comments         => 'Every 1 days');
END;

--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_JOB (job_name => 'JOB_REBUILD_UNUSABLE_INDEXES_1'); END;
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
  job_name       => 'JOB_REBUILD_UNUSABLE_INDEXES_1',
  program_name   => 'PROG_REBUILD_UNUSABLE_INDEXES_1',
  schedule_name  => 'SCHED_1DAY_REBUILD_UNUSABLE_INDEXES_1');
END;

-- BEGIN  DBMS_SCHEDULER.DISABLE('JOB_REBUILD_UNUSABLE_INDEXES_1'); END;
BEGIN 
DBMS_SCHEDULER.ENABLE('JOB_REBUILD_UNUSABLE_INDEXES_1');
END;


--------------------------------------------------------------------------------
-- SELECT SQL_ID, SQL_FULLTEXT FROM V$SQL WHERE SQL_ID='c21nzt2671xa3';
-- SELECT sys.stragg(plan_table_output || chr(10)) FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('c21nzt2671xa3'));
--------------------------------------------------------------------------------

