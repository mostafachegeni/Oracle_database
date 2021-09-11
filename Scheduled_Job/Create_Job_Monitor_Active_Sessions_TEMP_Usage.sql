--------------------------------------------------------------------------------
-- List of All Sessions in table "TBL_TEMP_USAGE_HISTORY" (Inactive/Active):
-- TRUNCATE TABLE MOSCH.TBL_TEMP_USAGE_HISTORY ;
SELECT last_call+((LAST_CALL_ET)/(24*60*60)) Finish_date, a.* FROM MOSCH.TBL_TEMP_USAGE_HISTORY a ORDER BY LAST_CALL DESC;

SELECT case when (last_call+((LAST_CALL_ET)/(24*60*60))) > sysdate - (120/(24*60*60)) then 'RUNNING...'
            else to_char((last_call+((LAST_CALL_ET)/(24*60*60))), 'YYYY/MM/DD HH24:MI:SS') end Finish_date, 
       a.* FROM MOSCH.TBL_TEMP_USAGE_HISTORY a 
    WHERE   LAST_CALL <                             TO_DATE('2021-01-09 02:50:00', 'YYYY-MM-DD HH24:MI:SS')
        AND LAST_CALL+((LAST_CALL_ET)/(24*60*60)) > TO_DATE('2021-01-09 02:50:00', 'YYYY-MM-DD HH24:MI:SS')
    ORDER BY TEMP_USED_GB DESC;

-- List of Running Sessions in "TBL_TEMP_USAGE_HISTORY":
SELECT * FROM MOSCH.TBL_TEMP_USAGE_HISTORY where last_call + ((LAST_CALL_ET)/(24*60*60)) > sysdate - interval '10' minute ORDER BY LAST_CALL DESC;



--------------------------------------------------------------------------------
-- DROP TABLE TBL_TEMP_USAGE_HISTORY CASCADE CONSTRAINTS PURGE;
CREATE TABLE TBL_TEMP_USAGE_HISTORY ( 
                username        varchar2(128 BYTE),
                LAST_CALL       DATE,
                LAST_CALL_ET    NUMBER,
                SID             NUMBER, 
                SERIAL#         NUMBER, 
                STATUS          varchar2(8 BYTE), 
                MACHINE         varchar2(64 BYTE),
                SQL_ID          varchar2(13 BYTE), 
                SPID            varchar2(24 BYTE),
                EVENT           varchar2(64 BYTE),
                Tablespace_Name varchar2(30 BYTE),
                SEGTYPEs        varchar2(4000),
                TEMP_USED_GB    NUMBER,
                sql_statement   CLOB, 
                execution_plan  varchar2(4000), 

                CONSTRAINT TEMP_USAGE_HISTORY_PK PRIMARY KEY (SID, SERIAL#, sql_id)
            );

--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PROC_TEMP_USAGE_HISTORY 
IS 
  sql_LAST_CALL       date;
  sql_LAST_CALL_ET       NUMBER;
  sql_statement   CLOB;
  execution_plan  varchar2(4000);
BEGIN 
  FOR m_cursor in  (select  TU.username, S.LAST_CALL_ET, S.SID, S.SERIAL#, S.STATUS, S.MACHINE, S.SQL_ID Current_SQL_ID, TU.sql_id_tempseg TEMPSEG_SQL_ID, TU.TABLESPACE Tablespace_Name,
                            ROUND(SUM(TU.BLOCKS)*TS.BLOCK_SIZE/1024/1024/1024,1) TEMP_USED_GB,
                            listagg(TU.SEGTYPE || ', ') within Group (order by TU.SEGTYPE) SEGTYPEs 
                        from    V$TEMPSEG_USAGE TU, 
                                DBA_TABLESPACES TS,
                                V$SESSION S
                        WHERE   S.serial#=TU.session_num
                            and S.SADDR=TU.SESSION_ADDR
                            and TU.TABLESPACE=TS.TABLESPACE_NAME
                            and TS.CONTENTS='TEMPORARY'
                        GROUP BY TU.username, S.LAST_CALL_ET, S.SID, S.SERIAL#, S.STATUS, S.MACHINE, S.SQL_ID, TU.sql_id_tempseg, TU.TABLESPACE, TS.BLOCK_SIZE
                        order by TEMP_USED_GB desc)
  LOOP 
    
    -- if TEMP_Usage < 50GB ignore it.
    IF (m_cursor.TEMP_USED_GB < 50) then
        CONTINUE;
    END IF;
    
	BEGIN 
            IF (m_cursor.TEMPSEG_SQL_ID = m_cursor.Current_SQL_ID AND m_cursor.STATUS = 'ACTIVE') THEN
                sql_LAST_CALL := ROUND(sysdate - (m_cursor.LAST_CALL_ET)/(24*60*60),'MI');
                sql_LAST_CALL_ET := (sysdate - sql_LAST_CALL) *24*60*60;
            ELSE
                sql_LAST_CALL := NULL;
                sql_LAST_CALL_ET := NULL;
            END IF;

            SELECT sys.stragg(plan_table_output || chr(10)) into execution_plan FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(m_cursor.TEMPSEG_SQL_ID));
            SELECT b.sql_fulltext into sql_statement FROM v$sqlarea b WHERE b.sql_id = m_cursor.TEMPSEG_SQL_ID;
            INSERT INTO TBL_TEMP_USAGE_HISTORY(username,LAST_CALL,LAST_CALL_ET,SID,SERIAL#,STATUS,MACHINE,SQL_ID,Tablespace_Name,SEGTYPEs,TEMP_USED_GB,sql_statement,execution_plan) 
                    values (m_cursor.username,sql_LAST_CALL,sql_LAST_CALL_ET,m_cursor.SID,m_cursor.SERIAL#,m_cursor.STATUS,m_cursor.MACHINE,m_cursor.TEMPSEG_SQL_ID,m_cursor.Tablespace_Name,m_cursor.SEGTYPEs,m_cursor.TEMP_USED_GB,sql_statement,execution_plan);
	EXCEPTION   
            WHEN DUP_VAL_ON_INDEX THEN
                -- Update LAST_CALL_ET:
                update TBL_TEMP_USAGE_HISTORY set LAST_CALL_ET = (sysdate - LAST_CALL) *24*60*60 where SID = m_cursor.SID and SERIAL# = m_cursor.SERIAL# and sql_id = m_cursor.TEMPSEG_SQL_ID;

                -- Update STATUS:
                update TBL_TEMP_USAGE_HISTORY set STATUS = m_cursor.STATUS where SID = m_cursor.SID and SERIAL# = m_cursor.SERIAL# and sql_id = m_cursor.TEMPSEG_SQL_ID;
                
                -- Update TEMP_USED_GB:
                DECLARE
                    m_temp_usage number;
                BEGIN
                    select TEMP_USED_GB into m_temp_usage from TBL_TEMP_USAGE_HISTORY where SID = m_cursor.SID and SERIAL# = m_cursor.SERIAL# and sql_id = m_cursor.TEMPSEG_SQL_ID;
                    if(m_cursor.TEMP_USED_GB > m_temp_usage)
                    then
                       update TBL_TEMP_USAGE_HISTORY set TEMP_USED_GB = m_cursor.TEMP_USED_GB where SID = m_cursor.SID and SERIAL# = m_cursor.SERIAL# and sql_id = m_cursor.TEMPSEG_SQL_ID;                
                    end if;
                END;
            when TOO_MANY_ROWS then 
                NULL;
            when NO_DATA_FOUND then 
                NULL;
            when others then 
                NULL;
	END;

  END LOOP; 

  COMMIT;
END;


--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_PROGRAM (program_name => 'PROG_TEMP_USAGE_HISTORY'); END;
BEGIN
DBMS_SCHEDULER.CREATE_PROGRAM (
program_name      => 'PROG_TEMP_USAGE_HISTORY',
program_action    => 'PROC_TEMP_USAGE_HISTORY',
program_type      => 'STORED_PROCEDURE');
END;

-- BEGIN DBMS_SCHEDULER.DISABLE('PROG_TEMP_USAGE_HISTORY'); END;
BEGIN 
DBMS_SCHEDULER.ENABLE('PROG_TEMP_USAGE_HISTORY');
END; 


--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_SCHEDULE (schedule_name => 'SCHED_30SEC_TEMP_USAGE_HISTORY'); END;
BEGIN
DBMS_SCHEDULER.CREATE_SCHEDULE (
 schedule_name   => 'SCHED_30SEC_TEMP_USAGE_HISTORY',
 start_date    => SYSTIMESTAMP,
 repeat_interval  => 'FREQ=SECONDLY; INTERVAL=30;',
 end_date     => SYSTIMESTAMP + INTERVAL '365' day,
 comments     => 'Every 30 seconds');
END;

--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_JOB (job_name => 'JOB_TEMP_USAGE_HISTORY') END;
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
  job_name       => 'JOB_TEMP_USAGE_HISTORY',
  program_name   => 'PROG_TEMP_USAGE_HISTORY',
  schedule_name  => 'SCHED_30SEC_TEMP_USAGE_HISTORY');
END;

-- BEGIN  DBMS_SCHEDULER.DISABLE('JOB_TEMP_USAGE_HISTORY'); END;
BEGIN 
DBMS_SCHEDULER.ENABLE('JOB_TEMP_USAGE_HISTORY');
END;


--------------------------------------------------------------------------------
-- SELECT SQL_ID, SQL_FULLTEXT FROM V$SQL WHERE SQL_ID='c21nzt2671xa3';
-- SELECT sys.stragg(plan_table_output || chr(10)) FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('c21nzt2671xa3'));
--------------------------------------------------------------------------------
