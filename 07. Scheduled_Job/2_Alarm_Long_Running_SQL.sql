------------------------------------------------------------------------------------------------
[ ]$ mkdir -p /export/home/mohaymendba/script/log/

------------------------------------------------------------------------------------------------
[ ]$ cat /export/home/mohaymendba/script/long_running_trans_db_find.sql
set line 300
col username for a15
col machine for a30
set echo off
set feed off
--set head off
alter session set nls_calendar=gregorian;
alter session set nls_date_format='DD-MON-YY HH24:MI:SS';
spool /export/home/mohaymendba/script/long_running_trans_db.sql
--set time on
--set timing on
SELECT 	username, 
        round(LAST_CALL_ET/60) 							LAST_CALL_ET_minute,
        ROUND(sysdate - (LAST_CALL_ET)/(24*60*60),'MI') LAST_CALL,
        SID, SERIAL#, status, machine, program, sql_id 
    FROM    v$session 
    WHERE   username is not null 
        AND username not like 'SYS' 
        AND sql_id is not null 
        AND status = 'ACTIVE'
		AND program not like 'sqlldr%'
        AND LAST_CALL_ET > 60*60;
spool off
exit;

-----------------------------------------------------------------------------------------------
[oracle@moschdb ~]$ cat /export/home/mohaymendba/script/long_running_db_alert.ksh

#!/bin/bash

export ORACLE_SID=db
export ORACLE_HOME=/oracle/product/19c/db_1
export LD_LIBRARY_PATH=/oracle/product/19c/db_1/lib:/lib
export PATH=$ORACLE_HOME/bin:$PATH


#Empty File Content by Redirecting to Null:
> /export/home/mohaymendba/script/long_running_trans_db.sql

#Run SQL Files:
sqlplus USERNAME/PASSWORD << EOF
@/export/home/mohaymendba/script/long_running_trans_db_find.sql
EOF

#Send an Email if the file is not empty:
if [[ -s /export/home/mohaymendba/script/long_running_trans_db.sql ]]
then
cat /export/home/mohaymendba/script/long_running_trans_db.sql | mailx -s "db_ALERT_LONG_RUNNING" email@email.ir
fi

#Empty File Content by Redirecting to Null:
> /export/home/mohaymendba/script/long_running_trans_db.sql

-----------------------------------------------------------------------------------------------
[oracle@moschdb ~]$ chmod +x /export/home/mohaymendba/script/long_running_db_alert.ksh

[oracle@moschdb ~]$ crontab -e
00,30 * * * * /export/home/mohaymendba/script/long_running_db_alert.ksh >> /export/home/mohaymendba/script/log/long_running_db_alert.log

[oracle@moschdb ~]$ crontab -l
