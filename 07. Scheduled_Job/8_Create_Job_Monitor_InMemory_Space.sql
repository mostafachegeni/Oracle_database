--------------------------------------------------------------------------------
select  log_date, 
        pool, 
        con_id, 
        populate_status, 
        ROUND(allocated_bytes/1024/1024/1024)               "ALLOCATED_GB",
        ROUND(used_bytes/1024/1024/1024)                    "USED_GB", 
        ROUND((allocated_bytes-used_bytes)/1024/1024/1024)  "Free_GB" 
    from     MOSCH.IM_AREA_HISTORY 
    where    pool like '%1MB%'
    order by log_date desc;

--------------------------------------------------------------------------------
CREATE TABLE MOSCH.IM_AREA_HISTORY (
	log_date        DATE,
    pool            VARCHAR2(26 Byte), 
    populate_status VARCHAR2(26 Byte), 
    allocated_bytes number, 
    used_bytes      number, 
    con_id          number
);

--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PROC_IM_AREA_HISTORY 
IS 
    CURSOR C1 IS SELECT POOL, 
                        POPULATE_STATUS, 
                        ALLOC_BYTES, 
                        USED_BYTES, 
                        CON_ID 
                FROM V$INMEMORY_AREA;

BEGIN 

  FOR I in C1
  LOOP     
    BEGIN 
	    INSERT INTO MOSCH.IM_AREA_HISTORY 
		       VALUES   (sysdate, I.POOL, I.POPULATE_STATUS, I.ALLOC_BYTES, I.USED_BYTES, I.CON_ID);

    EXCEPTION   
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
BEGIN
DBMS_SCHEDULER.CREATE_PROGRAM (
program_name      => 'PROG_IM_AREA_HISTORY',
program_action    => 'PROC_IM_AREA_HISTORY',
program_type      => 'STORED_PROCEDURE');
END;

begin 
dbms_scheduler.enable('PROG_IM_AREA_HISTORY');
end; 


--------------------------------------------------------------------------------
BEGIN
DBMS_SCHEDULER.CREATE_SCHEDULE (
 schedule_name   => 'SCHED_1HOUR_IM_AREA_HISTORY',
 start_date    => SYSTIMESTAMP - interval '58' minute,
 repeat_interval  => 'FREQ=HOURLY; INTERVAL=1;',
 end_date     => SYSTIMESTAMP + INTERVAL '1000' day,
 comments     => 'Every 1 hour');
END;


--------------------------------------------------------------------------------
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
  job_name       => 'JOB_IM_AREA_HISTORY',
  program_name   => 'PROG_IM_AREA_HISTORY',
  schedule_name  => 'SCHED_1HOUR_IM_AREA_HISTORY');
END;

begin 
dbms_scheduler.enable('JOB_IM_AREA_HISTORY');
end;


--------------------------------------------------------------------------------


