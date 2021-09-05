# Container Database
[docs.oracle.com](https://docs.oracle.com/database/121/CNCPT/cdbovrvw.htm#CNCPT89245) \
[oracle-base.com](https://oracle-base.com/articles/12c/multitenant-clone-remote-pdb-or-non-cdb-12cr1) \
[oracle-base.com](https://oracle-base.com/articles/12c/multitenant-pdb-refresh-12cr2#create-refreshable-pdb)

======================================================================================================
------------------------------------------------------------------------------------------------------
======================================================================================================
- NOTE 1: you would correct the connect string to use "SERVICEs" instead of "SIDs".


======================================================================================================
------------------------------------------------------------------------------------------------------
======================================================================================================
- Benefits of the Multitenant Architecture:

1. PDB/non-CDB compatibility: 

- 	This guarantee means that a "PDB" behaves the same as a "non-CDB" as seen from a client 
- 		connecting with Oracle Net. The installation scheme for an application back end that runs against 
- 		a non-CDB runs the same against a PDB and produces the same result. 
- 	Also, the run-time behavior of client code that connects to the PDB containing 
- 		the application back end is identical to the behavior of client code that connected 
- 		to the non-CDB containing this back end.
- 	Operations that act on an entire non-CDB act in the same way on an entire CDB, for example, 
- 		when using Oracle Data Guard and database backup and recovery. Thus, the users, administrators, 
- 		and developers of a non-CDB have substantially the same experience after the database has been consolidated.


2. Database consolidation: 
- 	Database consolidation is the process of consolidating data from multiple databases into 
- 		"one database" on "one computer". 
- 	Starting in Oracle Database 12c, the Oracle Multitenant option enables 
- 		you to consolidate data and code without altering existing schemas or applications.


3. Cost reduction:
-	By consolidating hardware and database infrastructure to a single set of background processes, 
-		and efficiently sharing computational and memory resources, you reduce costs for hardware and maintenance. 
-		For example, 100 PDBs on a single server share "one database instance".


4. Easier migration and testing:
- 	For example, instead of "upgrading" a CDB from one database release to another, you can "unplug" a 
- 		PDB from the existing CDB, and then "plug" it into a newly created CDB from a higher release.
- 	You can develop an application on a test PDB and, when it is ready for deployment, 
- 		plug this PDB into the production CDB.


======================================================================================================
------------------------------------------------------------------------------------------------------
======================================================================================================
- Creation of a CDB:


======================================================================================================
------------------------------------------------------------------------------------------------------
======================================================================================================
- Creation of a PDB:

1. Plug In an "Unplugged PDB":
- 	PDB in unplugged state, is a self-contained set of "data files" and an "XML metadata file". 
- 		This technique uses the XML metadata file that describes the PDB and the files associated 
- 		with the PDB to associate it with the CDB.

- Using "NOCOPY":
```
SQL> CREATE PLUGGABLE DATABASE pdb_plug_NOcopy USING '/disk1/usr/financepdb.xml' NOCOPY;
SQL> alter pluggable database pdb_plug_nocopy open;
[ ]$ connect sys/oracle@localhost:1521/pdb_plug_nocopy AS SYSDBA
```
- Using "COPY":
```
SQL> create pluggable database pdb_plug_copy using '/u01/app/oracle/oradata/pdb2.xml' COPY FILE_NAME_CONVERT=('/u01/app/oracle/oradata/cdb1/pdb2','/u01/app/oracle/oradata/cdb2/pdb_plug_copy');
SQL> alter pluggable database pdb_plug_copy open;
[ ]$ connect sys/oracle@localhost:1521/pdb_plug_copy AS SYSDBA
```
- Using "MOVE":
```
SQL> create pluggable database pdb_plug_move AS CLONE using '/u01/app/oracle/oradata/pdb2.xml' MOVE FILE_NAME_CONVERT=('/u01/app/oracle/oradata/cdb1/pdb2','/u01/app/oracle/oradata/cdb2/pdb_plug_move');
SQL> alter pluggable database pdb_plug_move open;
[ ]$ connect sys/oracle@localhost:1521/pdb_plug_move AS SYSDBA
```
-------------------------------------------------------------------------------------------------
2. Creation of a PDB by Cloning a "PDB" or "Non-CDB(12cR1 and later)":
- 	You can use the CREATE PLUGGABLE DATABASE statement to clone a source PDB or non-CDB and plug 
- 		the clone into the CDB.
- (The source can be a PDB in a local or remote CDB, 
-	or starting in Oracle Database 12c Release 1 (12.1.0.2), it can also be a remote non-CDB. )

- Using "Local PDB":
```
SQL> CREATE PLUGGABLE DATABASE salespdb FROM hrpdb;
```
- Using "Remote PDB":
```
SQL> CREATE DATABASE LINK clone_link CONNECT TO remote_clone_user IDENTIFIED BY remote_clone_user USING 'pdb5';
SQL> CREATE PLUGGABLE DATABASE pdb5new  FROM pdb5@clone_link;
SQL> ALTER PLUGGABLE DATABASE pdb5new OPEN;
SQL> SELECT name, open_mode FROM v$pdbs WHERE name = 'PDB5NEW';
NAME     OPEN_MODE
-------- ----------
PDB5NEW  READ WRITE
```
- Using "Remote Non-CDB":
```
--SQL> CREATE PLUGGABLE DATABASE targetpdb 
--	FROM SourcePDBName  /  NON$CDB 
--	@to_source 
--	CREATE_FILE_DEST='*****' ;
SQL> CREATE DATABASE LINK clone_link CONNECT TO remote_clone_user IDENTIFIED BY remote_clone_user USING 'db12c';
SQL> CREATE PLUGGABLE DATABASE db12cpdb FROM NON$CDB@clone_link;
SQL> ALTER SESSION SET CONTAINER=db12cpdb;
SQL> @$ORACLE_HOME/rdbms/admin/noncdb_to_pdb.sql
SQL> ALTER PLUGGABLE DATABASE db12cpdb OPEN;
SQL> SELECT name, open_mode FROM v$pdbs WHERE name = 'DB12CPDB';
NAME      OPEN_MODE
--------- ----------
DB12CPDB  READ WRITE
```
-------------------------------------------------------------------------------------------------
3. Creation of a PDB from a "Non-CDB(Before 12cR1)":
- 	You can move a non-CDB into a PDB by accomplishing one of the following 3 ways:

1. Executing DBMS_PDB.DESCRIBE on a non-CDB in Oracle Database 12c.
2. Using Oracle Data Pump with/without transportable tablespaces.
3. Using Oracle GoldenGate replication.

-------------------------------------------------------------------------------------------------
4. Creation of a PDB from "Seed(as a Template)":
- 	You can use the CREATE PLUGGABLE DATABASE statement to create a PDB by copying the files 
- 		from "PDB$SEED (Seed PDB)", which is a "template" for creating PDBs.
```
SQL> CREATE PLUGGABLE DATABASE hrpdb ADMIN USER dba1 IDENTIFIED BY password;
```

======================================================================================================
------------------------------------------------------------------------------------------------------
======================================================================================================
- List of all PDBs:
```
SQL> SELECT con_id, name PDB_NAME, open_mode, proxy_pdb FROM v$pdbs WHERE name = 'PDB5NEW';
CON_ID  PDB_NAME  OPEN_MODE  PROXY_PDB
------- --------- ---------- ---------
      2 PDB5NEW   READ WRITE NO
      3 DB12CPDB  READ WRITE NO
      5 DB13CPDB  MOUNTED    NO

```
- List of all "Datafiles"/"TempFiles" in a PDB:
```
SQL> SELECT name FROM v$datafile WHERE con_id = 5;
SQL> SELECT name FROM v$tempfile WHERE con_id = 5;
```

- List of all Containers:
```
SQL> SELECT name service_name, pdb FROM   v$services ORDER BY name;
SERVICE_NAME	PDB
--------------- ---------
SYS$BACKGROUND  CDB$ROOT
SYS$USERS       CDB$ROOT
cdb1            CDB$ROOT
cdb1XDB         CDB$ROOT
pdb1            PDB1
pdb2            PDB2
```

- Switch Between Containers:
```
SQL> ALTER SESSION SET CONTAINER=pdb1;
--SQL> ALTER SESSION SET CONTAINER=pdb1 SERVICE=my_new_service;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') pdb FROM   dual;
PDB
-----
PDB1
```

- Create New Service for a PDB(pdb1):
```
SQL> ALTER SESSION SET CONTAINER=pdb1;
SQL> DBMS_SERVICE.create_service('my_new_service','my_new_service');
SQL> DBMS_SERVICE.start_service('my_new_service');
```
======================================================================================================
------------------------------------------------------------------------------------------------------
======================================================================================================
- Proxy PDB:

- 1. DML and DDL is sent to the referenced PDB for execution and the results returned.

- 2. Local Datafiles: \
--	What might seem a little odd is the "SYSTEM", "SYSAUX", "TEMP" and "UNDO" tablespaces are copied \
-- 		to the "local" instance and kept synchronized. \
-- 		All other tablespaces are only present in the "referenced(remote)" instance. 
```
SQL> CREATE PLUGGABLE DATABASE pdb5_proxy AS PROXY FROM pdb5@clone_link;
SQL> ALTER PLUGGABLE DATABASE pdb5_proxy OPEN;

--SQL> CONN / AS SYSDBA  ->  "ERROR"
SQL> CONN sys@cdb1 AS SYSDBA
SQL> ALTER SESSION SET CONTAINER = pdb5_proxy;

SQL> SELECT con_id, target_port, target_host, target_service, target_user FROM v$proxy_pdb_targets;
CON_ID TARGET_PORT TARGET_HOST TARGET_SERVICE                   TARGET_USER
------ ----------- ----------- -------------------------------- -----------
     5        1521 my-server   469d84c85d196311e0538738a8c0b97d       
```
======================================================================================================
------------------------------------------------------------------------------------------------------
======================================================================================================
- Refreshable PDB (Remotely Hot Cloned PDB): \
-- 	Refresh Modes: 	REFRESH MODE EVERY XXX MINUTES  /  REFRESH MODE MANUAL  /  REFRESH MODE NONE(default). \

-- *CONSIDERATIONS*: 	Remember, this is NOT "Data Guard". There is a "lag" between the initiation and \
-- 					completion of the switchover, where transactions against the original primary database \
-- 					could be applied, and not synced with the read-only database before the roles are switched. \
-- 					|||++-->>> As a result, you may "lose" those transactions. <<<--+++||| \
-- 					If this is a problem for you, you need to use "Data Guard"! \

-- 	1. If the source PDB is not available over a "DB link", the "Archived Redo Logs" can be read from \
-- 		a location specified by the optional "REMOTE_RECOVERY_FILE_DEST" parameter. \

-- 	2. New datafiles added to the source PDB are "Automatically" created on the destination PDB. \
-- 		The "PDB_FILE_NAME_CONVERT" parameter must be specified to allow the conversion to take place. \

-- 	3. 


------------------------------------------------------------------------------------------------------
- 1. Create a Refreshable PDB: 
- (Local database): \
- 	Refresh Modes: 	REFRESH MODE EVERY XXX MINUTES  /  REFRESH MODE MANUAL  /  REFRESH MODE NONE(default). \
```
SQL> CREATE PLUGGABLE DATABASE pdb5_ro FROM pdb5@clone_link REFRESH MODE MANUAL;
SQL> ALTER PLUGGABLE DATABASE pdb5_ro OPEN READ ONLY;
SQL> ALTER SESSION SET CONTAINER = pdb5_ro;
SQL> SELECT open_mode FROM v$pdbs WHERE name = 'PDB5_RO';
OPEN_MODE
----------
READ ONLY
SQL> SELECT status, refresh_mode FROM dba_pdbs WHERE  pdb_name = 'PDB5_RO';
STATUS     REFRES
---------- ------
REFRESHING MANUAL


------------------------------------------------------------------------------------------------------
- 2. Refresh a Refreshable PDB:
- (Local database)
```
SQL> ALTER PLUGGABLE DATABASE CLOSE IMMEDIATE;
SQL> ALTER PLUGGABLE DATABASE REFRESH;
SQL> ALTER PLUGGABLE DATABASE OPEN READ ONLY;
```

------------------------------------------------------------------------------------------------------
- 3. Switchover Roles:
- (Remote database)
```
SQL> ALTER SESSION SET CONTAINER = pdb5;
SQL> ALTER PLUGGABLE DATABASE REFRESH MODE MANUAL FROM pdb5_ro@clone_link SWITCHOVER;
SQL> ALTER PLUGGABLE DATABASE OPEN READ ONLY;
SQL> SELECT status, refresh_mode FROM dba_pdbs WHERE  pdb_name = 'PDB5';
STATUS     REFRESH
---------- -------
REFRESHING MANUAL
```
- SwitchBack Roles:
- (Local database) = (new primary database)
```
SQL> ALTER SESSION SET CONTAINER = pdb5_ro;
SQL> ALTER PLUGGABLE DATABASE REFRESH MODE MANUAL FROM pdb5@clone_link SWITCHOVER;
SQL> ALTER PLUGGABLE DATABASE OPEN READ ONLY;
SQL> SELECT status, refresh_mode FROM dba_pdbs WHERE  pdb_name = 'PDB5_RO';
STATUS     REFRES
---------- ------
REFRESHING MANUAL

```
------------------------------------------------------------------------------------------------------

======================================================================================================
------------------------------------------------------------------------------------------------------
======================================================================================================
