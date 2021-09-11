# Initial Load OGG12.2 Higer
=============================================================
-------------------------------------------------------------
=============================================================
- Initial Load [For OGG Versions 12.2 and above]:
[www.oracle-scn.com](https://www.oracle-scn.com/oracle-goldengate-integration-with-datapump-dboptions-enable_instantiation_filtering/)

- Source:
```
SQL> CREATE TABLE HR.MY_TABLE_TEST_3 as select * from hr.employees where employee_id<150;

[ ]$ cd /u01/app/oracle/product/gg/
[ ]$ ./ggsci
GGSCI> DBLogin UserIDAlias ogg_user 


--GGSCI> Add  TranData HR.MY_TABLE_TEST_3  PREPARECSN
GGSCI> Add  TranData HR.MY_TABLE_TEST_3
GGSCI> Info TranData HR.MY_TABLE_TEST_3

SQL> select table_name, scn from dba_capture_prepared_tables where table_owner = 'HR';
TABLE_NAME       SCN
---------------- ----------
MY_TABLE_TEST_3  829695121



GGSCI> view params einta
Extract einta
SETENV (ORACLE_SID='shdgtestdb')
DiscardFile /u01/app/oracle/product/gg/dirrpt/einta.dsc
UserIdAlias ogg_user
TranlogOptions IntegratedParams (max_sga_size 1024, parallelism 5)
Exttrail /u01/app/oracle/product/gg/dirdat/en
LOGALLSUPCOLS
UPDATERECORDFORMAT COMPACT

-- DDL Parameters
DDL INCLUDE MAPPED
DDLOPTIONS REPORT

--table HR.*;
--TABLEEXCLUDE HR.EMPLOYEES;
table HR.MY_TABLE_TEST_3;
table HR.MY_TABLE_TEST_4;
table HR.MY_TABLE_TEST_5;



GGSCI> view params pinta
Extract  pinta
SETENV (ORACLE_SID='shdgtestdb')
UserIdAlias ogg_user
rmthost 192.85.85.49, mgrport 7909, compress
rmttrail /u01/app/oracle/product/gg/dirdat/pn

table HR.*;



GGSCI> Info All 
Program     Status      Group       Lag at Chkpt  Time Since Chkpt
MANAGER     RUNNING
EXTRACT     STOPPED     EINTA       00:00:11      00:00:15
EXTRACT     STOPPED     PINTA       00:00:00      00:00:06


GGSCI> start extract einta
GGSCI> start extract pinta


GGSCI> Info All 
Program     Status      Group       Lag at Chkpt  Time Since Chkpt
MANAGER     RUNNING
EXTRACT     RUNNING     EINTA       00:00:10      00:00:02
EXTRACT     RUNNING     PINTA       00:00:00      00:11:05


```
- Target:
```
[ ]$ cd /u01/app/oracle/product/gg/
[ ]$ ./ggsci
GGSCI> DBLogin UserIDAlias ogg_user 

GGSCI> Info All 
Program     Status      Group       Lag at Chkpt  Time Since Chkpt
MANAGER     RUNNING
REPLICAT    STOPPED     RINTA       00:00:00      00:00:01

```

- Source:
```
[ ]$ vi /home/oracle/expdp_test/expdp_test_query.par
#no Comments
directory=EXPDP_TEST_DIR
dumpfile=expdp_test.dmp
logfile=impdp_test.log
TABLES=HR.MY_TABLE_TEST_3


[ ]$ expdp PARFILE=/home/oracle/expdp_test/expdp_test_query.par
[ ]$ scp /home/oracle/expdp_test/expdp_test.dmp oracle@192.85.85.49:/home/oracle/expdp_test/

```

- Target:
```
GGSCI> view params rinta
Replicat rinta
SETENV(ORACLE_SID='moschdb')
DBOPTIONS INTEGRATEDPARAMS (parallelism 5), ENABLE_INSTANTIATION_FILTERING
AssumeTargetDefs
DiscardFile /u01/app/oracle/product/gg/dirrpt/rinta.dsc, Purge
UserIdAlias ogg_user
--Handlecollisions

-- DDL Parameters
--DDL INCLUDE MAPPED
DDL INCLUDE ALL
DDLOPTIONS REPORT
--ddlerror 1430 ignore
--ddlerror 1432 ignore
--ddlerror 1435 ignore
--ddlerror 904 ignore
--ddlerror 942 ignore

--MAP HR.* , target HR.*;
MAP HR.MY_TABLE_TEST_3 , target HR.MY_TABLE_TEST_3;
MAP HR.MY_TABLE_TEST_4 , target HR.MY_TABLE_TEST_4;
MAP HR.MY_TABLE_TEST_5 , target HR.MY_TABLE_TEST_5;



[ ]$ vi /home/oracle/expdp_test/impdp_test_query.par
#no Comments
directory=EXPDP_TEST_DIR
dumpfile=expdp_test.dmp
logfile=impdp_test.log
TABLES=HR.MY_TABLE_TEST_3


[ ]$ impdp PARFILE=/home/oracle/expdp_test/impdp_test_query.par


SQL> select source_object_name, instantiation_scn, ignore_scn from dba_apply_instantiated_objects where source_object_owner = 'HR';
SOURCE_OBJECT_NAME INSTANTIATION_SCN IGNORE_SCN
------------------ ----------------- ----------
MY_TABLE_TEST_3    829723224         0


GGSCI> Start Replicat rinta 


SQL> select source_object_name, instantiation_scn, ignore_scn from dba_apply_instantiated_objects where source_object_owner = 'HR';
SOURCE_OBJECT_NAME INSTANTIATION_SCN IGNORE_SCN
------------------ ----------------- ----------
MY_TABLE_TEST_3    829723224         0
```
=============================================================
-------------------------------------------------------------
=============================================================
