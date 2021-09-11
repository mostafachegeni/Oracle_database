# Recovery Catalog Management

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


-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
# Resynchronize the Recovery Catalog

> NOTE 1: RMAN only "automatically" resynchronizes the recovery catalog with a database, 
> when connected to the database as "TARGET". 

> NOTE 2: In "Data Guard", primary and standby should be resynchronized "separately".

> NOTE 3: When to Resynchronize the Recovery Catalog: 
>	-  Resynchronizing After the Recovery Catalog is Unavailable. 
>	-  Resynchronizing in ARCHIVELOG Mode When You Back Up Infrequently.
>	-  Resynchronizing After Configuring a Standby Database.
>	-  Resynchronizing the Recovery Catalog Before Control File Records Age Out.

1- Start RMAN and connect to a target database and recovery catalog.

2. Mount or open the target database
```
RMAN> STARTUP MOUNT;
```
3. Resynchronize the recovery catalog. 
```
	-- Resynchronizes the control file of target database:
	
  RMAN> RESYNC CATALOG;
	
	-- Resynchronizes the control file of standby1:
	RMAN> RESYNC CATALOG FROM DB_UNIQUE_NAME standby1;

	-- Resynchronize control files for all databases in "Data Guard" setup that are known to "Recovery Catalog":
	RMAN> RESYNC CATALOG FROM DB_UNIQUE_NAME ALL;

```


-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
# Performing Backups Directly to Tape:

- Commands for Daily Backups Directly to Tape:

1. Connect RMAN to the standby database (as the "target" database) and recovery catalog.

2. Execute the CONFIGURE command as follows:
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
