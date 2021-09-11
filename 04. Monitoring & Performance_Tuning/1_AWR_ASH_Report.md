# AWR ASH Report

[ittutorial.org](https://ittutorial.org/awr-report-automatic-workload-repository-sqlplus-enterprise-manager-and-toad-how-to-generate-in-oracle/) 



-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
- Find "Snapshot Interval", "Retention Interval":
```
SQL> select
  extract( day from snap_interval) *24*60+
  extract( hour from snap_interval) *60+
  extract( minute from snap_interval ) "Snapshot Interval",
  extract( day from retention) *24*60+
  extract( hour from retention) *60+
  extract( minute from retention ) "Retention Interval"
from
   dba_hist_wr_control;

```
- Modify "Snapshot Interval", "Retention Interval":
```
SQL> exec dbms_workload_repository.modify_snapshot_settings (interval => 60, retention => 11520);
```

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
- AWR Report:
```
SQL> grant select any dictionary to myuser;
SQL> grant execute on sys.dbms_workload_repository to myuser;
```
-------------------------------------------------------------------------------------
1. Generate AWR Report (SQL*Plus):
```
SQL> select snap_id, begin_interval_time,end_interval_time from dba_hist_snapshot order by begin_interval_time desc;
SQL> $ORACLE_HOME/rdbms/admin/awrrpt.sql
```
-------------------------------------------------------------------------------------
- Generate AWR Report (TOAD):
```
SQL> select snap_id, begin_interval_time,end_interval_time from dba_hist_snapshot order by begin_interval_time desc;
> Database > Monitor > ADDM/AWR Reports (OEM)
```


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
- ASH:

- Generate ASH Report (TOAD): \
	> Database > Monitor > ASH Reports

-------------------------------------------------------------------------------------
- List of User Active sessions at a specific time:
```
SQL> select  u.username
        ,s.sql_id
        ,s.sql_opname
        ,s.sql_exec_start 
        ,cast(min(s.sample_time) as date)      first_sample_time
        ,cast(max(s.sample_time) as date)      last_sample_time
        ,(max(s.sample_time)-min(s.sample_time)) duration,
    from    DBA_HIST_ACTIVE_SESS_HISTORY s, 
            dba_users u 
    where   s.USER_ID=u.user_id 
        AND s.sample_time > to_date('2021-02-20 14:00:00', 'YYYY-MM-DD HH24:MI:SS')
        AND s.sample_time < to_date('2021-02-20 18:00:00', 'YYYY-MM-DD HH24:MI:SS')
        AND s.sql_exec_start   < to_date('2021-02-20 16:00:00', 'YYYY-MM-DD HH24:MI:SS')
        AND u.username != 'SYS'
    group by    u.username 
                ,s.sql_id
                ,s.sql_exec_start
                ,s.sql_opname
                --,s.session_id, s.session_serial#, s.program, s.module, s.machine
    having  max(s.sample_time) > to_date('2021-02-20 16:00:00', 'YYYY-MM-DD HH24:MI:SS')
    --order by duration desc, s.sql_exec_start
    order by min(s.sample_time), duration desc
    ;

```

-------------------------------------------------------------------------------------
- Parallel Queries by each Schema:
```
with parallel_tbl as (
    SELECT  case    when REGEXP_SUBSTR(b.sql_text, '(PARALLEL|parallel)+ (\d)(\d)') is null  then REGEXP_SUBSTR(b.sql_text, '(PARALLEL|parallel)+ (\d)')
                else REGEXP_SUBSTR(b.sql_text, '(PARALLEL|parallel)+ (\d)(\d)') end parallel_degree
        ,b.parsing_schema_name        
        ,b.last_active_time           
        ,b.last_load_time             
        ,b.sql_text
    FROM v$sqlarea b 
    WHERE   sql_text like '%PARALLE%'
        AND sql_text not like '%NO_PARALLE%'
        AND b.parsing_schema_name != 'SYS'
        AND b.parsing_schema_name != 'ORACLE_OCM'
    ORDER BY b.parsing_schema_name asc
    )
(   select  p.parsing_schema_name
            ,p.parallel_degree
           ,count(*) num_of_queries
    from parallel_tbl p 
    group by parallel_degree, parsing_schema_name 
);

```

-------------------------------------------------------------------------------------
- List of "INSERT Commands" during a specific time period:
```
select  u.username
        ,s.sql_id
        ,s.sql_opname
        ,s.sql_exec_start 
        ,cast(min(s.sample_time) as date)      first_sample_time
        ,cast(max(s.sample_time) as date)      last_sample_time
        ,(max(s.sample_time)-min(s.sample_time)) duration,
        b.sql_text 
    from    DBA_HIST_ACTIVE_SESS_HISTORY s left join v$sqlarea b on s.sql_id=b.sql_id, 
            dba_users u 
    where   s.USER_ID=u.user_id 
        AND s.sample_time >         to_date('2021-04-07 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
        AND s.sample_time <         to_date('2021-04-07 23:59:00', 'YYYY-MM-DD HH24:MI:SS')
        AND u.username != 'SYS'
    group by    u.username 
                ,s.sql_id
                ,s.sql_exec_start
                ,s.sql_opname
                ,b.sql_text 
    having  --max(s.sample_time) > to_date('2021-04-05 16:00:00', 'YYYY-MM-DD HH24:MI:SS') AND 
			s.sql_opname like '%INSERT%'
        --AND b.sql_text like '%INSERT%TBL_REF%'
    --order by duration desc, s.sql_exec_start
    order by min(s.sample_time), duration desc
    ;

```

-------------------------------------------------------------------------------------
- List of "Create/Drop" Specific Tables in last "24 hours":
```
select a.dbusername, a.event_timestamp, a.action_name, a.OBJECT_SCHEMA, a.object_name  
		from unified_audit_trail a
		where 	(action_name like 'CREATE TABLE' OR action_name like 'DROP TABLE')
            AND a.dbusername like 'MYUSER'
            AND a.object_name like 'TBL_%_POST'
            AND a.event_timestamp > sysdate - interval '24' hour
		order by a.event_timestamp desc;
```

