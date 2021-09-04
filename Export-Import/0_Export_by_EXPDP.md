# Export by EXPDP
[oracle-base.com](https://oracle-base.com/articles/10g/oracle-data-pump-10g) \
[docs.oracle.com](https://docs.oracle.com/database/121/SUTIL/GUID-CDA1477D-4710-452A-ABA5-D29A0F3E3852.htm#SUTIL860) \
[www.techonthenet.com](https://www.techonthenet.com/oracle/between.php)
--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
- Simple Export/Import:

1. 
```
[oracle@ol7 ~]$ mkdir /dvd/Oracle_Database_12cR2/oradata/
```
2.
```
SQL> CONN / AS SYSDBA
SQL> ALTER USER sys IDENTIFIED BY password ACCOUNT UNLOCK;
SQL> CREATE OR REPLACE DIRECTORY expdp_test_dir AS '/dvd/Oracle_Database_12cR2/oradata/';
SQL> GRANT READ, WRITE ON DIRECTORY expdp_test_dir TO sys;
```
3.
```
SQL> select * from ALL_DIRECTORIES;
OWNER  DIRECTORY_NAME  DIRECTORY_PATH                               ORIGIN_CON_ID
------ --------------- -------------------------------------------- -------------
SYS    EXPDP_TEST_DIR  /dvd/Oracle_Database_12cR2/oradata/                      0
SYS    XMLDIR          /dvd/Oracle_Database_12cR2/rdbms/xml                     0
SYS    XSDDIR          /dvd/Oracle_Database_12cR2/rdbms/xml/schema              0
```
4.
```
[oracle@ol7 ~]$ vim expdp_test_query.par
#no Comments
directory=EXPDP_TEST_DIR
dumpfile=expdp_test.dmp
logfile=expdp_test.log
TABLES=HR.EMPLOYEES,HR.LOCATIONS,HR.JOBS,HR.REGIONS
```
5. 
```
--[oracle@ol7 ~]$ expdp scott/tiger TABLES=emp QUERY=\"WHERE job=\'SALESMAN\' and sal \<1600\"
--[oracle@ol7 ~]$ expdp \"sys/qwe123###@192.168.56.20:1521/orcl as sysdba\" PARFILE=emp_query.par
[oracle@ol7 ~]$ expdp PARFILE=expdp_test_query.par
```
6. 
```
[oracle@ol7 ~]$ vim impdp_test_query.par
#no Comments
directory=EXPDP_TEST_DIR
dumpfile=expdp_test.dmp
logfile=impdp_test.log
TABLES=HR.EMPLOYEES,HR.JOBS

[oracle@ol7 ~]$ impdp PARFILE=impdp_test_query.par
```
--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
- List of SQL Commands is put in "ddl.sql":
```
[oracle@ol7 ~]$ impdp directory=EXPDP_TEST_DIR dumpfile=expdp_test.dmp sqlfile=ddl.sql
```
--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
- Filter Data:
```
[oracle@ol7 ~]$ vim expdp_test_query.par
#no comments
schemas=HR
directory=EXPDP_TEST_DIR
dumpfile=expdp_test_1.dmp
logfile=expdp_test_1.log
include=TABLE:"IN ('EMPLOYEES')"
query=HR.EMPLOYEES:"WHERE HIRE_DATE BETWEEN TO_DATE('2004/07/15','yyyy/mm/dd') AND TO_DATE('2005/02/18','yyyy/mm/dd')"
```

--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
- Exclude:
```
[oracle@ol7 ~]$ vim expdp_test_query.par
#Exclude
schemas=HR
directory=EXPDP_TEST_DIR
dumpfile=expdp_test_1.dmp
logfile=expdp_test_1.log
EXCLUDE=TABLE:"IN ( \
'REQUEST01', \
'REQUEST02', \
'REQUEST03' \
)"
```
--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
- Change "Schema":

- (using 'imp'):
```
[oracle@ol7 ~]$ vim expdp_test_query.par
#no Comments
FROMUSER=HR
TOUSER=NEW_USER
directory=EXPDP_TEST_DIR
dumpfile=expdp_test_2.dmp
logfile=impdp_test_2.log
```
- (using 'impdp'):
```
[oracle@ol7 ~]$ vim expdp_test_query.par
#no Comments
REMAP_SCHEMA=HR:NEW_USER
REMAP_TABLESPACE=HR_TBS:NEW_USER_TBS
directory=EXPDP_TEST_DIR
dumpfile=expdp_test_2.dmp
logfile=impdp_test_2.log
```

--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
- Change "Data Type":

1.
```
[oracle@ol7 ~]$ vim expdp_test_query.par
#no Comments
directory=EXPDP_TEST_DIR
dumpfile=expdp_test_2.dmp
logfile=impdp_test_2.log
TABLES=HR.EMPLOYEES,HR.ROLES
CONTENT=METADATA_ONLY
```
2.
```
--SQL> ALTER TABLE NEW_USER.EMPLOYEES DROP COLUMN results cascade constraints;
SQL> ALTER TABLE NEW_USER.EMPLOYEES DROP COLUMN results;
SQL> ALTER TABLE NEW_USER.EMPLOYEES ADD results BLOB;
SQL> ALTER TABLE NEW_USER.EMPLOYEES MODIFY results NOT NULL;
```
3.
```
[oracle@ol7 ~]$ vim expdp_test_query.par
#no Comments
directory=EXPDP_TEST_DIR
dumpfile=expdp_test_2.dmp
logfile=impdp_test_2.log
TABLES=HR.EMPLOYEES,HR.ROLES
CONTENT=DATA_ONLY
```
--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
- Export All MetaData:
```
[oracle@ol7 ~]$ vim expdp_test_query.par
#no Comments
directory=EXPDP_TEST_DIR
dumpfile=expdp_test_4_metadata_115_2.dmp
logfile=expdp_test_4_metadata_115_2.log
FULL=Y
CONTENT=METADATA_ONLY
```

--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
-- 
```
[oracle@ol7 ~]$ vim expdp_test_query.par
#no Comments
...
exclude=statistics
...
```

--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
- Parallel:
```
[oracle@ol7 ~]$ vim expdp_1_query.par
schemas=SHAHKARDB_MAIN
directory=EXPDP_TEST_DIR
parallel=4 
dumpfile=shahkar_%U.dmp 
logfile=expdp_1.log

-------------
/tmp/shahkar_01.dmp
/tmp/shahkar_02.dmp
/tmp/shahkar_03.dmp
-------------

[oracle@ol7 ~]$ vim impdp_1_query.par
schemas=SHAHKARDB_MAIN
directory=EXPDP_TEST_DIR
parallel=4 
dumpfile=shahkar_%U.dmp 
logfile=impdp_1.log

```
--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
- Disable Logging during Import, and automatically Enable Logging when Import is Finished:
- (NOTE: This Parameter has "NO Effect" if Database is in "FORCE LOGGING" mode.)
```
[oracle@ol7 ~]$ vim expdp_test_query.par
#no Comments
...
transform=disable_archive_logging:y
...
```
--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------
- Error:
```
ORA-31693: Table data object "SHAHKARDB_MAIN"."REQUEST" failed to load/unload and is being skipped due to error:
ORA-02354: error in exporting/importing data
ORA-01555: snapshot too old: rollback segment number 33 with name "_SYSSMU33_2612778688$" too small

SQL> select * from v$parameter where name like '%undo_ret%';
NAME		   VALUE
-------------- -----
undo_retention 900

SQL> alter system set undo_retention=20000 scope=both;
```
--------------------------------------------------------------------------
==========================================================================
--------------------------------------------------------------------------

