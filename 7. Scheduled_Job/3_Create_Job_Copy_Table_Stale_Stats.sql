--------------------------------------------------------------------------------
/*
-- 4. Configure 'INCREMENTAL_STALENESS':
SQL> SYS.dbms_stats.set_table_prefs(ownname=>'OWNER', tabname=>'TABLE_NAME', pname =>'INCREMENTAL_STALENESS', pvalue=>'USE_STALE_PERCENT, USE_LOCKED_STATS');
SQL> SELECT dbms_stats.get_prefs(ownname=>'OWNER', tabname=>'TABLE_NAME', pname => 'INCREMENTAL_STALENESS') FROM DUAL;


-- 5. Enable 'INCREMENTAL' Statistics:
SQL> SYS.dbms_stats.set_table_prefs(ownname=>'OWNER', tabname=>'TABLE_NAME', pname =>'INCREMENTAL', pvalue=>'TRUE');
SQL> SELECT dbms_stats.get_prefs(ownname=>'OWNER', tabname=>'TABLE_NAME', pname => 'INCREMENTAL') FROM DUAL;
*/
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE INVENTIVE.PROC_COPY_TABLE_STALE_STATS 
IS 
    m_owner         VARCHAR2(128 Byte); 
    m_TABLE_NAME    VARCHAR2(128 Byte); 
    m_part_name     VARCHAR2(128 Byte); 
    m_highval       DATE;
BEGIN 

    -- Flush statistics to Disk to see the changes immediately (Insufficient Privillege):
--    dbms_stats.flush_database_monitoring_info;

    -- All "non-InMemory" Partitions:
    for i in (SELECT    a.owner, a.TABLE_NAME, a.partition_name, a.num_rows, a.global_stats, a.last_analyzed, a.stattype_locked, a.stale_stats, 
                        INVENTIVE.hv_to_date(a.owner, a.table_name, a.partition_name) high_value,
                        b.POPULATE_STATUS 
                FROM dba_tab_statistics a left join v$im_segments b
                    ON      a.owner=b.owner
                        AND a.table_name=b.SEGMENT_NAME
                        AND a.partition_name=b.partition_name
                WHERE   a.OWNER = 'INVENTIVE' 
                    AND a.table_name like 'TBL_%'
                    AND (a.stale_stats is NULL)
                    AND (a.partition_name IS NOT NULL)
                    --AND INVENTIVE.hv_to_date(a.owner, a.table_name, a.partition_name) > sysdate - 60 
                    --AND INVENTIVE.hv_to_date(a.owner, a.table_name, a.partition_name) < sysdate - 0 
                    --AND (b.POPULATE_STATUS IS NULL)
                order by high_value desc
                )
    loop 
        Begin 

            -- Find a "non-Stale stats" Partitions:
            SELECT  a.owner, a.TABLE_NAME, a.partition_name, 
                    INVENTIVE.hv_to_date(a.owner, a.table_name, a.partition_name) high_value 
                INTO m_owner, m_TABLE_NAME, m_part_name, m_highval
                FROM dba_tab_statistics a left join v$im_segments b
                    ON      a.owner=b.owner
                        AND a.table_name=b.SEGMENT_NAME
                        AND a.partition_name=b.partition_name
                WHERE   a.OWNER = i.owner 
                    AND a.table_name = i.table_name 
                    AND (a.stale_stats = 'NO')
                    AND (a.partition_name IS NOT NULL)
                    AND INVENTIVE.hv_to_date(a.owner, a.table_name, a.partition_name) > sysdate - 60 
                    AND INVENTIVE.hv_to_date(a.owner, a.table_name, a.partition_name) < sysdate - 0 
                    AND (b.POPULATE_STATUS IS NULL)
                    AND rownum < 2
                order by high_value desc;


            -- Copy Statistics of a Partition to another Partition:
            SYS.DBMS_STATS.COPY_TABLE_STATS( 
                ownname     => i.owner, 
                tabname     => i.table_name, 
                srcpartname => m_part_name, 
                dstpartname => i.partition_name, 
                force       => TRUE);


            -- Lock Statistics of all Partitions:
            SYS.DBMS_STATS.LOCK_PARTITION_STATS(
                ownname  => i.owner, 
                tabname  => i.table_name, 
                partname => i.partition_name);


        EXCEPTION   
            WHEN DUP_VAL_ON_INDEX THEN
                NULL;
            when TOO_MANY_ROWS then 
                NULL;
            when NO_DATA_FOUND then 
                NULL;
            when others then 
                NULL;

        End;
    End loop; 

    --COMMIT;

END;

--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_PROGRAM (program_name => 'PROG_COPY_TABLE_STALE_STATS'); END;
BEGIN
DBMS_SCHEDULER.CREATE_PROGRAM (
program_name      => 'PROG_COPY_TABLE_STALE_STATS',
program_action    => 'PROC_COPY_TABLE_STALE_STATS',
program_type      => 'STORED_PROCEDURE');
END;

-- BEGIN DBMS_SCHEDULER.DISABLE('PROG_COPY_TABLE_STALE_STATS'); END;
BEGIN 
DBMS_SCHEDULER.ENABLE('PROG_COPY_TABLE_STALE_STATS');
END; 


--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_SCHEDULE (schedule_name => 'SCHED_1DAY_COPY_TABLE_STALE_STATS'); END;
BEGIN
DBMS_SCHEDULER.CREATE_SCHEDULE (
 schedule_name    => 'SCHED_1DAY_COPY_TABLE_STALE_STATS',
 start_date       => SYSTIMESTAMP - INTERVAL '5' hour,
 repeat_interval  => 'FREQ=DAILY; INTERVAL=1;',
 end_date         => SYSTIMESTAMP + INTERVAL '10000' day,
 comments         => 'Every 1 days');
END;

--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_JOB (job_name => 'JOB_COPY_TABLE_STALE_STATS'); END;
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
  job_name       => 'JOB_COPY_TABLE_STALE_STATS',
  program_name   => 'PROG_COPY_TABLE_STALE_STATS',
  schedule_name  => 'SCHED_1DAY_COPY_TABLE_STALE_STATS');
END;

-- BEGIN  DBMS_SCHEDULER.DISABLE('JOB_COPY_TABLE_STALE_STATS'); END;
BEGIN 
DBMS_SCHEDULER.ENABLE('JOB_COPY_TABLE_STALE_STATS');
END;


--------------------------------------------------------------------------------
-- SELECT SQL_ID, SQL_FULLTEXT FROM V$SQL WHERE SQL_ID='c21nzt2671xa3';
-- SELECT sys.stragg(plan_table_output || chr(10)) FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('c21nzt2671xa3'));
--------------------------------------------------------------------------------

