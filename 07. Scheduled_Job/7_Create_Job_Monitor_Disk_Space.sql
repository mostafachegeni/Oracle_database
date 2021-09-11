--------------------------------------------------------------------------------
select * from MOSCH.DISK_SPACE_HISTORY_2020_08_09 where diskgroup_NAME = 'DATAGRP' order by log_date desc;

--------------------------------------------------------------------------------
--grant select on MOSCH.DISK_SPACE_HISTORY_2020_08_09 to star_etl;
--drop table MOSCH.DISK_SPACE_HISTORY_2020_08_09 cascade constraints purge;
CREATE TABLE MOSCH.DISK_SPACE_HISTORY_2020_08_09 (
	log_date        DATE,
    GROUP_number    number,
    diskgroup_NAME  varchar2(30 Byte),
    STATUS          varchar2(11 Byte),
    TOTAL_GB        number,
    USABLE_GB       number
);


--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PROC_DISK_SPACE_HISTORY_2020_08_09 
IS 
    GROUP_number    number;
    diskgroup_NAME  varchar2(30 Byte);
    STATUS          varchar2(11 Byte);
    TOTAL_GB        number;
    USABLE_GB       number;

	-- Left join of (ToTal_Allocated_Space_size and Used_Allocated_Space_Size)
	-- Identify Disks in ASM:
    CURSOR C1 IS select group_number, 
				        name, 
				        state, 
				        round(total_mb/1024), 
				        round(usable_file_mb/1024) 
                    from v$asm_diskgroup 
                    order by group_number;

BEGIN 

  OPEN c1;   
  
  LOOP 
    FETCH C1 INTO GROUP_number, diskgroup_NAME, STATUS, TOTAL_GB, USABLE_GB;
	EXIT WHEN c1%NOTFOUND;
    
    BEGIN 
	    INSERT INTO MOSCH.DISK_SPACE_HISTORY_2020_08_09 
		       VALUES   (sysdate, GROUP_number, diskgroup_NAME, STATUS, TOTAL_GB, USABLE_GB);

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
program_name      => 'PROG_DISK_SPACE_HISTORY_2020_08_09',
program_action    => 'PROC_DISK_SPACE_HISTORY_2020_08_09',
program_type      => 'STORED_PROCEDURE');
END;

begin 
dbms_scheduler.enable('PROG_DISK_SPACE_HISTORY_2020_08_09');
end; 


--------------------------------------------------------------------------------
BEGIN
DBMS_SCHEDULER.CREATE_SCHEDULE (
 schedule_name   => 'SCHED_1HOUR_DISK_SPACE_HISTORY_2020_08_09',
 start_date    => SYSTIMESTAMP,
 repeat_interval  => 'FREQ=HOURLY; INTERVAL=1;',
 end_date     => SYSTIMESTAMP + INTERVAL '1000' day,
 comments     => 'Every 1 hour');
END;


--------------------------------------------------------------------------------
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
  job_name       => 'JOB_DISK_SPACE_HISTORY_2020_08_09',
  program_name   => 'PROG_DISK_SPACE_HISTORY_2020_08_09',
  schedule_name  => 'SCHED_1HOUR_DISK_SPACE_HISTORY_2020_08_09');
END;

begin 
dbms_scheduler.enable('JOB_DISK_SPACE_HISTORY_2020_08_09');
end;


--------------------------------------------------------------------------------


