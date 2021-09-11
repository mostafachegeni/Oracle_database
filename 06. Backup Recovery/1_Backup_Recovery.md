# Backup Recovery
- Take Backup Level 0 Cumulative:
```
[oracle(shdg)@shahkardg ~]$ cat /u01/script/l0_bkp
run
{
sql 'alter session set nls_calendar=gregorian';
Allocate channel c1 device type disk format '/u01/orcl_files/backup/l0/bkp_l0%u';
Allocate channel c2 device type disk format '/u01/orcl_files/backup/l0/bkp_l0%u';
Allocate channel c3 device type disk format '/u01/orcl_files/backup/l0/bkp_l0%u';
Allocate channel c4 device type disk format '/u01/orcl_files/backup/l0/bkp_l0%u';
Allocate channel c5 device type disk format '/u01/orcl_files/backup/l0/bkp_l0%u';
Allocate channel c6 device type disk format '/u01/orcl_files/backup/l0/bkp_l0%u';

crosscheck backup;
DELETE noprompt EXPIRED BACKUP;
crosscheck backup;
delete noprompt obsolete;

CROSSCHECK ARCHIVELOG ALL;
DELETE noprompt EXPIRED ARCHIVELOG ALL;

SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/u01/orcl_files/backup/l0/autoback_ctlfile_%F.bck';
Backup as compressed backupset incremental level 0 cumulative database include current controlfile plus archivelog section size 100g;
BACKUP CURRENT CONTROLFILE TAG 'Backup_Controlfile' format '/u01/orcl_files/backup/l0/back_ctlfile_%U';

#BACKUP CURRENT CONTROLFILE TAG 'Backup_Controlfile' format '/u01/orcl_files/backup/l0/back_ctlfile_%U' KEEP UNTIL TIME='sysdate+10' NOLOGS;

crosscheck backup;
DELETE noprompt EXPIRED BACKUP;
crosscheck backup;
delete noprompt obsolete;

CROSSCHECK ARCHIVELOG ALL;
DELETE noprompt EXPIRED ARCHIVELOG ALL;
}
```


-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
- 1- Check Backup Status:
```
SQL> SELECT OPERATION, STATUS, MBYTES_PROCESSED, START_TIME, END_TIME from V$RMAN_STATUS;


RMAN> LIST DB_UNIQUE_NAME OF DATABASE;
	List of Databases
	DB Key  DB Name  DB ID            Database Role    Db_unique_name
	------- ------- ----------------- ---------------  ------------------
	2       ORCLDB   2473084788       PRIMARY          ORCLDB


RMAN> LIST ARCHIVELOG ALL;
	List of Archived Log Copies for database with db_unique_name ORCLDB
	==============================================================================
	Key     Thrd Seq     S Low Time
	------- ---- ------- - ---------
	30      1    24      A 17-MAY-20
			Name: +FRA/ORCLDB/ARCHIVELOG/2020_05_17/thread_1_seq_24.281.1040636289
	32      1    25      A 17-MAY-20
			Name: +FRA/ORCLDB/ARCHIVELOG/2020_05_17/thread_1_seq_25.283.1040657449
	34      1    26      A 17-MAY-20
			Name: +FRA/ORCLDB/ARCHIVELOG/2020_05_17/thread_1_seq_26.285.1040679555


RMAN> REPORT SCHEMA;
	Report of database schema for database with db_unique_name ORCLDB
	List of Permanent Datafiles
	===========================
	File Size(MB) Tablespace           RB segs Datafile Name
	---- -------- -------------------- ------- ------------------------
	1    820      SYSTEM               YES     +DATA/ORCLDB/DATAFILE/system.257.1037131121
	3    810      SYSAUX               NO      +DATA/ORCLDB/DATAFILE/sysaux.258.1037131171
	4    80       UNDOTBS1             YES     +DATA/ORCLDB/DATAFILE/undotbs1.259.1037131195
	7    5        USERS                NO      +DATA/ORCLDB/DATAFILE/users.260.1037131197
	List of Temporary Files
	=======================
	File Size(MB) Tablespace           Maxsize(MB) Tempfile Name
	---- -------- -------------------- ----------- --------------------
	1    129      TEMP                 32767       +DATA/ORCLDB/TEMPFILE/temp.265.1037131261

RMAN> LIST BACKUP SUMMARY;
	List of Backups
	===============
	Key     TY LV S Device Type Completion Time #Pieces #Copies Compressed Tag
	------- -- -- - ----------- --------------- ------- ------- ---------- ---
	1       B  F  A DISK        29-APR-20       1       1       NO         TAG20200429T020524
	2       B  F  A DISK        29-APR-20       1       1       NO         TAG20200429T022026

RMAN> SHOW ALL;
	RMAN configuration parameters for database with db_unique_name ORCLDB are:
	CONFIGURE RETENTION POLICY TO REDUNDANCY 1; # default
	CONFIGURE BACKUP OPTIMIZATION OFF; # default
	CONFIGURE DEFAULT DEVICE TYPE TO DISK; # default
	CONFIGURE CONTROLFILE AUTOBACKUP ON; # default
	CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '%F'; # default
	CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO BACKUPSET; # default
	CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
	CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
	CONFIGURE MAXSETSIZE TO UNLIMITED; # default
	CONFIGURE ENCRYPTION FOR DATABASE OFF; # default
	CONFIGURE ENCRYPTION ALGORITHM 'AES128'; # default
	CONFIGURE COMPRESSION ALGORITHM 'BASIC' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE ; # default
	CONFIGURE RMAN OUTPUT TO KEEP FOR 7 DAYS; # default
	CONFIGURE ARCHIVELOG DELETION POLICY TO NONE; # default
	CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/u01/app/oracle/product/12.2.0/dbhome_1/dbs/snapcf_prim.f'; # default


RMAN> RESTORE DATABASE PREVIEW;
RMAN> RESTORE DATABASE PREVIEW SUMMARY;

RMAN> RESTORE DATABASE VALIDATE;

RMAN> RESTORE TABLESPACE dev1 PREVIEW;
RMAN> RESTORE DATAFILE '/u01/oradata/devdb/dev1_01.dbf' PREVIEW;
RMAN> RESTORE ARCHIVELOG ALL PREVIEW;
RMAN> RESTORE ARCHIVELOG FROM SCN 234546 PREVIEW;
```
- 2- Configure Backup Parameters:
-  Return any setting to its default value by using "CONFIGURE ... CLEAR":
```
RMAN> CONFIGURE RETENTION POLICY CLEAR;
RMAN> CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
RMAN> CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/backup/rman/full_%u_%s_%p';
```
- 3- Restore ControlFIle:
```
RMAN> RESTORE CONTROLFILE FROM AUTOBACKUP;
RMAN> RESTORE CONTROLFILE FROM TAG 'WEEKLY_FULL_BKUP';
RMAN> RESTORE CONTROLFILE FROM "/backup/rman/ctl_c-12345-20141003-03"; 
```
- 4- Restore DataFile:
```
SQL> select file_id, file_name from dba_data_files;
RMAN> RESTORE DATAFILE 34, 35
RMAN> RESTORE DATAFILE '/u01/oradata/devdb/dev1_01.dbf'
RMAN> RESTORE DATAFILE '/u01/oradata/devdb/dev1_01.dbf', '/u01/oradata/devdb/dev1_02.dbf'
```
- 5- Restore Archive RedoLogs:
```
RMAN> SET ARCHIVELOG DESTINATION TO '/home/arc_logs_new/';
RMAN> RESTORE ARCHIVELOG ALL;
RMAN> RESTORE ARCHIVELOG FROM SEQUENCE 153 UNTIL SEQUENCE 175;
RMAN> RESTORE ARCHIVELOG FROM SCN 56789;
```
- 6- Restore Tablespace:
```
RMAN> RESTORE TABLESPACE dev1, dev2;
```
- 7- Recover 
```
RMAN> RECOVER TABLESPACE dev1 DELETE ARCHIVELOG;
```
- 8- Delete Expired/Obsolete Backup:
```
RMAN> CROSSCHECK BACKUP;
RMAN> DELETE EXPIRED BACKUP;
RMAN> DELETE noprompt obsolete;
```
- 9- Delete Expired ArchiveLog:
```
RMAN> CROSSCHECK ARCHIVELOG ALL;
RMAN> DELETE EXPIRED ARCHIVELOG ALL;
```


-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
- **Scenario 1**: 
	> 1- Backup database to a "local directory".
	> (Backup as compressed backupset incremental level 0 cumulative database TAG 'Database_Inc' include current controlfile plus archivelog section size 100g;) 
	
	> 2- Change Database. 
	
	> 3- Delete "DataFiles", 
	> "Online RedoLogs", 
	> "Archived RedoLogs". 

	> 4- Recover Database to previous state as follows: 



- 0- 
```
[oracle@prim ~]$ rman target /
connected to target database: ORCLDB (DBID=2473084788)
```
- 1- Mount Database:
```
RMAN> shutdown immediate;
RMAN> startup mount;
Oracle instance started
database mounted
```
- 2- Restore Database:
```
RMAN> RESTORE DATABASE;
...
cataloging done.
List of Cataloged Files
=======================
File Name: +FRA/ORCLDB/ARCHIVELOG/2020_05_10/thread_1_seq_78.302.1040057955
File Name: +FRA/ORCLDB/ARCHIVELOG/2020_05_10/thread_1_seq_79.303.10400579
...
Finished restore at 10-MAY-20
```
- 3- Recover Database: 
```
RMAN> ALTER DATABASE recover database using backup controlfile until cancel;
RMAN-00571: ===========================================================
RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
RMAN-00571: ===========================================================
RMAN-03002: failure of sql statement command at 05/10/2020 17:12:55
ORA-00279: change 7247777 generated at 05/10/2020 15:44:13 needed for thread 1
ORA-00289: suggestion : +FRA
ORA-00280: change 7247777 for thread 1 is in sequence #82
```
- 4- Cancel Recovery:
```
RMAN> ALTER DATABASE recover cancel;
Statement processed
```
- 5- Reset Logs:
```
RMAN> ALTER DATABASE OPEN RESETLOGS;
Statement processed
```


-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
- **Scenario 2**:

	> 1- Backup database to a "local directory".
	> (Backup as compressed backupset incremental level 0 cumulative database TAG 'Database_Inc' include current controlfile plus archivelog section size 100g;) 

	> 2- Change Database.
	
	> 3- Delete "DataFiles", 
	>			"Online RedoLogs", 
	>			"Archived RedoLogs", 
	>			"TempFiles", 
	>			"AutoBackup",
	>			"Flashback". 

	> 4- Recover Database to previous state as follows: 


- 0- 
```
[oracle@prim ~]$ rman target /
connected to target database: ORCLDB (DBID=2473084788)
```

- 1- Mount Database:
```
RMAN> shutdown immediate;
RMAN> startup mount;
	Oracle instance started
	database mounted
```

- 2- Restore Database:
```
RMAN> RESTORE DATABASE;
...
channel ORA_DISK_1: restore complete, elapsed time: 00:01:25
Finished restore at 10-MAY-20
```

- 3- Recover Database:
```
RMAN> ALTER DATABASE recover database using backup controlfile until cancel;
RMAN-00571: ===========================================================
RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
RMAN-00571: ===========================================================
RMAN-03002: failure of sql statement command at 05/10/2020 19:10:31
ORA-00279: change 8380127 generated at 05/10/2020 18:15:41 needed for thread 1
ORA-00289: suggestion : +FRA/ORCLDB/ARCHIVELOG/2020_05_10/thread_1_seq_9.299.1040062607
ORA-00280: change 8380127 for thread 1 is in sequence #9
```


- 4- Cancel Recovery:
```
RMAN> alter database recover cancel;
Statement processed
```

- 5- Reset Logs:
```
RMAN> ALTER DATABASE OPEN RESETLOGS;
Statement processed
```

- 6- Enable flashback:
```
SQL> SELECT flashback_on from v$database;
SQL> ALTER DATABASE FLASHBACK ON;
```

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
- **Scenario 3**: 

	> 1- Backup database to a "local directory".
	> (Backup as compressed backupset incremental level 0 cumulative database TAG 'Database_Inc' include current controlfile plus archivelog section size 100g;)
	
	> 2- Change Database.
	
	> 3- Delete "DataFiles", 
	>			"Online RedoLogs", 
	>			"Archived RedoLogs",  
	>			"TempFiles", 
	>			"AutoBackup", 
	>			"Flashback", 
	>			"ControlFiles", 
	>			"SPFILE".
	
	> 4- Recover Database to previous state as follows: 



- 0- 
```
[oracle@stand ~]$ vi /tmp/init.ora
*.db_name='orcldb'

[oracle@stand ~]$ rman target /
connected to target database (not started)
```
- 1- Startup NoMount Database:
```
RMAN> shutdown immediate;
RMAN> STARTUP NOMOUNT PFILE='/tmp/init.ora';
```
- 2- Set Database ID: (DBID exist in "ControlFile AutoBackup FileName": 
```
--	  e.g. autoback_ctlfile_c-2473084788-20200513-03.bck)
RMAN> SET DBID 2473084788;
```
- 3- Restore SPFILE:
```
RMAN> RESTORE SPFILE FROM '/u01/orcl_files/backup/l0/autoback_ctlfile_c-2473084788-20200513-03.bck';
--RMAN> RESTORE SPFILE FROM AUTOBACKUP;
--RMAN> RESTORE SPFILE TO '/tmp/spfileTEMP.ora' FROM AUTOBACKUP;
--RMAN> RESTORE SPFILE TO PFILE '/tmp/initTEMP.ora';
```
- 4- Restart instance:
```
RMAN> shutdown immediate;
RMAN> startup nomount;
```

- 5- Restore ControlFIle:
```
RMAN> RESTORE CONTROLFILE FROM '/u01/orcl_files/backup/l0/autoback_ctlfile_c-2473084788-20200513-03.bck';
```
- 6- Mount Database:
```
RMAN> ALTER DATABASE MOUNT;
```

- 7- Restore Database:
```
RMAN> RESTORE DATABASE;
channel ORA_DISK_1: restore complete, elapsed time: 00:00:55
Finished restore at 13-MAY-20
```

- 8- Recover Database:
```
RMAN> ALTER DATABASE RECOVER DATABASE USING BACKUP CONTROLFILE UNTIL CANCEL;
RMAN-00571: ===========================================================
RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
RMAN-00571: ===========================================================
RMAN-03002: failure of sql statement command at 05/13/2020 18:33:19
ORA-00279: change 7803148 generated at 05/13/2020 17:37:16 needed for thread 1
ORA-00289: suggestion : +FRA/STAND/ARCHIVELOG/2020_05_13/thread_1_seq_7.332.1040319427
ORA-00280: change 7803148 for thread 1 is in sequence #7
```



- 9- Cancel Recovery:
```
RMAN> ALTER database recover cancel;
Statement processed
```

- 10- Reset Logs:
```
RMAN> ALTER DATABASE OPEN RESETLOGS;
Statement processed
```

- 11- Enable flashback:
```
SQL> SELECT flashback_on from v$database;
SQL> ALTER DATABASE FLASHBACK ON;
```

