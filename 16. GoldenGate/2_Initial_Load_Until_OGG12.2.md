# Initial Load for OGG versions prior to 12.2
[blog.dbi-services.com](https://blog.dbi-services.com/performing-an-initial-load-with-goldengate-2-expdpimpdp/)

-------------------------------------------------------------
- **Source**:

```
SQL> CREATE TABLE HR.MY_TABLE_TEST_3 as select * from hr.employees where employee_id<150;

[ ]$ cd /u01/app/oracle/product/gg/
[ ]$ ./ggsci
GGSCI> DBLogin UserIDAlias ogg_user 

GGSCI> Add TranData HR.MY_TABLE_TEST_3
GGSCI> Info TranData HR.MY_TABLE_TEST_3


GGSCI> Info All 
Program     Status      Group       Lag at Chkpt  Time Since Chkpt
MANAGER     RUNNING
EXTRACT     RUNNING     EINTA       00:00:09      00:00:08
EXTRACT     RUNNING     PINTA       00:00:00      00:39:18

```

-------------------------------------------------------------
- **Target**:
```
[ ]$ cd /u01/app/oracle/product/gg/
[ ]$ ./ggsci
GGSCI> DBLogin UserIDAlias ogg_user 


GGSCI> Info All 
Program     Status      Group       Lag at Chkpt  Time Since Chkpt
MANAGER     RUNNING
REPLICAT    STOPPED     RINTA       00:00:00      00:00:01

```

-------------------------------------------------------------
- **Source**:
```
SQL> select current_scn from v$database;
CURRENT_SCN
-----------
    2625151


[ ]$ vi /home/oracle/expdp_test/expdp_test_query.par
#no Comments
directory=EXPDP_TEST_DIR
dumpfile=expdp_test.dmp
logfile=impdp_test.log
TABLES=HR.MY_TABLE_TEST_3
flashback_scn=2625151


[ ]$ expdp PARFILE=/home/oracle/expdp_test/expdp_test_query.par
[ ]$ scp /home/oracle/expdp_test/expdp_test.dmp oracle@192.85.85.49:/home/oracle/expdp_test/

```


-------------------------------------------------------------
- **Target**:
```
[ ]$ vi /home/oracle/expdp_test/impdp_test_query.par
#no Comments
directory=EXPDP_TEST_DIR
dumpfile=expdp_test.dmp
logfile=impdp_test.log
TABLES=HR.MY_TABLE_TEST_3

[ ]$ impdp PARFILE=/home/oracle/expdp_test/impdp_test_query.par

GGSCI> start replicat RINTA, aftercsn 2625151

```

-------------------------------------------------------------


