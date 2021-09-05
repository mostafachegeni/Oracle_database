# Locks
=====================================================================================
-------------------------------------------------------------------------------------
=====================================================================================
- Locked_Mode: \
--  	0 -> NONE: lock requested but not yet obtained \
--  	1 -> NULL \
--  	2 -> ROWS_S (SS): Row Share Lock \
--  	3 -> ROW_X (SX): Row Exclusive Table Lock \
--  	4 -> SHARE (S): Share Table Lock \
--  	5 -> S/ROW-X (SSX): Share Row Exclusive Table Lock \
--  	6 -> Exclusive (X): Exclusive Table Lock 


=====================================================================================
-------------------------------------------------------------------------------------
=====================================================================================
- time limit for how long DDL statements will Wait in "DML Lock Queue":
```
SQL> select a.name, a.value from v$parameter a where name like '%ddl_lock_timeout%';
```
=====================================================================================
-------------------------------------------------------------------------------------
=====================================================================================
- List of "All Locks" on a Specific Object (In RAC use "GV$locked_object"):
```
SQL> select b.owner object_owner, b.object_name, b.subobject_name, b.object_type, b.created object_created, b.status object_status, 
			c.username lock_username, c.SID lock_sid, c.serial# lock_serial#, a.locked_mode, c.PROGRAM lock_program, c.sql_id lock_sql_id, c.state lock_state, 
            (select q.sql_text 	from v$sqlarea q where q.sql_id=c.sql_id) 		 lock_request_sqltext,
            (select q.sql_text 	from v$sqlarea q, v$session s2 where q.sql_id=s2.sql_id and s2.sid=c.blocking_session) 	Blocking_sqltext
        from gv$locked_object a, dba_objects b, gv$session c
			-- v$locked_object a, dba_objects b, v$session c
        where   a.object_id=b.object_id 
            and a.session_ID=c.SID 
            and b.object_name like '%STAR_REF%'
        order by owner, b.object_name, a.locked_mode desc;

```
- List of "Blocking Locks" on a Specific Object (In RAC use "GV$locked_object"):
```
SQL> select b.owner object_owner, b.object_name, b.subobject_name, b.object_type, b.created object_created, b.status object_status, 
			c.username lock_username, c.SID lock_sid, c.serial# lock_serial#, a.locked_mode, c.PROGRAM lock_program, c.sql_id lock_sql_id, c.state lock_state, 
			s.sid 						blocking_sid,
			s.serial# 					blocking_serial#,
			s.blocking_session_status 	blocking_session_status,
			s.sql_id 					blocking_sql_id,
			s.program 					blocking_program,
            (select q.sql_text 	from v$sqlarea q where q.sql_id=c.sql_id) 		 lock_request_sqltext,
            (select q.sql_text 	from v$sqlarea q, v$session s2 where q.sql_id=s2.sql_id and s2.sid=c.blocking_session) 	Blocking_sqltext
        from gv$locked_object a, dba_objects b, gv$session c, v$session s
			-- v$locked_object a, dba_objects b, v$session c
        where   a.object_id=b.object_id 
            and a.session_ID=c.SID 
			and c.blocking_session=s.sid
            --and b.object_name like '%INVENTORY%'
        order by owner, b.object_name, a.locked_mode desc;
```
=====================================================================================
-------------------------------------------------------------------------------------
=====================================================================================
- List of "Blocking/Blocked Sessions":
```
SQL> select sa.username     blocking_username, 
			sa.sid          blocking_SID, 
			sa.serial#      blocking_serial#, 
			sa.sql_id       blocking_sql_id ,
			sa.last_call_et blocking_last_call_et,
			a.LMODE 		Blocking_Lock_Mode,
			' is blocking ',
			sb.username     blocked_username, 
			sb.sid          blocked_SID, 
			sb.serial#      blocked_serial#, 
			sb.sql_id       blocked_sql_id,
			sb.last_call_et blocked_last_call_et,
			b.LMODE 		Blocked_Lock_Mode
    from v$lock a, v$lock b, v$session sa, v$session sb 
    where   a.block=1
        and b.request>0
        and a.id1=b.id1
        and a.id2=b.id2
        and a.sid=sa.sid
        and b.sid=sb.sid;


    
SQL> SELECT l1.LMODE Blocking_Lock_Mode, l2.LMODE Blocked_Lock_Mode, 
		'Instance '||s1.INST_ID|| ':   ' || s1.username || '@' || s1.machine
        || ' ( SID,SERIAL#=' || s1.sid || ','|| s1.serial# || ', status=' || s1.status|| ', sql_id=' || s1.sql_id || '  )    is blocking   '
        || s2.username || '@' || s2.machine || ' ( SID,SERIAL#=' || s2.sid || ',' || s2.serial# || ', status=' || s2.status || ', sql_id=' || s2.sql_id || ' ) '  
		,(select sql_text from v$sqlarea q where q.sql_id=s1.sql_id) blocking_sqltext
		,(select sql_text from v$sqlarea q where q.sql_id=s2.sql_id) waiting_sqltext
        FROM    gv$lock l1, gv$session s1, gv$lock l2, gv$session s2
        WHERE   s1.sid=l1.sid           AND
                s1.inst_id=l1.inst_id   AND
                s2.sid=l2.sid           AND
                s2.inst_id=l2.inst_id   AND
                l1.BLOCK=1              AND
                l2.request > 0          AND
                l1.id1 = l2.id1         AND
                l2.id2 = l2.id2 ;



SQL> SELECT c.holding_session blocking_SID, b.serial# blocking_serial#, b.username blocking_username, b.sql_id Blocking_sql_id, 
            c.waiting_session waiting_SID, a.serial# waiting_serial#, a.username waiting_username, a.sql_id Waiting_sql_id, 
            c.lock_type, c.mode_held, c.mode_requested,
			(select sql_text from v$sqlarea q where q.sql_id=b.sql_id) blocking_sql_text,
			(select sql_text from v$sqlarea q where q.sql_id=a.sql_id) waiting_sql_text
    FROM sys.v_$session b,
         sys.dba_waiters c,
         sys.v_$session a
    WHERE c.holding_session=b.sid and
          c.waiting_session=a.sid;
```
=====================================================================================
-------------------------------------------------------------------------------------
=====================================================================================
- History of Locks (Between "BEGIN_SNAP_ID" and "END_SNAP_ID"):
```
select distinct
    -- Snapshot ID
    min(blocked.snap_id)      as first_snap_id,
    max(blocked.snap_id)      as last_snap_id,

    -- Sample ID and Time
    min(blocked.sample_id)    as first_sample_id,
    min(blocked.sample_id)    as last_sample_id,
    to_char(
        min(blocked.sample_time),
        'YYYY-MM-DD HH24:MI:SS'
    )                         as first_sample_time,
    to_char(
        max(blocked.sample_time),
        'YYYY-MM-DD HH24:MI:SS'
    )                         as last_sample_time,

    -- Session causing the block
    blocker.instance_number   as blocker_instance_number,
    blocker.machine           as blocker_machine,
    blocker.program           as blocker_program,
    blocker.session_id        as blocker_sid,
    blocker_user.username     as blocker_username,

    ' -> '                    as is_blocking,

    -- Sesssion being blocked
    blocked.instance_number   as blocked_instance_number,
    blocked.machine           as blocked_machine,
    blocked.program           as blocked_program,
    blocked.session_id        as blocked_sid,
    blocked_user.username     as blocked_username,
    blocked.session_state     as blocked_session_state,
    blocked.event             as blocked_event,
    blocked.blocking_session  as blocked_blocking_session,
    blocked.sql_id            as blocked_sql_id,
    blocked.sql_child_number  as blocked_sql_child_number,
    sys_obj.name              as blocked_table_name,
    dbms_rowid.rowid_create(
        rowid_type    => 1,
        object_number => blocked.current_obj#,
        relative_fno  => blocked.current_file#,
        block_number  => blocked.current_block#,
        row_number    => blocked.current_row#
    )                         as blocked_rowid,
    blocked_sql.sql_text      as blocked_sql_text
from
    dba_hist_active_sess_history blocker
    inner join
    dba_hist_active_sess_history blocked
        on blocker.session_id = blocked.blocking_session
        and blocker.session_serial# = blocked.blocking_session_serial# 
    inner join
    sys.obj$ sys_obj
        on sys_obj.obj# = blocked.current_obj#
    inner join
    dba_users blocker_user
        on blocker.user_id = blocker_user.user_id
    inner join
    dba_users blocked_user
        on blocked.user_id = blocked_user.user_id
    left outer join
    v$sql blocked_sql
        on blocked_sql.sql_id = blocked.sql_id
        and blocked_sql.child_number = blocked.sql_child_number
    left outer join
    v$sql blocker_sql
        on blocker_sql.sql_id = blocker.sql_id
        and blocker_sql.child_number = blocker.sql_child_number
where
    blocked.snap_id between BEGIN_SNAP_ID and END_SNAP_ID
and
    blocked.event = 'enq: TX - row lock contention'
group by
    blocker.instance_number,
    blocker.machine,
    blocker.program,
    blocker.session_id,
    blocker_user.username,
    ' -> ',
    blocked.instance_number,
    blocked.machine,
    blocked.program,
    blocked.session_id,
    blocked_user.username,
    blocked.session_state,
    blocked.event,
    blocked.blocking_session,
    blocked.sql_id,
    blocked.sql_child_number,
    sys_obj.name,
    dbms_rowid.rowid_create(
        rowid_type    => 1,
        object_number => blocked.current_obj#,
        relative_fno  => blocked.current_file#,
        block_number  => blocked.current_block#,
        row_number    => blocked.current_row#
    ),
    blocker_sql.sql_text,
    blocked_sql.sql_text
order by
    first_sample_id;
```
=====================================================================================
-------------------------------------------------------------------------------------
=====================================================================================
