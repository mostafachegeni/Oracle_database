# OGG Performance Tuning 


======================================================================================
--------------------------------------------------------------------------------------
======================================================================================
maa-gg-performance-1969630.pdf
- Oracle Streams Performance Advisor (SPADV):


- (Source Database) Identify the LMP process identifiers:
```
SQL> SELECT c.capture_name, lp.spid FROM V$LOGMNR_PROCESS lp, DBA_CAPTURE c WHERE lp.session_id=c.logminer_id AND lp.role='preparer';
```


======================================================================================
--------------------------------------------------------------------------------------
======================================================================================
- Start/Stop "SPADV" Monitoring:


1. Install "UTL_SPADV" package:
```
SQL> exec DBMS_GOLDENGATE_AUTH.GRANT_ADMIN_PRIVILEGE('GGUSER');

SQL> conn GGUSER/GGUSER
SQL> @$ORACLE_HOME/rdbms/admin/utlspadv.sql

```
2. Start Monitoring:
```
-- (15 seconds)
SQL> exec UTL_SPADV.START_MONITORING(interval=>15);

```
3. Check if the monitoring job is currently running:
```
SQL> SET SERVEROUTPUT ON
SQL> 
DECLARE 
	is_mon   BOOLEAN;
BEGIN 
	is_mon := UTL_SPADV.IS_MONITORING(job_name => 'STREAMS$_MONITORING_JOB',client_name => NULL);
	IF(is_mon=TRUE) THEN DBMS_OUTPUT.PUT_LINE('The monitoring job is running.');
					ELSE DBMS_OUTPUT.PUT_LINE('No monitoring job was found.');
	END IF;
END;

```
4. Create a text report:
```
SQL> spool /tmp/spadv.txt 
SQL> 
begin 
	utl_spadv.show_stats(path_stat_table=>'STREAMS$_PA_SHOW_PATH_STAT',bgn_run_id=> 1,end_run_id=> 9999,show_legend=> TRUE);
end;
```

5. Stop Monitoring:
```
-- (purging the SPADV statistics)
SQL> exec UTL_SPADV.STOP_MONITORING(PURGE=>TRUE);
--SQL> exec UTL_SPADV.STOP_MONITORING;
```

-----------------------------------------------------------------
- Displays SPADV statistics in "real time", once monitoring has been "Started":
-- (
```
-- 		The format: <process name> <idle %> <flow control %> <top event%> <top event name> 
-- 		Mon Mar 29 01:55:07 +0430 2021
-- 		PATH 1 RUN_ID 32 RUN_TIME 2021-MAR-29 01:55:03 CCA Y
-- 		|<R> RINTA 					0.19 148 	0 100% 	0% 
-- 		|<Q> "GGUSER"."OGGQ$RINTA" 	0.19 0.01 	1 
-- 		|<A> OGG$RINTA 				0.19 0.06 	0 			APR 	100% 0% 0% "" 
--															APC 	100% 0% 0% "" 
--															APS(6) 	600% 0% 0% ""
-- 		|<B> NO BOTTLENECK IDENTIFIED
-- )

```

0. (Target Database) ANR process:
```
SQL> SELECT DST_QUEUE_SCHEMA, DST_QUEUE_NAME, TOTAL_MSGS, SPID, STATE from V$PROPAGATION_RECEIVER;
DST_QUEUE_SCHEMA DST_QUEUE_NAME TOTAL_MSGS SPID  STATE
---------------- -------------- ---------- ----- -------------------------------
GGUSER           OGGQ$RINTA         232254 20797 Waiting for message from client

```
1. Start Monitoring:
```
-- (15 seconds)
SQL> exec UTL_SPADV.START_MONITORING(interval=>15);

```
2. 
```
[ ]$ vi /home/oracle/real_mon_spadv.bash
#!/bin/bash

# Set the Oracle environment variables
export ORACLE_SID=moschdb
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/12.2.0/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin

sqlplus -s GGUSER/GGUSER <<!EOS
set feedback off serveroutput on
```
- First need to show first stat line with the legend:
```
begin
utl_spadv.show_stats(path_stat_table=>'STREAMS\$_PA_SHOW_PATH_STAT',bgn_run_id=> -1,end_run_id=> -1,show_legend=> TRUE);
end;
/
!EOS

sleep 15

#Now loop through showing results every 15 seconds, until CTRL-C is issued
d=0
while [ $d -lt 1 ];
do
	date

	#sqlplus -s STREAMSADMIN/STREAMSADMIN <<!EOS
	sqlplus -s GGUSER/GGUSER <<!EOS
	set feedback off serveroutput on

	begin
		utl_spadv.show_stats(path_stat_table=>'STREAMS\$_PA_SHOW_PATH_STAT',bgn_run_id=> -1,end_run_id=> -1,show_legend=> FALSE);
	end;
/

!EOS

	sleep 15
done

```

3. 
```
[ ]$ chmod +x /home/oracle/real_mon_spadv.bash

```

4. 
```
[ ]$ /home/oracle/real_mon_spadv.bash

```

5. Stop Monitoring:
```
-- (purging the SPADV statistics)
SQL> exec UTL_SPADV.STOP_MONITORING(PURGE=>TRUE);
--SQL> exec UTL_SPADV.STOP_MONITORING;
```
======================================================================================
--------------------------------------------------------------------------------------
======================================================================================
