# File and Tablespace Management


- List of "Tablespaces":
```
SQL> select distinct(tablespace_name) from dba_tablespaces;
```
- List of "Datafiles":
```
SQL>COLUMN file_name FORMAT A65 
	SQL>select 	b.tablespace_name 					"TableSpace", 
				b.contents                                      "Contents",
				a.autoextensible 				"Auto_Extention",
				b.bigfile 					"BigFile",
				a.file_name 					"File_Name",
				round(a.Bytes/1024/1024/1024,2) 		"Allocated_Size_GB",
				round(a.maxbytes/1024/1024/1024,2)		"Max_Size_GB",
				round((a.maxbytes-a.Bytes)/1024/1024/1024,2)	"Unallocated_Size_GB"
			from 	dba_data_files a,
					dba_tablespaces b 
			where 	a.tablespace_name=b.tablespace_name 
			order by b.contents, b.tablespace_name, a.Bytes;
```
- Size of each "Data Tablespace":
```
select 	substr(TABLESPACE_NAME,1,20) "TABLESPACE_NAME", 
				sum(Bytes)/1024/1024/1024 Tablespace_Size_GB
			from DBA_SEGMENTS
			group by TABLESPACE_NAME
			order by Tablespace_Size_GB desc;
```
- Size of "TEMP Tablespace":
```
SQL>  select 	tablespace_name 						"TableSpace", 
				round(tablespace_size/1024/1024/1024) 	"Allocated_Size_GB", 
				round(free_space/1024/1024/1024) 		"Usable_Size_GB"
		from dba_temp_free_space;
```
- Sum of Sizes of "Allocated", "Free Allocated", and "Unallocated" Extents in DataFiles used by each "Tablespace":
```
select 	a.tablespace_name 			"Tablespace_Name", 
				a.Free_Allocated_Space_GB 	"Free_Allocated_Space_GB",
				b.Allocated_Size_GB 		"Allocated_Size_GB",
				c.Unallocated_Size_GB 		"Unallocated_Size_GB"
			from 	(
					select 	tablespace_name,
							sum(bytes)/1024/1024/1024 				Free_Allocated_Space_GB
						from 	dba_free_space
						group by tablespace_name
					) 	a, 
					(
					select 	tablespace_name,
							sum(bytes)/1024/1024/1024 				Allocated_Size_GB
						from 	dba_data_files
						group by tablespace_name
					) 	b,
					(select a.tablespace_name 						tablespace_name,
							round(sum((a.maxbytes-a.Bytes)/1024/1024/1024),2)	Unallocated_Size_GB
						from 	dba_data_files a,
							dba_tablespaces b
						where 	a.tablespace_name=b.tablespace_name 
						group by a.tablespace_name
					) 	c
			where 	a.tablespace_name=b.tablespace_name
				and a.tablespace_name=c.tablespace_name
			order by b.Allocated_Size_GB desc;

--check the "UNDO" Tablespace total, free and used space(Size in MB) in Oracle
SELECT 	a.tablespace_name,
		SIZEMB,
		USAGEMB,
		(SIZEMB - USAGEMB) FREEMB
	FROM 	(SELECT SUM (bytes) / 1024 / 1024 SIZEMB, b.tablespace_name
				FROM dba_data_files a, dba_tablespaces b
				WHERE a.tablespace_name = b.tablespace_name AND b.contents like 'UNDO'
				GROUP BY b.tablespace_name
			) a,
			( SELECT c.tablespace_name, SUM (bytes) / 1024 / 1024 USAGEMB
				FROM DBA_UNDO_EXTENTS c
				WHERE status <> 'EXPIRED'
				GROUP BY c.tablespace_name
			) b
	WHERE a.tablespace_name = b.tablespace_name;


--Check "UNDO" usage by User or schema
select u.tablespace_name tablespace, s.username, u.status, sum(u.bytes)/1024/1024 sum_in_mb, count(u.segment_name) seg_cnts
	from dba_undo_extents u, v$transaction t , v$session s
	where u.segment_name = '_SYSSMU' || t.xidusn || '$' and t.addr = s.taddr
	group by u.tablespace_name, s.username, u.status order by 1,2,3;
	
	
--Check the Active, expired and unexpired transaction space usage in "UNDO" Tablespace
--		ACTIVE: 	Status shows us the active transaction going in database, utilizing the undo tablespace and cannot be truncated.
--		EXPIRED: 	Status shows us the transaction which is completed and complete the undo_retention time and now first candidate for trucated from undo tablespace.
--		UNEXPIRED: 	Status shows us the transaction which is completed but not completed the undo retention time. It can be trucated if required.
select tablespace_name tablespace, status, sum(bytes)/1024/1024 sum_in_mb, count(*) counts
	from dba_undo_extents
	group by tablespace_name, status order by 1,2;
```

- Size of "UNDO" Tablespace:
```
/*
--To check the current size of the Undo tablespace:
select sum(a.bytes) as undo_size from v$datafile a, v$tablespace b, dba_tablespaces c where c.contents = 'UNDO' and c.status = 'ONLINE' and b.name = c.tablespace_name and a.ts# = b.ts#;

--To check the free space (unallocated) space within Undo tablespace:
select sum(bytes)/1024/1024 "mb" from dba_free_space where tablespace_name ='[undo tablespace name]';

--To Check the space available within the allocated Undo tablespace:
select tablespace_name, sum(blocks)*8/(1024) reusable_space from dba_undo_extents where status='EXPIRED' group by tablespace_name;

--To Check the space allocated in the Undo tablespace:
select tablespace_name , sum(blocks)*8/(1024) space_in_use from dba_undo_extents where status IN ('ACTIVE','UNEXPIRED') group by  tablespace_name;
*/
--Alternatively, below one SQL can be used as well:
with 	free_sz as 	(select tablespace_name, sum(f.bytes)/1048576/1024 free_gb 
						from dba_free_space f 
						group by tablespace_name ), 
		a as 		(select tablespace_name , sum(case when status = 'EXPIRED' then blocks end)*8/1048576 reusable_space_gb , sum(case when status in ('ACTIVE', 'UNEXPIRED') then blocks end)*8/1048576 allocated_gb 
						from dba_undo_extents where status in ('ACTIVE', 'EXPIRED', 'UNEXPIRED') 
						group by tablespace_name ) , 
		undo_sz as 	(select tablespace_name, df.user_bytes/1048576/1024 user_sz_gb 
						from dba_tablespaces ts join dba_data_files df using (tablespace_name) 
						where ts.contents = 'UNDO' and ts.status = 'ONLINE' ) 
	select tablespace_name, user_sz_gb, free_gb, reusable_space_gb, allocated_gb , free_gb + reusable_space_gb + allocated_gb total 
		from undo_sz join free_sz using (tablespace_name) join a using (tablespace_name);

```
- Determine Size of "UNDO space" used by "Sessions":
```
select  s.sid, s.serial#, NVL(s.username, 'None') username, s.program, r.name UNDO_SEG,
        round(t.used_ublk * TO_NUMBER(x.value)/1024/1024/1024, 2) size_GB
    from    sys.v_$rollname r, 
            sys.v_$session s,
            sys.v_$transaction t,
            sys.v_$parameter x
    where   s.taddr = t.addr 
            --AND sid = '6152' 
            --AND serial# = '47236' 
            AND r.usn = t.xidusn(+) 
            AND x.name = 'db_block_size'
    order by size_gb desc;
```
------------------------------------------------------------
- List of "TempFiles":
```
SQL> COLUMN file_name FORMAT A65 
SQL> select c.CREATION_TIME 						"CREATION_TIME",
			b.tablespace_name 				"TableSpace", 
			a.autoextensible 				"Auto_Extention",
			b.bigfile 					"BigFile",
			a.file_name 					"File_Name",
			round(a.Bytes/1024/1024/1024,2) 		"Allocated_Size_GB",
			round(a.maxbytes/1024/1024/1024,2)		"Max_Size_GB",
			round((a.maxbytes-a.Bytes)/1024/1024/1024,2)	"Unallocated_Size_GB"
		from 	dba_temp_files a,
				dba_tablespaces b,
				v$tempfile c
		where 	a.tablespace_name=b.tablespace_name  
			AND a.file_name=c.name 
		order by b.tablespace_name, a.Bytes;

	CREATION_ TableSpace  Aut Big File_Name                               Allocated_Size_GB Max_Size_GB Unallocated_Size_GB
	--------- ----------- --- --- --------------------------------------- ----------------- ----------- -------------------
	30-JAN-17 TMP         YES YES +DATA/shdg/tempfile/tmp.409.1030798755               2207       32768               30561


```
- Total/Allocated/Free Space in "TEMPORARY" Tablespaces:
```
SQL> select  a.tablespace_name, 
        b.Max_Size_GB,
        a.Allocated_Size_GB,
        a.Free_Allocated_Size_GB 
    from 
    (select tablespace_name, 
            round(tablespace_size/1024/1024/1024) Allocated_Size_GB, 
            round(free_space/1024/1024/1024) 	  Free_Allocated_Size_GB
    from dba_temp_free_space) a, 
    (select tablespace_name, 
            round(sum(GREATEST(bytes,maxbytes))/1024/1024/1024)   Max_Size_GB 
    from 	 dba_temp_files 
    group by tablespace_name) b 
    where a.tablespace_name = b.tablespace_name;

```


--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
- Manage "Permanent" Tablespaces:


- Create a Tablespace:
```
-- DATAFILE '/u01/app/oracle/oradata/orcl/datafile_new_01.dbf' 
SQL> create tablespace MOSCH_TBS 
		DATAFILE '+DATA' 
		size 100M autoextend on next 100M maxsize 32767M;
```
- Create a BigFile Tablespace:
```
SQL> create bigfile tablespace star_tbs     
		datafile 'D:\app\oracle\oradata\ORCL\star_tbs.dbf' 
		size 1g autoextend on next 1g;
```
- Drop a Tablespace:
```
SQL> DROP TABLESPACE MOSCH_TBS [INCLUDING CONTENTS [AND | KEEP] DATAFILES] [CASCADE CONSTRAINTS];
SQL> DROP TABLESPACE MOSCH_TBS INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;
```
------------------------------------------------------------
- Add/Drop a Datafile in Tablespace 'MOSCH_TBS':
```
SQL> ALTER TABLESPACE MOSCH_TBS
		--ADD DATAFILE '/u02/oracle/rbdb1/users03.dbf' SIZE 10G
		ADD DATAFILE '+DATA' SIZE 10G
		AUTOEXTEND ON
		NEXT 1G
		MAXSIZE 32767M;
```


--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
- Manage "Temporary" Tablespaces:


- Set "Default" Temporary Tablespace:
```
SQL> alter database default temporary tablespace TEMP_NEW;
```
------------------------------------------------------------
- Create a "Temporary" Tablespace:
```
SQL> create temporary tablespace TEMP_NEW tempfile '/u01/app/oracle/oradata/orcl/temp_new_01.dbf' size 100M autoextend on next 100M maxsize 32767M;
```

- Drop a "Temporary" Tablespace:

/*
1. Find sessions using "TEMP Tablespace":
```
SQL> select b.tablespace, b.segfile#, b.segblk#, b.blocks, a.sid, a.serial#, a.username, a.osuser, a.status from v$session a, v$sort_usage b where a.saddr=b.session_addr;
	TABLESPACE  SEGFILE#  SEGBLK#  BLOCKS  SID SERIAL# USERNAME  OSUSER   STATUS
	----------- -------- -------- ------- ---- ------- --------- -------- --------
	TEMP             203  3660288     128   19   20513 MOHAJER   Shirzad  INACTIVE
	TEMP_NEW         211      128     128  143   40659 SYS       oracle   ACTIVE
```
2. Kill sessions using "TEMP Tablespace":
```
SQL> alter system kill session 'SID,SERIAL#';
*/
SQL> drop tablespace TEMP including contents and datafiles;
```
------------------------------------------------------------
- Add a new TempFile:
```
SQL> ALTER tablespace temp add tempfile '/u01/app/oracle/oradata/orcl/temp02.dbf' size 10G autoextend on next 1G maxsize 32767M;
```
- Drop a TempFile:
```
SQL> alter database tempfile '/u01/app/oracle/oradata/orcl/temp02.dbf' offline;
SQL> alter database tempfile '/u01/app/oracle/oradata/orcl/temp02.dbf' drop including datafiles;
```


--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
- Manage "RedoLog" Files:


- Switch LogFile Group: 
```
SQL> ALTER system switch logfile;

-- 
SQL> ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT='MANUAL';
```
-----------------------------------------------------------
- List of "LogFiles" Members:
```
SQL> select b.thread#, a.group#, a.member, b.status, b.bytes/1024/1024 BYTES_MB FROM v$logfile a, v$log b WHERE a.group# = b.group# order by b.group#;
```
-----------------------------------------------------------
- List of "Standby LogFiles" Members:
```
SQL> SELECT * from v$logfile order by group#, member;
```
-----------------------------------------------------------
- Add/Drop LogFile Group:
```
SQL> ALTER DATABASE ADD  LOGFILE GROUP 4 '+FRA' SIZE 200M;
SQL> ALTER DATABASE DROP LOGFILE GROUP 4;

SQL> ALTER DATABASE ADD  STANDBY LOGFILE GROUP 5 '+FRA' SIZE 200M;
SQL> ALTER DATABASE DROP STANDBY LOGFILE GROUP 5;
```
-----------------------------------------------------------
- Add/Drop Member:
```
SQL> ALTER DATABASE ADD  LOGFILE MEMBER '+FRA' TO GROUP 3;
SQL> ALTER DATABASE DROP LOGFILE MEMBER '+FRA/ORCLDB/ONLINELOG/group_3.462.1045770301';

SQL> ALTER DATABASE ADD  STANDBY LOGFILE MEMBER '+FRA' TO GROUP 5;
SQL> ALTER DATABASE DROP STANDBY LOGFILE MEMBER '+FRA/ORCLDB/ONLINELOG/group_5.462.1045770443';
```



