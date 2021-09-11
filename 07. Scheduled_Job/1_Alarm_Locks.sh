------------------------------------------------------------------------------------------------
[ ]$ mkdir -p /export/home/companydba/script/log/

------------------------------------------------------------------------------------------------
[oracle@moschdb ~]$ cat /export/home/companydba/script/locks_db_find.sql
set line 300
col Blocking_session for a100
col Blocked_session for a100
set echo off
set feed off
set head off
alter session set nls_calendar=gregorian;
alter session set nls_date_format='DD-MON-YY HH24:MI:SS';
spool /export/home/companydba/script/locks_db.sql
--set time on
--set timing on
select    '(Username='                  || sa.username
        ||', SID='                              || sa.sid
        ||', Serial#='                  || sa.serial#
        ||', SQL_ID='                   || sa.sql_id
        ||', Last_Call_ET='             || sa.last_call_et || ')' "Blocking_session"
        ,' is blocking ',
          '(Username='                  || sb.username
        ||', SID='                              || sb.sid
        ||', Serial#='                  || sb.serial#
        ||', SQL_ID='                   || sb.sql_id       || ')' "Blocked_session"
  from v$lock a, v$lock b, v$session sa, v$session sb
  where           a.block = 1
        and     b.request > 0
        and a.id1 = b.id1
        and a.id2 = b.id2
        and a.sid=sa.sid
        and b.sid=sb.sid
        AND sa.last_call_et > 30*60;
spool off
exit;

-----------------------------------------------------------------------------------------------
[oracle@moschdb ~]$ cat /export/home/companydba/script/locks_db_alert.ksh

#!/bin/bash

export ORACLE_SID=db
export ORACLE_HOME=/oracle/product/19c/db_1
export LD_LIBRARY_PATH=/oracle/product/19c/db_1/lib:/lib
export PATH=$ORACLE_HOME/bin:$PATH


#Empty File Content by Redirecting to Null:
> /export/home/companydba/script/locks_db.sql

#Run SQL Files:
sqlplus USERNAME/PASSWORD << EOF
@/export/home/companydba/script/locks_db_find.sql
EOF

#Send an Email if the file is not empty:
if [[ -s /export/home/companydba/script/locks_db.sql ]]
then
cat /export/home/companydba/script/locks_db.sql | mailx -s "db_ALERT_LOCKS" email@email.ir
fi

#Empty File Content by Redirecting to Null:
> /export/home/companydba/script/locks_db.sql

-----------------------------------------------------------------------------------------------
[oracle@moschdb ~]$ chmod +x /export/home/companydba/script/locks_db_alert.ksh

[oracle@moschdb ~]$ crontab -e
00,30 * * * * /export/home/companydba/script/locks_db_alert.ksh >> /export/home/companydba/script/log/locks_db_alert.log

[oracle@moschdb ~]$ crontab -l

-----------------------------------------------------------------------------------------------
