--------------------------------------------------------------------------------
select * from MOSCH.TABLESPACE_SPACE_HISTORY_2020_08_09 order by log_date desc, total_allocated_size_GB desc;

--------------------------------------------------------------------------------
CREATE TABLE MOSCH.TABLESPACE_SPACE_HISTORY_2020_08_09 (
	log_date                DATE,
	Tablespace_name         varchar2(30 byte), 
	total_allocated_size_GB number, 
	used_allocate_size_GB   number
);


--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PROC_TABLESPACE_SPACE_HISTORY_2020_08_09 
IS 
    tablespace_name      varchar2(30 byte);
    total_allocated_size number;
    used_allocate_size 	 number;

	-- Left join of (ToTal_Allocated_Space_size and Used_Allocated_Space_Size)
    CURSOR C1 IS select b.tablespace_name,
				        b.Total_Allocated_Data_Size_GB, 
				        a.Used_Allocated_Space_TB
				    from 
				    (select  /*+ parallel(dba_data_files,16) */ b.tablespace_name,
				        round(sum(a.Bytes/1024/1024/1024)) Total_Allocated_Data_Size_GB
				    from 	dba_data_files a, 
				            dba_tablespaces b 
				    where       a.tablespace_name=b.tablespace_name 
				    group by    b.tablespace_name) b 
				    LEFT OUTER JOIN 
				    (select  /*+ parallel(DBA_SEGMENTS,16) */ tablespace_name, 
				        round(sum(Bytes)/1024/1024/1024) Used_Allocated_Space_TB 
				    from     DBA_SEGMENTS 
				    group by tablespace_name) a 
				    on a.tablespace_name = b.tablespace_name 
				    order by 2 desc;

BEGIN 

  OPEN c1;   

  LOOP 
    FETCH C1 INTO tablespace_name, total_allocated_size, used_allocate_size;
	EXIT WHEN c1%NOTFOUND;
    
    BEGIN 
	    INSERT INTO MOSCH.TABLESPACE_SPACE_HISTORY_2020_08_09 
		       VALUES   (sysdate, tablespace_name, total_allocated_size, used_allocate_size);

    EXCEPTION   
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
BEGIN
DBMS_SCHEDULER.CREATE_PROGRAM (
program_name      => 'PROG_TABLESPACE_SPACE_HISTORY_2020_08_09',
program_action    => 'PROC_TABLESPACE_SPACE_HISTORY_2020_08_09',
program_type      => 'STORED_PROCEDURE');
END;

begin 
dbms_scheduler.enable('PROG_TABLESPACE_SPACE_HISTORY_2020_08_09');
end; 


--------------------------------------------------------------------------------
BEGIN
DBMS_SCHEDULER.CREATE_SCHEDULE (
 schedule_name   => 'SCHED_1DAY_TABLESPACE_SPACE_HISTORY_2020_08_09',
 start_date    => SYSTIMESTAMP + INTERVAL '1' day - INTERVAL '9' hour,
 repeat_interval  => 'FREQ=DAILY; INTERVAL=1;',
 end_date     => SYSTIMESTAMP + INTERVAL '1000' day,
 comments     => 'Every 1 day');
END;


--------------------------------------------------------------------------------
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
  job_name       => 'JOB_TABLESPACE_SPACE_HISTORY_2020_08_09',
  program_name   => 'PROG_TABLESPACE_SPACE_HISTORY_2020_08_09',
  schedule_name  => 'SCHED_1DAY_TABLESPACE_SPACE_HISTORY_2020_08_09');
END;

begin 
dbms_scheduler.enable('JOB_TABLESPACE_SPACE_HISTORY_2020_08_09');
end;


--------------------------------------------------------------------------------


