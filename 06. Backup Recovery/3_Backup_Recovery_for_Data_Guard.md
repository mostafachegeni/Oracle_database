# Backup/Recovery for "Data Guard"

[docs.oracle.com](https://docs.oracle.com/cd/E18283_01/server.112/e17022/rman.htm#SBYDB04700) 

> NOTE 1: In a Data Guard environment, the primary and standby databases share the same "DBID" and "database name". 
> be eligible for registration in the recovery catalog, each database in the Data Guard environment must 
> have different "DB_UNIQUE_NAME" values.

------------------------------------------------
- **Configure "Primary" Database**:

1- Use a server parameter file (SPFILE).

2- Enable Flashback Database.
```
SQL> SELECT flashback_on from v$database;
SQL> ALTER DATABASE FLASHBACK ON;
System altered.
```

3- Connect RMAN to the "primary" as target, and to the "recovery catalog".

4- Register Database in Recovery Catalog:
```
- NOTE 2: If you use RMAN in a "Data Guard" environment, then you can use the "REGISTER DATABASE" 
  command only for the "primary" database. 
  You can use the following techniques to register a "standby" database: 
	1. When you connect to a standby database as TARGET, 
	RMAN automatically registers the database in the recovery catalog. 
	2. When you run the "CONFIGURE DB_UNIQUE_NAME" command for a standby database, 
	RMAN automatically registers this standby database if its primary database is registered. 
```

5- Configure the retention policy for the database as n days:
```
RMAN> CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF <n> DAYS;
```

6- Use "DELETE OBSOLETE" to delete backups that are NOT required according the "retention policy".

7- Specify when archived logs can be deleted. 
```
	-- Delete logs after ensuring that they shipped to all destinations:
	RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO SHIPPED TO ALL STANDBY;
  
	-- Delete logs after ensuring that they were applied on all standby destinations:
	RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;
```

8- Configure "TNS alias" for all "standby" databases.
```
RMAN> CONFIGURE DB_UNIQUE_NAME BOSTON CONNECT IDENTIFIER 'DBSTBY';
RMAN> LIST DB_UNIQUE_NAME OF DATABASE;
```

------------------------------------------------
------------------------------------------------
- **Configure "Guard" Database Where "Backups are Performed"**:

1- Use a server parameter file (SPFILE).

2- Enable Flashback Database.
```
SQL> SELECT flashback_on from v$database;
SQL> ALTER DATABASE FLASHBACK ON;
System altered.
```

3. Connect RMAN to the "standby" database as target, and to the "recovery catalog".

4. Enable automatic backup of the "ControlFile" and the "SPFILE":
```
RMAN> CONFIGURE CONTROLFILE AUTOBACKUP ON;
```

5. Skip backing up datafiles for which there already exists a valid backup with the same checkpoint:
```
RMAN> CONFIGURE BACKUP OPTIMIZATION ON;
```

6. Configure the tape channels to create backups as required by media management software:
```
RMAN> CONFIGURE CHANNEL DEVICE TYPE SBT PARMS '<channel parameters>';
```

7. Specify when the archived logs can be deleted.
```
RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP;
```

------------------------------------------------
------------------------------------------------
- **Configure "Guard" Database Where "Backups are NOT Performed"**:

1- Use a server parameter file (SPFILE).

2- Enable Flashback Database.
```
SQL> SELECT flashback_on from v$database;
SQL> ALTER DATABASE FLASHBACK ON;
System altered.
```

3- Connect RMAN to the "standby" database as target, and to the "recovery catalog".

4- Enable automatic deletion of archived logs once they are applied at the standby database:
```
RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;
```

------------------------------------------------
------------------------------------------------
- **Recovery on "Primary" Using "DataFiles" On a Standby Database**:

1- Connect to "standby" as the "target", and "primary" as "auxiliary":
```
RMAN> CONNECT TARGET sys@DBSTBY
RMAN> CONNECT AUXILIARY sys@DBPRIM
```

2- Backup the datafile on the "standby" host across the network to a location on the "primary" host.
```
RMAN> BACKUP AS COPY DATAFILE 2 AUXILIARY FORMAT '/disk9/df2copy.dbf';
```

3- Exit the RMAN client as follows:
```
EXIT;
```

4- connect to the primary database as target, and to the recovery catalog:
```
RMAN> CONNECT TARGET sys@DBPRIM;
RMAN> CONNECT CATALOG rman@DBCAT;
```

5- Catalog the datafile copy:
```
RMAN> CATALOG DATAFILECOPY '/disk9/df2copy.dbf';
```

6- Switch the datafile copy so that /disk9/df2copy.dbf becomes the "current datafile":
```
RUN {
  SET NEWNAME FOR DATAFILE 2 TO '/disk9/df2copy.dbf';
  SWITCH DATAFILE 2;
}
```


------------------------------------------------
------------------------------------------------
- **Using Disk as Cache for Tape Backups in Data Guard Environment**:

> NOTE 1: "Disk" is used as the primary storage for backups. 
> "Tape" providing long-term, archival storage. 

> NOTE 2: In this scenario, "Incremental Tape backups" are taken daily. 
> "Full Tape backups" are taken weekly.

> NOTE 3: "Fast Recovery Area" on the standby database can serve as a "Disk Cache" for "Tape Backup". 

------------------------------------------------
------------------------------------------------
- **Commands for Daily Tape Backups Using Disk as Cache**:

1- Resynchronize control files for all databases in "Data Guard" setup that are known to "Recovery Catalog".
```
-- (RMAN should be connected to the "target" using the "Oracle Net service name")
-- (All databases must use the same "password file".)

RMAN> RESYNC CATALOG FROM DB_UNIQUE_NAME ALL;
```

2- Roll Forward "level 0 copy" of the database by applying the level 1 incremental backup "OSS" that is taken the "day before".
```
-- (On the "first day" this command is run, roll forward is "NOT" performed. Because there is no incremental level 1 yet.)
-- (On the "second day" this command is run, roll forward is "NOT" performed. Because there is only a level 0 incremental.)
-- (On the "third day" and following days, roll forward is performed using the level 1 incremental tagged "OSS" created on the "previous day".)
RMAN> RECOVER COPY OF DATABASE WITH TAG 'OSS';
```

3- Create a new level 1 incremental backup. 
```
-- (On the "first day" this command is run, this will be a level 0 incremental.) 
-- (On the "second day" and following days, this will be a level 1 incremental.)
RMAN> BACKUP DEVICE TYPE DISK INCREMENTAL LEVEL 1 FOR RECOVER OF COPY WITH TAG 'OSS' DATABASE;
```

4- Backup "archived logs" to "Tape" according to the "Deletion Policy" in place.
```
RMAN> BACKUP DEVICE TYPE SBT ARCHIVELOG ALL;
```

5- Backup any "backup sets" created as a result of incremental backup creation.
```
RMAN> BACKUP BACKUPSET ALL;
```

6- Deletes "Archived Logs" according to the log "Deletion Policy" set by the "CONFIGURE ARCHIVELOG DELETION POLICY" command.
```
-- (This is only needed if the "fast recovery area" is   "NOT" used to store logs.)
RMAN> DELETE ARCHIVELOG ALL;

```
