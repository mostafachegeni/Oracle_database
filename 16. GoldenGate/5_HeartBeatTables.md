# **Automatic Heartbeat Tables to Monitor**

[docs.oracle.com](https://docs.oracle.com/en/middleware/goldengate/core/19.1/admin/monitoring-oracle-goldengate-processing.html#GUID-59E61274-BDDE-4D4B-9681-ED0BC39E9FCF) \
[www.ateam-oracle.com](https://www.ateam-oracle.com/oracle-goldengate-integrated-heartbeat) \
[k21academy.com](https://k21academy.com/oracle-goldengate-12c/the-heartbeat-table-of-oracle-goldengate-12-2/) \
[www.oracle-scn.com](https://www.oracle-scn.com/oracle-goldengate-12-2-enhanced-heartbeat-table/) 

-------------------------------------------------------------


>	NOTE 1: 
>	Taking the defaults, every 60 seconds an update is performed against the gg_heartbeat_seed table. 
>	This record is captured and replicated to the target tables gg_heartbeat_seed, gg_heartbeat, and gg_heartbeat_history. 
>	The target table gg_heartbeat contains the data from the last heartbeat record processed by Replicat while the table gg_heartbeat_history contains all hearbeat records. 


>	NOTE 2: 
>	SOURCE -> The source side gg_heartbeat_seed table records the local (source) database name and the timestamp of the last heartbeat. 
>	TARGET -> The target side gg_heartbeat table contains the last heartbeat record, with additional information added by every Oracle GoldenGate Group in the replication stream. 

------------------------------------------------------------------------------
1- **Source**:

```
[ ]$ cd /u01/app/oracle/product/gg/
[ ]$ ./ggsci
GGSCI> edit params ./GLOBALS
GGSCHEMA GGUSER


GGSCI> exit


[ ]$ cd /u01/app/oracle/product/gg/
[ ]$ ./ggsci
GGSCI> DBLogin UserIDAlias ogg_user 


/*
ADD HEARTBEATTABLE [, FREQUENCY number in seconds] [, RETENTION_TIME number in days] | [, PURGE_FREQUENCY number in days]

-- FREQUENCY: Specifies how often the heartbeat seed table and heartbeat table are updated. For example, how frequently heartbeat records are generated. The default is 60 seconds.
-- RETENTION_TIME: Specifies when heartbeat entries older than the retention time in the history table are purged. The default is 30 days.
-- PURGE_FREQUENCY: Specifies how often the purge scheduler is run to delete table entries that are older than the retention time from the heartbeat history . The default is 1 day.
*/

-- ALTER HEARTBEATTABLE
-- ENABLE_HEARBEAT_TABLE
-- DISABLE_HEARBEAT_TABLE
-- DELETE HEARTBEATTABLE
GGSCI> add HEARTBEATTABLE

```

- Restart Extracts:
```
GGSCI> stop  Extract einta
GGSCI> stop  Extract pinta

GGSCI> start Extract einta
GGSCI> start Extract pinta

GGSCI> Info All 

```

- List of HeartBeat Objects:
```
SQL> SELECT owner, object_name, object_type 
		from dba_objects 
		where 	owner = 'GGUSER' and 
				(object_name like '%HEARTBEAT%' OR object_name like '%LAG%' OR object_name like '%HB%');
OWNER   OBJECT_NAME           OBJECT_TYPE 
------- --------------------- ------------
GGUSER  GG_HEARTBEAT_SEED     TABLE       
GGUSER  GG_HEARTBEAT          TABLE       
GGUSER  GG_HEARTBEAT_HISTORY  TABLE       
GGUSER  GG_LAG                VIEW        
GGUSER  GG_LAG_HISTORY        VIEW        
GGUSER  GG_UPDATE_HB_TAB      PROCEDURE   
GGUSER  GG_PURGE_HB_TAB       PROCEDURE   
GGUSER  GG_UPDATE_HEARTBEATS  JOB         
GGUSER  GG_PURGE_HEARTBEATS   JOB         

```
------------------------------------------------------------------------------
2- **Target**:
```
[ ]$ cd /u01/app/oracle/product/gg/
[ ]$ ./ggsci
GGSCI> edit params ./GLOBALS
GGSCHEMA GGUSER


GGSCI> exit


[ ]$ cd /u01/app/oracle/product/gg/
[ ]$ ./ggsci
GGSCI> DBLogin UserIDAlias ogg_user 

GGSCI> add heartbeattable


```
- Restart Replicat:
```
GGSCI> stop  Extract rinta
GGSCI> start Extract rinta

GGSCI> Info All 

```
- List of HeartBeat Objects:
```
SQL> SELECT owner, object_name, object_type 
		from dba_objects 
		where 	owner = 'GGUSER' and 
				(object_name like '%HEARTBEAT%' OR object_name like '%LAG%' OR object_name like '%HB%');
OWNER   OBJECT_NAME           OBJECT_TYPE 
------- --------------------- ------------
GGUSER  GG_HEARTBEAT_SEED     TABLE       
GGUSER  GG_HEARTBEAT          TABLE       
GGUSER  GG_HEARTBEAT_HISTORY  TABLE       
GGUSER  GG_LAG                VIEW        
GGUSER  GG_LAG_HISTORY        VIEW        
GGUSER  GG_UPDATE_HB_TAB      PROCEDURE   
GGUSER  GG_PURGE_HB_TAB       PROCEDURE   
GGUSER  GG_UPDATE_HEARTBEATS  JOB         
GGUSER  GG_PURGE_HEARTBEATS   JOB         


```

------------------------------------------------------------------------------
3- **Target**:

>	NOTE 1: The timestamps recorded are in UTC format. 

>	NOTE 2: Lag computations require that the source and target server clocks be setup correctly. 
>	Regularly synced with a network time service. 


- Monitor the GoldenGate Lags:
```
SQL> select local_database, current_local_ts, remote_database, incoming_path, incoming_lag from GGUSER.gg_lag;
```

- Monitor GoldenGate Lags over "Long Periods" of time:
```
SQL> col LOCAL_DATABASE 		for a30
SQL> col HEARTBEAT_RECEIVED_TS  for a30
SQL> col REMOTE_DATABASE        for a30
SQL> col INCOMING_PATH          for a30
SQL> col INCOMING_LAG           for a30
SQL> select local_database, heartbeat_received_ts, remote_database, incoming_path, incoming_lag 
		from GGUSER.gg_lag_history
		order by HEARTBEAT_RECEIVED_TS desc;

```

- Lag across the replication stream in "seconds":
>	- Description of columns in the gg_heartbeat_history table: 
>	(a) incoming_heartbeat_ts – source side heartbeat timestamp 
>	(b) incoming_extract_ts – timestamp when extract processed the heartbeat record 
>	(c) incoming_routing_ts – timestamp when data pump read the heartbeat record from the extract trail 
>	(d) incoming_replicat_ts – timestamp when replicat read the heartbeat record from the remote trail 
>	(e) heartbeat_received_ts   - timestamp when replicat applied the heartbeat record to the target 

>	- With this information, we can now compute the following: 
>	(a) heartbeat_received_ts - incoming_heartbeat_ts = total end-to-end lag 
>	(b) incoming_extract_ts -  incomning_heartbeat_ts = cdc extract lag 
>	(b) incoming_routing_ts – incoming_extract_ts = data pump read lag 
>	(c) incoming_replicat_ts – incoming_routing_ts = replicat read lag 
>	(d) heartbeat_received_ts – incoming_replicat_ts = replicat apply lag 

```
SQL> set hea on 
SQL> set wrap off 
SQL> set line 300 
SQL> column Extract format a9 
SQL> column Data_Pump format a10 
SQL> column Replicat format a9 
SQL> select to_char(incoming_heartbeat_ts,'DD-MON-YY HH24:MI:SSxFF') Source_HB_Ts, 
			incoming_extract Extract, 
			extract (day from (incoming_extract_ts - incoming_heartbeat_ts))*24*60*60+          
			extract (hour from (incoming_extract_ts - incoming_heartbeat_ts))*60*60+          
			extract (minute from (incoming_extract_ts - incoming_heartbeat_ts))*60+          
			extract (second from (incoming_extract_ts - incoming_heartbeat_ts)) Extract_Lag, 
			incoming_routing_path Data_Pump, 
			extract (day from (incoming_routing_ts - incoming_extract_ts))*24*60*60+          
			extract (hour from (incoming_routing_ts - incoming_extract_ts))*60*60+          
			extract (minute from (incoming_routing_ts - incoming_extract_ts))*60+          
			extract (second from (incoming_routing_ts - incoming_extract_ts)) Data_Pump_Read_Lag, 
			incoming_replicat Replicat, 
			extract (day from (incoming_replicat_ts - incoming_routing_ts))*24*60*60+          
			extract (hour from (incoming_replicat_ts - incoming_routing_ts))*60*60+          
			extract (minute from (incoming_replicat_ts - incoming_routing_ts))*60+          
			extract (second from (incoming_replicat_ts - incoming_routing_ts)) Replicat_Read_Lag, 
			extract (day from (heartbeat_received_ts - incoming_replicat_ts))*24*60*60+          
			extract (hour from (heartbeat_received_ts - incoming_replicat_ts))*60*60+          
			extract (minute from (heartbeat_received_ts - incoming_replicat_ts))*60+          
			extract (second from (heartbeat_received_ts - incoming_replicat_ts)) Replicat_Apply_Lag, 
			extract (day from (heartbeat_received_ts - incoming_heartbeat_ts))*24*60*60+          
			extract (hour from (heartbeat_received_ts - incoming_heartbeat_ts))*60*60+          
			extract (minute from (heartbeat_received_ts - incoming_heartbeat_ts))*60+          
			extract (second from (heartbeat_received_ts - incoming_heartbeat_ts)) Total_Lag  
		from GGUSER.gg_heartbeat_history 
		order by heartbeat_received_ts desc;

```

------------------------------------------------------------------------------
