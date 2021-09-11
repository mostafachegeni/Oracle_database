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
- Scenario 1: \
	> 1 -> Backup database to a "local directory" at 05/10/20 15:44.\
	(Backup as compressed backupset incremental level 0 cumulative database TAG 'Database_Inc' include current controlfile plus archivelog section size 100g;) \
	> 2 -> Change Database. \
	> 3 -> Delete "DataFiles", \ 
	>			"Online RedoLogs", \
	>			"Archived RedoLogs". \
	> 4 -> Recover Database to previous state as follows: \



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
- Scenario 2: \
	> 1 -> Backup database to a "local directory" at 05/10/20 18:16. \
	(Backup as compressed backupset incremental level 0 cumulative database TAG 'Database_Inc' include current controlfile plus archivelog section size 100g;) \
	> 2 -> Change Database. \
	> 3 -> Delete "DataFiles", \ 
	>			"Online RedoLogs", \
	>			"Archived RedoLogs", \ 
	>			"TempFiles", \
	>			"AutoBackup", \
	>			"Flashback". \
	> 3 -> Recover Database to previous state as follows: \


- 0. 
```
[oracle@prim ~]$ rman target /
connected to target database: ORCLDB (DBID=2473084788)
```
- 1. Mount Database:
```
RMAN> shutdown immediate;
RMAN> startup mount;
	Oracle instance started
	database mounted
```
- 2. Restore Database:
```
RMAN> RESTORE DATABASE;
...
channel ORA_DISK_1: restore complete, elapsed time: 00:01:25
Finished restore at 10-MAY-20
```
- 3. Recover Database:
```
RMAN> ALTER DATABASE recover database using backup controlfile until cancel;
RMAN-00571: ===========================================================
RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
RMAN-00571: ===========================================================
RMAN-03002: failure of sql statement command at 05/10/2020 19:10:31
ORA-00279: change 8380127 generated at 05/10/2020 18:15:41 needed for thread 1
ORA-00289: suggestion : +FRA/ORCLDB/ARCHIVELOG/2020_05_10/thread_1_seq_9.299.1040062607
ORA-00280: change 8380127 for thread 1 is in sequence #9

/*
- ERROR:
ORA-38760: This database instance failed to turn on flashback database
```
- SOLUTION: \
1. shutdown immediate; \
2. startup mount; \
3. ALTER DATABASE FLASHBACK OFF; \
5. alter databasse open; \
*/ 

- 4. Cancel Recovery:
```
RMAN> alter database recover cancel;
Statement processed
```
- 5. Reset Logs:
```
RMAN> ALTER DATABASE OPEN RESETLOGS;
Statement processed
/*
ERROR:
ORA-01113: file 1 needs media recovery
ORA-01110: data file 1: '+DATA/ORCLDB/DATAFILE/system.259.1040063577'
```
- SOLUTION:
```
RMAN> ALTER database recover database using backup controlfile;
RMAN> ALTER database recover cancel;
RMAN> recover database;
RMAN> ALTER database RECOVER DATAFILE '+DATA/ORCLDB/DATAFILE/system.259.1040063577';
RMAN-06067: RECOVER DATABASE required with a backup or created control file

RMAN> ALTER DATABASE OPEN RESETLOGS;
*/
```

- 7. Enable flashback:
```
SQL> SELECT flashback_on from v$database;
SQL> ALTER DATABASE FLASHBACK ON;
```

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
- Scenario 3: \
	> 1 -> Backup database to a "local directory" at 05/10/20 18:16. \
	(Backup as compressed backupset incremental level 0 cumulative database TAG 'Database_Inc' include current controlfile plus archivelog section size 100g;) \
	> 2 -> Change Database. \
	> 3 -> Delete "DataFiles", \ 
	>			"Online RedoLogs", \
	>			"Archived RedoLogs", \ 
	>			"TempFiles", \
	>			"AutoBackup", \
	>			"Flashback", \
	>			"ControlFiles", \
	>			"SPFILE". \
	> 3 -> Recover Database to previous state as follows: \



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

===================================================================================
-----------------------------------------------------------------------------------
===================================================================================
- Recovery Catalog Management: \
[docs.oracle.com](https://docs.oracle.com/cd/E18283_01/backup.112/e10642/rcmcatdb.htm#insertedID8) 

------------------------------------------------
- Configure "Recovery Catalog" Database:

- 1. Login as "root".
```
[oracle@prim ~]$ vi /etc/hosts
192.168.96.113      moschdb     moschdb.mosch.co
```
- 2. Login as "oracle".

- 3. Modify "tnsnames.ora":
```
[oracle@stand ~]$ vi /u01/app/oracle/product/12.2.0/dbhome_1/network/admin/tnsnames.ora
DBCAT =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = moschdb.mosch.co)(PORT = 1521))
    (CONNECT_DATA =
      (SID = moschdb)
    )
  )

```
- 4. Connect to recovery catalog database:
```
SQL> CONNECT SYS/SYS123sys@DBCAT AS SYSDBA
```
- 5. Create a tablespace:
```
SQL> CREATE tablespace tools 
	  datafile '+DATA' 
	  size 32M 
	  autoextend on 
	  next 32M maxsize 2048M
	  extent management local;
```
- 6. Create a user and schema for the recovery catalog:
```
SQL> CREATE USER rman IDENTIFIED BY SYS123sys
		TEMPORARY TABLESPACE temp 
		DEFAULT TABLESPACE tools 
		QUOTA UNLIMITED ON tools;
```
- 7. Grant the RECOVERY_CATALOG_OWNER role to the schema owner.
```
SQL> GRANT RECOVERY_CATALOG_OWNER TO rman;
```
- 8. Connect to database as the "catalog owner".
```
[oracle@moschdb ~]$ rman CATALOG rman/SYS123sys@DBCAT
connected to recovery catalog database
```
- 9. Create the catalog. This can take "several minute".
```
RMAN> CREATE CATALOG;
/*
--If the catalog tablespace is "NOT" the (rman user)'s default tablespace:
RMAN> CREATE CATALOG TABLESPACE cat_ts;
*/
```
- 10. Verify the results by using SQL*Plus to query the recovery catalog to see which tables were created:
```
SQL> SELECT TABLE_NAME FROM USER_TABLES;
...
57 rows selected.
```
------------------------------------------------
- Register a Database in the Recovery Catalog: \

- NOTE 1: If you use RMAN in a "Data Guard" environment, then you need to use the "REGISTER DATABASE" \
  command only for the "primary" database. \
  The "standby" database is registered automatically in the recovery catalog, when: \
	1. When you connect to a standby database as TARGET. \
	2. When you run the "CONFIGURE DB_UNIQUE_NAME" command for a standby database. \


- 1. Connect to "target" database and recovery "catalog".
```
[oracle@moschdb ~]$ rman TARGET sys/SYS123sys@DBPRIM CATALOG rman/SYS123sys@DBCAT
	connected to target database: ORCLDB (DBID=2473084788)
	connected to recovery catalog database
```
- 2. mount or open target database.
```
RMAN> STARTUP MOUNT;
```
- 3. Register the target database in the connected recovery catalog:
```
RMAN> REGISTER DATABASE;
	database registered in recovery catalog
	starting full resync of recovery catalog
	full resync complete
```

- 4. Verify that the registration was successful: \
--(RMAN creates rows in the "catalog tables" to contain information about the target database, \
-- then copies all pertinent data about the target database from the control file into the catalog, \ 
-- "synchronizing" the "catalog" with the "ControlFile".)
```
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

```
- 5. Cataloging "Datafile Copies", "Backup Pieces", or "archivedLogs" on disk in the Recovery Catalog.
```
RMAN> CATALOG DATAFILECOPY '/disk1/old_datafiles/01_01_2003/users01.dbf';
RMAN> CATALOG ARCHIVELOG '/disk1/arch_logs/archive1_731.dbf', 
                   '/disk1/arch_logs/archive1_732.dbf';
RMAN> CATALOG BACKUPPIECE '/disk1/backups/backup_820.bkp';
```
- Catalog multiple backup files:
```
--RMAN> CATALOG START WITH '/disk1/backups/';
```
------------------------------------------------
- Unregister a (Primary) Database from the Recovery Catalog:

- 1. Start RMAN and connect as "TARGET" to the database that you want to unregister. Also connect to the "recovery catalog".

- 2. Make a note of the "DBID" as displayed by RMAN at startup. \
connected to target database: PROD (DBID=39525561)

- 3. Check list all of the backups recorded in the recovery catalog.
```
RMAN> LIST BACKUP SUMMARY;
RMAN> LIST COPY SUMMARY;
```
- 4. Delete all backups of the database completely. \
-- (Do not delete all backups if your intention is only to remove the database from the  \
--  "recovery catalog" and rely on the "control file" to store the RMAN metadata for this database.) \
```
--RMAN> DELETE BACKUP DEVICE TYPE sbt; 
--RMAN> DELETE BACKUP DEVICE TYPE DISK;
--RMAN> DELETE COPY;
```
- 5. Unregister the database.
```
RMAN> UNREGISTER DATABASE;
```

------------------------------------------------
- Unregister a Standby Database from the Recovery Catalog:

- 1. Start RMAN and Connect as TARGET to the "Primary" database. Also, connect RMAN to a recovery catalog.
```
[]$ rman target sys/SYS123sys@DBPRIM
connected to target database: ORCLDB (DBID=2473084788)

RMAN> CONNECT CATALOG rman@DBCAT
```
- 2. List the database unique names.
```
RMAN> LIST DB_UNIQUE_NAME OF DATABASE;
List of Databases
DB Key  DB Name DB ID             Database Role     Db_unique_name
------- ------- ----------------- ----------------- ------------------
1       ORCLDB  2473084788         PHYSICAL STANDBY STAND
1       ORCLDB  2473084788         PRIMARY          ORCLDB
```
- 3. Unregister "standby" database:
```
RMAN> UNREGISTER DB_UNIQUE_NAME stand;

```
===================================================================================
-----------------------------------------------------------------------------------
===================================================================================
- Resynchronize the Recovery Catalog:

- NOTE 1: RMAN only "automatically" resynchronizes the recovery catalog with a database, \
  when connected to the database as "TARGET". \

- NOTE 2: In "Data Guard", primary and standby should be resynchronized "separately". \

- NOTE 3: When to Resynchronize the Recovery Catalog: 
	-  Resynchronizing After the Recovery Catalog is Unavailable. 
	-  Resynchronizing in ARCHIVELOG Mode When You Back Up Infrequently.
	-  Resynchronizing After Configuring a Standby Database.
	-  Resynchronizing the Recovery Catalog Before Control File Records Age Out.

- 1. Start RMAN and connect to a target database and recovery catalog.

- 2. Mount or open the target database
```
RMAN> STARTUP MOUNT;
```
- 3. Resynchronize the recovery catalog. 
```
	-- Resynchronizes the control file of target database:
	
  RMAN> RESYNC CATALOG;
	
	-- Resynchronizes the control file of standby1:
	RMAN> RESYNC CATALOG FROM DB_UNIQUE_NAME standby1;

	-- Resynchronize control files for all databases in "Data Guard" setup that are known to "Recovery Catalog":
	RMAN> RESYNC CATALOG FROM DB_UNIQUE_NAME ALL;

```
===================================================================================
-----------------------------------------------------------------------------------
===================================================================================
- Backup/Recovery with "Data Guard": \
[docs.oracle.com](https://docs.oracle.com/cd/E18283_01/server.112/e17022/rman.htm#SBYDB04700) 

- NOTE 1: In a Data Guard environment, the primary and standby databases share the same "DBID" and "database name". \
		  To be eligible for registration in the recovery catalog, each database in the Data Guard environment must
		  have different "DB_UNIQUE_NAME" values.

------------------------------------------------
-- Configure "Primary" Database:

- 1. Use a server parameter file (SPFILE).

- 2. Enable Flashback Database.
```
SQL> SELECT flashback_on from v$database;
SQL> ALTER DATABASE FLASHBACK ON;
System altered.
/*
ERROR at line 1:
ORA-38706: Cannot turn on FLASHBACK DATABASE logging.
ORA-38709: Recovery Area is not enabled.
```
if ERROR: \
1. (On Primary) Login as "root". Then, create "udev rule" to change disk owner. \

2. (On Primary) Login as "grid". Then, add new diskgroup "FRA" using "asmca". \

3. (On Primary) Login as "oracle":
```
SQL> alter system set db_recovery_file_dest_size=26g scope=both;
SQL> alter system set db_recovery_file_dest='+FRA' scope=both;
```
4. 
```
SQL> show parameter DB_RECOVERY_FILE_DEST
*/
```
- 3. Connect RMAN to the "primary" as target, and to the "recovery catalog".

- 4. Register Database in Recovery Catalog:
/*
- NOTE 2: If you use RMAN in a "Data Guard" environment, then you can use the "REGISTER DATABASE" \
  command only for the "primary" database. \
  You can use the following techniques to register a "standby" database: \
	1. When you connect to a standby database as TARGET, \
	RMAN automatically registers the database in the recovery catalog. \
	2. When you run the "CONFIGURE DB_UNIQUE_NAME" command for a standby database, \
	RMAN automatically registers this standby database if its primary database is registered. \
*/

- 5. Configure the retention policy for the database as n days:
```
RMAN> CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF <n> DAYS;
```
- 6. Use "DELETE OBSOLETE" to delete backups that are NOT required according the "retention policy".

- 7. Specify when archived logs can be deleted. 
```
	-- Delete logs after ensuring that they shipped to all destinations:
	
  RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO SHIPPED TO ALL STANDBY;
  
	-- Delete logs after ensuring that they were applied on all standby destinations:
	RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;
```
- 8. Configure "TNS alias" for all "standby" databases.
```
RMAN> CONFIGURE DB_UNIQUE_NAME BOSTON CONNECT IDENTIFIER 'DBSTBY';
RMAN> LIST DB_UNIQUE_NAME OF DATABASE;
```
------------------------------------------------
- Configure "Guard" Database Where "Backups are Performed":

- 1. Use a server parameter file (SPFILE).

- 2. Enable Flashback Database.
```
SQL> SELECT flashback_on from v$database;
SQL> ALTER DATABASE FLASHBACK ON;
System altered.
/*
ERROR at line 1:
ORA-38706: Cannot turn on FLASHBACK DATABASE logging.
ORA-38709: Recovery Area is not enabled.
```
if ERROR: \
1. (On Primary) Login as "root". Then, create "udev rule" to change disk owner. 

2. (On Primary) Login as "grid". Then, add new diskgroup "FRA" using "asmca".

3. (On Primary) Login as "oracle":
```
SQL> alter system set db_recovery_file_dest_size=26g scope=both;
SQL> alter system set db_recovery_file_dest='+FRA' scope=both;
```
4. 
```
SQL> show parameter DB_RECOVERY_FILE_DEST
*/
```
- 3. Connect RMAN to the "standby" database as target, and to the "recovery catalog".

- 4. Enable automatic backup of the "ControlFile" and the "SPFILE":
```
RMAN> CONFIGURE CONTROLFILE AUTOBACKUP ON;
```
- 5. Skip backing up datafiles for which there already exists a valid backup with the same checkpoint:
```
RMAN> CONFIGURE BACKUP OPTIMIZATION ON;
```
- 6. Configure the tape channels to create backups as required by media management software:
```
RMAN> CONFIGURE CHANNEL DEVICE TYPE SBT PARMS '<channel parameters>';
```
- 7. Specify when the archived logs can be deleted.
```
RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP;

```
------------------------------------------------
- Configure "Guard" Database Where "Backups are NOT Performed":

- 1. Use a server parameter file (SPFILE).

- 2. Enable Flashback Database.
```
SQL> SELECT flashback_on from v$database;
SQL> ALTER DATABASE FLASHBACK ON;
System altered.
/*
ERROR at line 1:
ORA-38706: Cannot turn on FLASHBACK DATABASE logging.
ORA-38709: Recovery Area is not enabled.
```
if ERROR: 
1. (On Primary) Login as "root". Then, create "udev rule" to change disk owner.

2. (On Primary) Login as "grid". Then, add new diskgroup "FRA" using "asmca".

3. (On Primary) Login as "oracle":
```
SQL> alter system set db_recovery_file_dest_size=26g scope=both;
SQL> alter system set db_recovery_file_dest='+FRA' scope=both;
```
4. 
```
SQL> show parameter DB_RECOVERY_FILE_DEST
*/
```
- 3. Connect RMAN to the "standby" database as target, and to the "recovery catalog".

- 4. Enable automatic deletion of archived logs once they are applied at the standby database:
```
RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;
```
------------------------------------------------
- Recovery on "Primary" Using "DataFiles" On a Standby Database:

- 1. Connect to "standby" as the "target", and "primary" as "auxiliary":
```
RMAN> CONNECT TARGET sys@DBSTBY
RMAN> CONNECT AUXILIARY sys@DBPRIM
```
- 2. Backup the datafile on the "standby" host across the network to a location on the "primary" host.
```
RMAN> BACKUP AS COPY DATAFILE 2 AUXILIARY FORMAT '/disk9/df2copy.dbf';
```
- 3. Exit the RMAN client as follows:
```
EXIT;
```
- 4. connect to the primary database as target, and to the recovery catalog:
```
RMAN> CONNECT TARGET sys@DBPRIM;
RMAN> CONNECT CATALOG rman@DBCAT;
```
- 5. Catalog the datafile copy:
```
RMAN> CATALOG DATAFILECOPY '/disk9/df2copy.dbf';
```
- 6. Switch the datafile copy so that /disk9/df2copy.dbf becomes the "current datafile":
```
RUN {
  SET NEWNAME FOR DATAFILE 2 TO '/disk9/df2copy.dbf';
  SWITCH DATAFILE 2;
}
```
------------------------------------------------


===================================================================================
-----------------------------------------------------------------------------------
===================================================================================
- Using Disk as Cache for Tape Backups in Data Guard Environment:

- NOTE 1: "Disk" is used as the primary storage for backups. \
		  "Tape" providing long-term, archival storage. 

- NOTE 2: In this scenario, "Incremental Tape backups" are taken daily. \
							"Full Tape backups" are taken weekly.

- NOTE 3: "Fast Recovery Area" on the standby database can serve as a "Disk Cache" for "Tape Backup". \

------------------------------------------------
- Commands for Daily Tape Backups Using Disk as Cache:

- 1. Resynchronize control files for all databases in "Data Guard" setup that are known to "Recovery Catalog".
```
-- (RMAN should be connected to the "target" using the "Oracle Net service name")
-- (All databases must use the same "password file".)

RMAN> RESYNC CATALOG FROM DB_UNIQUE_NAME ALL;
```
- 2. Roll Forward "level 0 copy" of the database by applying the level 1 incremental backup "OSS" that is taken the "day before".
```
-- (On the "first day" this command is run, roll forward is "NOT" performed. Because there is no incremental level 1 yet.)
-- (On the "second day" this command is run, roll forward is "NOT" performed. Because there is only a level 0 incremental.)
-- (On the "third day" and following days, roll forward is performed using the level 1 incremental tagged "OSS" created on the "previous day".)
RMAN> RECOVER COPY OF DATABASE WITH TAG 'OSS';
```
- 3. Create a new level 1 incremental backup. 
```
-- (On the "first day" this command is run, this will be a level 0 incremental.) 
-- (On the "second day" and following days, this will be a level 1 incremental.)
RMAN> BACKUP DEVICE TYPE DISK INCREMENTAL LEVEL 1 FOR RECOVER OF COPY WITH TAG 'OSS' DATABASE;
```
- 4. Backup "archived logs" to "Tape" according to the "Deletion Policy" in place.
```
RMAN> BACKUP DEVICE TYPE SBT ARCHIVELOG ALL;
```
- 5. Backup any "backup sets" created as a result of incremental backup creation.
```
RMAN> BACKUP BACKUPSET ALL;
```
- 6. Deletes "Archived Logs" according to the log "Deletion Policy" set by the "CONFIGURE ARCHIVELOG DELETION POLICY" command.
```
-- (This is only needed if the "fast recovery area" is   "NOT" used to store logs.)
RMAN> DELETE ARCHIVELOG ALL;

```
------------------------------------------------
- Commands for Weekly Tape Backups Using Disk as Cache:

- 1. Backup "all recovery-related files" to Tape.
```
-- (This ensures that all current incremental, image copy, and archived log backups on disk are backed up to tape.)
RMAN> BACKUP RECOVERY FILES;
```
===================================================================================
-----------------------------------------------------------------------------------
===================================================================================
- Performing Backups Directly to Tape:

------------------------------------------------
- Commands for Daily Backups Directly to Tape:

- 1. Connect RMAN to the standby database (as the "target" database) and recovery catalog.

- 2. Execute the CONFIGURE command as follows:
```
RMAN> CONFIGURE DEFAULT DEVICE TYPE TO SBT;
```
- 3. Resynchronize control files for all databases in "Data Guard" setup that are known to "Recovery Catalog".
```
-- (RMAN should be connected to the "target" using the "Oracle Net service name")
-- (All databases must use the same "password file".)
RMAN> RESYNC CATALOG FROM DB_UNIQUE_NAME ALL;
```
- 4. Create a level 1 incremental backup of the database, including all archived logs.
```
-- (On the "first day" this script is run, if no level 0 backups are found, then a level 0 backup is created.)
RMAN> BACKUP AS BACKUPSET INCREMENTAL LEVEL 1 DATABASE PLUS ARCHIVELOG; 
```
- 5. Deletes "Archived Logs" according to the log "Deletion Policy" set by the "CONFIGURE ARCHIVELOG DELETION POLICY" command.
```
-- (This is only needed if the "fast recovery area" is   "NOT" used to store logs.)
RMAN> DELETE ARCHIVELOG ALL;
```
------------------------------------------------
- Commands for Weekly Backups Directly to Tape:

- 1. Connect RMAN to the standby database (as the "target" database) and recovery catalog.

- 2. Create a level 0 database backup that includes all archived logs.
```
RMAN> BACKUP AS BACKUPSET INCREMENTAL LEVEL 0 DATABASE PLUS ARCHIVELOG;
```
- 3. Deletes "Archived Logs" according to the log "Deletion Policy" set by the "CONFIGURE ARCHIVELOG DELETION POLICY" command.
```
-- (This is only needed if the "fast recovery area" is   "NOT" used to store logs.)
RMAN> DELETE ARCHIVELOG ALL;
```
===================================================================================
-----------------------------------------------------------------------------------
===================================================================================
- Report information about a database:

- 1. Connect to the "recovery catalog":

- 2. 
```
RMAN> SET DBID 1625818158;
```
- 3. 
```
RMAN> LIST DB_UNIQUE_NAME OF DATABASE;
```
- 4. List "Archive Logs" for database.
```
RMAN> LIST ARCHIVELOG ALL FOR DB_UNIQUE_NAME orcldb;
```
- 5. List "Database File Names" for database.
```
RMAN> REPORT SCHEMA FOR DB_UNIQUE_NAME orcldb;
```
- 6. List "RMAN Configuration Information" for database.
```
RMAN> SHOW ALL FOR DB_UNIQUE_NAME orcldb;
```

===================================================================================
-----------------------------------------------------------------------------------
===================================================================================
