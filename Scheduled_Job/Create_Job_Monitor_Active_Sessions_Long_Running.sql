--------------------------------------------------------------------------------
-- List of All rows in table (Inactive/Active):
-- TRUNCATE TABLE MOSCH.EXECUTION_PLAN_HISTORY;
SELECT * FROM MOSCH.EXECUTION_PLAN_HISTORY ORDER BY LAST_CALL DESC;


SELECT count(*),round(avg(last_call_et)) FROM MOSCH.EXECUTION_PLAN_HISTORY 
    WHERE   execution_plan like '%STAR_REF_CBS_REC%'
        AND username not like '%SYS%'
        AND last_call >= to_date('2021-04-05 21:00:00', 'YYYY-MM-DD HH24:MI:SS')
        AND last_call <  to_date('2021-04-05 22:00:00', 'YYYY-MM-DD HH24:MI:SS')
    ORDER BY LAST_CALL DESC;


-- List of "InActive" Sessions:
select * 
    from MOSCH.EXECUTION_PLAN_HISTORY 
    where (LAST_CALL+(LAST_CALL_ET/(24*60*60))) < (sysdate-(60/(24*60*60))) 
    order by last_call desc;

--------------------------------------------------------------------------------
--grant select on EXECUTION_PLAN_HISTORY to star_etl;
--DROP TABLE EXECUTION_PLAN_HISTORY CASCADE CONSTRAINTS PURGE;
CREATE TABLE EXECUTION_PLAN_HISTORY (
                username        varchar2(128 BYTE), 
                LAST_CALL       DATE,
                LAST_CALL_ET    NUMBER,
                session_id      number, 
                SERIAL_number   number, 
                status          varchar2(8 BYTE), 
                machine         varchar2(64 BYTE), 
                sql_id          varchar2(13 BYTE), 
                sql_statement   CLOB, 
                execution_plan  varchar2(4000), 
                CONSTRAINT EPH_PK PRIMARY KEY (session_id, SERIAL_number, sql_id)
            );

--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PROC_EXECUTION_PLAN_HISTORY 
IS 
    musername       varchar2(128 BYTE);
    mLAST_CALL      DATE;
    mLAST_CALL_ET   number;
    msession_id     number;
    mSERIAL_number  number;
    mstatus         varchar2(8 BYTE);
    mmachine        varchar2(64 BYTE);
    msql_id         varchar2(13 BYTE);

    sql_statement   CLOB;
    execution_plan  varchar2(4000);

    CURSOR c1 IS SELECT username, 
                        LAST_CALL_ET,
                        ROUND(sysdate - (LAST_CALL_ET)/(24*60*60),'MI'), 
                        SID, SERIAL#, status, machine, sql_id  
                    FROM    v$session 
                    WHERE   
                            username is not null AND
                            status = 'ACTIVE'
                        AND LAST_CALL_ET > 600;
BEGIN 

  OPEN c1; 
  
  LOOP 
    FETCH C1 INTO mUSERNAME, mLAST_CALL_ET, mLAST_CALL, mSESSION_ID, mSERIAL_NUMBER, mSTATUS, mMACHINE, mSQL_ID;
	EXIT WHEN c1%NOTFOUND;
    
    BEGIN 
        SELECT sys.stragg(plan_table_output || chr(10)) into execution_plan FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(msql_id));
        SELECT b.sql_fulltext into sql_statement FROM v$sqlarea b WHERE b.sql_id = mSQL_ID;
        INSERT INTO EXECUTION_PLAN_HISTORY(username, LAST_CALL_ET, LAST_CALL, session_id, SERIAL_number, status, machine, sql_id, sql_statement, execution_plan) 
                values (musername, mLAST_CALL_ET, mLAST_CALL, msession_id, mSERIAL_number, mstatus, mmachine, msql_id, sql_statement, execution_plan);
    EXCEPTION   
        WHEN DUP_VAL_ON_INDEX THEN
           update EXECUTION_PLAN_HISTORY 
                set LAST_CALL_ET = (sysdate - mLAST_CALL) *24*60*60  
                where   session_id = msession_id 
                    and SERIAL_number = mSERIAL_number 
                    and sql_id = msql_id;
        when TOO_MANY_ROWS then 
            NULL;
        when NO_DATA_FOUND then 
            NULL;
        when others then 
            NULL;
    END;

  END LOOP; 

  CLOSE c1; 
  COMMIT;
END;


--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_PROGRAM (program_name => 'PROG_EXECUTION_PLAN_HISTORY_2020_08_05'); END;
BEGIN
DBMS_SCHEDULER.CREATE_PROGRAM (
program_name      => 'PROG_EXECUTION_PLAN_HISTORY',
program_action    => 'PROC_EXECUTION_PLAN_HISTORY',
program_type      => 'STORED_PROCEDURE');
END;

-- BEGIN dbms_scheduler.disable('PROG_EXECUTION_PLAN_HISTORY_2020_08_05'); END;
begin 
dbms_scheduler.enable('PROG_EXECUTION_PLAN_HISTORY');
end; 


--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_SCHEDULE (schedule_name => 'SCHED_30SEC_EXECUTION_PLAN_HISTORY_2020_08_05'); END;
BEGIN
DBMS_SCHEDULER.CREATE_SCHEDULE (
 schedule_name   => 'SCHED_30SEC_EXECUTION_PLAN_HISTORY',
 start_date    => SYSTIMESTAMP,
 repeat_interval  => 'FREQ=SECONDLY; INTERVAL=30;',
 end_date     => SYSTIMESTAMP + INTERVAL '700' day,
 comments     => 'Every 30 seconds');
END;

--------------------------------------------------------------------------------
-- BEGIN DBMS_SCHEDULER.DROP_JOB (job_name => 'JOB_EXECUTION_PLAN_HISTORY_2020_08_05'); END;
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
  job_name       => 'JOB_EXECUTION_PLAN_HISTORY',
  program_name   => 'PROG_EXECUTION_PLAN_HISTORY',
  schedule_name  => 'SCHED_30SEC_EXECUTION_PLAN_HISTORY');
END;

-- BEGIN dbms_scheduler.disable('JOB_EXECUTION_PLAN_HISTORY_2020_08_05'); END;
begin 
dbms_scheduler.enable('JOB_EXECUTION_PLAN_HISTORY');
end;

--------------------------------------------------------------------------------


