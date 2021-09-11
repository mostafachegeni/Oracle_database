----------------------------------------------------------------
-- Instance Startup_Time:
select * from v$instance;

-- TBSs:
select * from MOSCH.TABLESPACE_SPACE_HISTORY_2020_08_09 where log_date > sysdate -1 order by log_date desc, total_allocated_size_gb desc;
select * from MOSCH.TABLESPACE_SPACE_HISTORY            where log_date > sysdate -1 order by log_date desc, total_allocated_size_gb desc;

-- TEMP Tbs:
select min(ROUND(temp_free_size)) "TEMP_Min_Free_GB" from MOSCH.TEMP_SPACE_REPORT_2020_07_21 where log_date>sysdate-1 order by log_date desc;
select * from mosch.TEMP_SPACE_REPORT_2020_07_21 order by log_date desc;

-- Disk:
select * from MOSCH.DISK_SPACE_HISTORY_2020_08_09 where diskgroup_NAME like '%DATA%' order by log_date desc, group_number asc;
select  log_date, group_number, diskgroup_name, STATUS, TOTAL_GB, (TOTAL_GB-USABLE_GB) USED_GB, USABLE_GB from MOSCH.DISK_SPACE_HISTORY_2020_08_09 where log_date > sysdate - interval '1' hour order by group_number asc;

-- InMemory:
select min(ROUND((allocated_bytes-used_bytes)/1024/1024/1024)) "In-Memory Min Free_GB" from MOSCH.IM_AREA_HISTORY where log_date>sysdate-1 and pool like '%1MB%' order by log_date desc;
select  log_date, pool, con_id, populate_status, 
        ROUND(allocated_bytes/1024/1024/1024)              "ALLOCATED_GB",
        ROUND(used_bytes/1024/1024/1024)                   "USED_GB", 
        ROUND((allocated_bytes-used_bytes)/1024/1024/1024) "Free_GB" 
    from     MOSCH.IM_AREA_HISTORY 
    where    pool like '%1MB%'
    order by log_date desc;


-- Find Candidated TBSs to SHRINK:
select log_date, tablespace_name, total_allocated_size_gb, used_allocate_size_gb, total_allocated_size_gb-used_allocate_size_gb free_gb from MOSCH.TABLESPACE_SPACE_HISTORY_2020_08_09 where log_date > sysdate -1 order by used_allocate_size_gb desc, free_gb desc;
select log_date, tablespace_name, total_allocated_size_gb, used_allocate_size_gb, total_allocated_size_gb-used_allocate_size_gb free_gb from MOSCH.TABLESPACE_SPACE_HISTORY            where log_date > sysdate -1 order by used_allocate_size_gb desc, free_gb desc;
select  b.tablespace_name, b.DataFile_Size_GB, a.Segments_Allocated_Space_GB, DataFile_Size_GB-Segments_Allocated_Space_GB free_gb
    from 
    (select  /*+ parallel(dba_data_files,16) */ b.tablespace_name,
        round(sum(a.Bytes/1024/1024/1024),2) DataFile_Size_GB
    from 	dba_data_files a, 
            dba_tablespaces b 
    where       a.tablespace_name=b.tablespace_name 
    group by    b.tablespace_name) b 
    LEFT OUTER JOIN 
    (select  /*+ parallel(DBA_SEGMENTS,16) */ tablespace_name, 
        round(sum(Bytes)/1024/1024/1024,2) Segments_Allocated_Space_GB 
    from     DBA_SEGMENTS 
    group by tablespace_name) a 
    on a.tablespace_name = b.tablespace_name 
    order by Segments_Allocated_Space_GB desc, free_gb desc, DataFile_Size_GB desc;



----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-- Free Size:
select 	/*+ parallel(dba_free_space,16) */ a.tablespace_name,
        round(sum(a.bytes)/1024/1024/1024) Free_Allocated_Space_TB
    from 	dba_free_space a 
    group by a.tablespace_name 
    order by 2 desc;

-- Used Size:
select  /*+ parallel(DBA_SEGMENTS,16) */ a.tablespace_name, 
        round(sum(a.Bytes)/1024/1024/1024) Used_Allocated_Space_TB 
    from     DBA_SEGMENTS a 
    group by a.tablespace_name 
    order by 2 desc;
    
-- Allocate Size:
select  /*+ parallel(dba_data_files,16) */ b.tablespace_name,
        round(sum(a.Bytes/1024/1024/1024)) Total_Allocated_Data_Size_GB
    from 	dba_data_files a, 
            dba_tablespaces b 
    where       a.tablespace_name=b.tablespace_name 
    group by    b.tablespace_name 
    order by 2 desc; 

------ Identify Disks in ASM:
select  group_number                            GROUP#, 
        name                                    NAME, 
        state                                   STATUS, 
        round(total_mb/1024)                    TOTAL_GB, 
        round((total_mb-usable_file_mb)/1024)   USED_GB, 
        round(usable_file_mb/1024)              USABLE_GB 
    from v$asm_diskgroup 
    order by group_number;

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-- Left join of (ToTal_Allocated_Space_size and Used_Allocated_Space_Size)
select  b.tablespace_name,
        b.Total_Allocated_Data_Size_GB, 
        a.Used_Allocated_Space_GB
    from 
    (select  /*+ parallel(dba_data_files,16) */ b.tablespace_name,
        round(sum(a.Bytes/1024/1024/1024)) Total_Allocated_Data_Size_GB
    from 	dba_data_files a, 
            dba_tablespaces b 
    where       a.tablespace_name=b.tablespace_name 
    group by    b.tablespace_name) b 
    LEFT OUTER JOIN 
    (select  /*+ parallel(DBA_SEGMENTS,16) */ tablespace_name, 
        round(sum(Bytes)/1024/1024/1024) Used_Allocated_Space_GB 
    from     DBA_SEGMENTS 
    group by tablespace_name) a 
    on a.tablespace_name = b.tablespace_name 
    order by Used_Allocated_Space_GB desc, Total_Allocated_Data_Size_GB desc;

------ Size of "Allocated", "Free Allocated", and "Unallocated" Extents in DataFiles used by each "Tablespace":
		select 	a.tablespace_name 			"Tablespace_Name", 
                c.status                    "Tablespace_Status",
				a.Free_Allocated_Space_GB 	"Free_Allocated_Space_GB",
				b.Allocated_Size_GB 		"Allocated_Size_GB",
				c.Unallocated_Size_GB 		"Unallocated_Size_GB"
			from 	(
					select 	tablespace_name,
							round(sum(bytes)/1024/1024/1024,2) 	Free_Allocated_Space_GB
						from 	dba_free_space
						group by tablespace_name
					) 	a, 
					(
					select 	tablespace_name,
							round(sum(bytes)/1024/1024/1024,2) 	Allocated_Size_GB
						from 	dba_data_files
						group by tablespace_name
					) 	b,
					(select a.tablespace_name 									tablespace_name,
                            a.status                                            status,
							round(sum((a.maxbytes-a.Bytes)/1024/1024/1024),2)	Unallocated_Size_GB
						from 	dba_data_files a,
								dba_tablespaces b
						where 	a.tablespace_name=b.tablespace_name 
						group by a.tablespace_name, a.status
					) 	c
			where 	a.tablespace_name=b.tablespace_name
				and a.tablespace_name=c.tablespace_name
			order by b.Allocated_Size_GB desc;


------ List of "Datafiles":
select 	b.tablespace_name 								"TableSpace", 
				a.autoextensible 								"Auto_Extention",
				b.bigfile 										"BigFile",
				a.file_name 									"File_Name",
				round(a.Bytes/1024/1024/1024,2) 				"Allocated_Size_GB",
				round(a.maxbytes/1024/1024/1024,2)				"Max_Size_GB",
				round((a.maxbytes-a.Bytes)/1024/1024/1024,2)	"Unallocated_Size_GB"
			from 	dba_data_files a,
					dba_tablespaces b 
			where 	a.tablespace_name=b.tablespace_name 
			order by b.tablespace_name, a.Bytes;


-- List of segments in a tablespace:
select a.segment_type, round(sum(a.bytes/1024/1024/1024),2) size_GB
    from    dba_segments a
    where   a.tablespace_name = 'SYSAUX'
    group by a.segment_type
    order by size_gb desc;

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-- List of Non-Compressed Tablespaces:
select a.tablespace_name, b.CREATION_TIME, NVL(regexp_replace(a.COMPRESS_FOR, '[^[:digit:]]', ''), '(NULL)') COMPRESS_FOR
    from 
    (select tablespace_name, 
            compress_for 
        from    dba_tablespaces 
        where   (compress_for is NULL or compress_for != 'OLTP') 
            and contents = 'PERMANENT' 
        order by compress_for) a,
    (select a.tablespace_name, 
            to_char(min(b.CREATION_TIME), 'YYYY-MM-DD HH24:MI:SS') "CREATION_TIME"
        from    dba_data_files a, 
                v$datafile b 
        where a.file_name = b.name 
        group by a.tablespace_name
        order by a.tablespace_name) b
    where a.tablespace_name = b.tablespace_name;

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
---- Get the current PGA consumption of a database instance:
select  round(sum(pga_max_mem)/1024/1024/1024)      "TOTAL MAX PGA (GB)",
        round(sum(pga_alloc_mem)/1024/1024/1024)    "Allocate PGA (GB)",
        round(sum(pga_used_mem)/1024/1024/1024)     "Used PGA (GB)",
        round(sum(pga_freeable_mem)/1024/1024/1024) "Free PGA (GB)" 
    from v$process;

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-- List size of All Tables:
select b.owner, b.table_name "Table_name", b.partitioned, round(sum(a.Bytes/1024/1024/1024)) Table_Size_GB
    from DBA_SEGMENTS a, 
         dba_tables b
    where   A.OWNER=B.OWNER
        AND a.segment_name = b.table_name 
    group by b.table_name, b.owner, b.tablespace_name, b.partitioned 
    order by Table_Size_GB desc;


-- "Number of Columns" in a Table:
select owner, table_name, count(*) num_of_cols
    from dba_tab_columns
    where   owner = 'INVENTIVE'
        AND table_name IN ('TBL_PGW')
    group by owner, table_name;


-- List "Sizes" of Specified "Tables":
select a.owner, a.table_name, round(sum(b.bytes/1024/1024/1024),2) Size_GB 
    from    dba_tables a,
            dba_segments b
    where   a.owner=b.owner
        AND a.table_name=b.segment_name 
        AND (a.owner='STAR_USER' OR a.owner='ETL_USER')
        AND a.table_name IN ('TRMNTN_PROFILE_TABLE_1399_06_24',
                             'TRMNTN_DETECTION_TABLE_1399_06_24')
    group by a.owner, a.table_name
    order by a.owner, a.table_name;


-- List Sizes of "Partitions" of specified Tables:
select  a.table_owner, a.table_name, a.partition_name, 
        mosch.partition_hv_to_date(a.table_owner, a.table_name, a.partition_name) high_value, 
        round(sum(b.bytes/1024/1024/1024),4) Size_GB 
    from    dba_tab_partitions a,
            dba_segments b
    where   a.table_owner=b.owner
        AND a.table_name=b.segment_name 
        AND a.partition_name=b.partition_name
        AND (a.table_owner='STAR_USER' OR a.table_owner='ETL_USER' OR a.table_owner='STAR_ETL')
        AND a.table_name IN ('STAR_REF_CBS_REC')
    group by a.table_owner, a.table_name, a.partition_name
    order by a.table_owner, a.table_name, high_value desc;


-- Average size of "Partitions" of specified Tables:
select  a.table_owner, a.table_name, b.segment_type,
        ROUND(AVG(b.bytes/1024/1024/1024),2) Size_GB 
    from    dba_tab_partitions a,
            dba_segments b
    where   a.table_owner=b.owner
        AND a.table_name=b.segment_name 
        AND a.partition_name=b.partition_name
        AND (a.table_owner='STAR_USER' OR a.table_owner='ETL_USER' )
        AND a.table_name IN 
(
'REF_MSC',
'REF_CBS_REC'          
)
    group by a.table_owner, a.table_name, b.segment_type
    order by a.table_owner, a.table_name;


-- List of All Non-partitioned Tables "Creation Time":
SELECT  a.owner         table_owner, 
        a.table_NAME    table_name, 
        b.OBJECT_TYPE, 
        b.created created
        FROM    dba_tables a,
                dba_objects b
        where   a.owner=b.owner 
            and a.table_NAME=b.OBJECT_NAME
            and a.TABLE_NAME like 'ETL_%'
            and b.OBJECT_TYPE = 'TABLE'
        order by created desc;


-- List of All Table Partitions "Creation Time":
SELECT  a.table_owner                                                       table_owner, 
        a.table_NAME                                                        table_name, 
        a.PARTITION_NAME                                                    Partition_name, 
        mosch.partition_hv_to_date(a.table_owner, a.table_NAME, a.PARTITION_NAME) high_value_date,
        b.OBJECT_TYPE, 
        b.created,
        c.partitioning_type  
        FROM    dba_tab_partitions a,
                dba_objects b,
                dba_part_tables c
        where   a.table_owner=b.owner 
            and a.table_NAME=b.OBJECT_NAME
            and a.PARTITION_NAME=b.SUBOBJECT_NAME
            and a.table_owner=c.OWNER
            and a.table_name=c.TABLE_NAME
            and a.TABLE_NAME like 'REF%'
            and c.partitioning_type = 'RANGE'
            --and partition_hv_to_date(a.table_owner, a.table_NAME, a.PARTITION_NAME) > sysdate - 1
            --and partition_hv_to_date(a.table_owner, a.table_NAME, a.PARTITION_NAME) < sysdate
            and b.OBJECT_TYPE = 'TABLE PARTITION'
        order by 2, 4 desc;



-- List "Sizes" of "Indexes":
select a.owner, a.table_name, a.index_name, sum(bytes/1024/1024/1024) bytes_gb 
    from dba_indexes a, dba_segments b
    where   a.owner=b.owner 
        and a.index_name=b.segment_name 
        --and a.owner='STAR_ETL'
        --and a.table_name='REF_CBS_DATA'
        and (a.owner='STAR_USER' OR a.owner='ETL_USER' OR a.owner='STAR_ETL')
        AND a.table_name IN 
(
'REF_CBS_LOAN'        ,
'REF_CBS_CLR'         ,
'REF_AR_PAYMENT'      ,
'REF_AR_ADJUSTMENT'   ,
'TBL_HSS'             ,
'REF_L2_CG_PGW'       ,
'REF_CBS_DATA'        ,
'REF_CBS_REJECT_DATA' ,
'REF_CBS_REJECT_MON'  ,
'REF_CBS_REJECT_MGR'  ,
'REF_CBS_MON'         ,
'REF_CBS_MGR'         
)
    group by a.owner, a.table_name, a.index_name;


-- List of Partitioned "Indexes":
select * from dba_indexes where table_name='REF_CBS_DATA';
select * from dba_part_indexes where table_name='REF_CBS_DATA';

-- List of "Partitions" of an Index:
select a.owner, a.table_name, a.index_name, c.partition_name index_partition_name, c.status, b.object_type, c.tablespace_name,
    MOSCH.index_partition_hv_to_date(a.owner, a.index_name, c.partition_name) HIGH_VALUE, 
    b.created CREATED 
    from dba_indexes a, dba_objects b, dba_ind_partitions c
    where   a.owner=b.owner 
		and a.owner=c.index_owner
        and a.index_name=b.object_name 
		and a.index_name=c.index_name 
		and b.subobject_name=c.partition_name 
        --and a.owner='ETL_USER' 
        --and a.table_name='REF_CBS_REC' 
        --and a.index_name='PRI_IDENTI_CBS'
        --and a.owner='ETL_USER' 
        --and a.table_name='REF_CBS_SMS' 
        --and a.index_name='PRI_IDENTI_SMS'
        and a.owner='STAR_ETL' 
        and a.table_name='REF_CBS_DATA' 
        and a.index_name='CBS_DATA_NUMBER'
order by 1,2,3, HIGH_VALUE desc;


-- List Sizes of "Partitions" of specified Indexes:
select a.owner, a.table_name, a.index_name, c.partition_name index_partition_name, c.status, b.object_type, c.tablespace_name,
    MOSCH.index_partition_hv_to_date(a.owner, a.index_name, c.partition_name) HIGH_VALUE, 
    round(sum(d.bytes/1024/1024/1024),4) Size_GB,
    b.created CREATED 
    from dba_indexes a, dba_objects b, dba_ind_partitions c, dba_segments d
    where   a.owner=b.owner 
		and a.owner=c.index_owner
        and a.index_name=b.object_name 
		and a.index_name=c.index_name 
		and b.subobject_name=c.partition_name 
        AND c.index_name=d.segment_name 
        AND c.partition_name=d.partition_name
        and a.owner='STAR_ETL' 
        --and a.table_name='REF_CBS_REC' 
        and a.table_name='REF_CBS_DATA' 
        --and a.index_name='PRI_IDENTI_CBS'
    group by a.owner, a.table_name, a.index_name, c.partition_name, c.status, b.object_type, c.tablespace_name, b.created
    order by a.owner, a.table_name, high_value desc;

-- List of "All Index Partitions" of a Table for a "Specific Date":
select '''ALTER INDEX ' || a.owner || '.' || a.index_name || ' MODIFY PARTITION ' || c.partition_name || ' UNUSABLE'';', INVENTIVE.index_partition_hv_to_date(a.owner, a.index_name, c.partition_name) HIGH_VALUE, c.status, b.created CREATED  
--select a.owner, a.table_name, a.index_name, c.partition_name index_partition_name, c.status, b.object_type, c.tablespace_name,
--    INVENTIVE.index_partition_hv_to_date(a.owner, a.index_name, c.partition_name) HIGH_VALUE, 
--    b.created CREATED 
    from dba_indexes a, dba_objects b, dba_ind_partitions c
    where   a.owner=b.owner 
		and a.owner=c.index_owner
        and a.index_name=b.object_name 
		and a.index_name=c.index_name 
		and b.subobject_name=c.partition_name 
        and a.owner='INVENTIVE' 
        and a.table_name like 'TBL_%' 
        --and c.status = 'USABLE'
        and INVENTIVE.index_partition_hv_to_date(a.owner, a.index_name, c.partition_name) = to_date('2021-08-16 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
        --and a.index_name='CBS_DATA_NUMBER'
order by 1,2, HIGH_VALUE desc;


-- Average size of "Partitions" of specified Indexes:
select a.owner, a.table_name, a.index_name, 
    b.object_type, c.tablespace_name,
    round(avg(d.bytes/1024/1024/1024),2) Size_GB
    from dba_indexes a, dba_objects b, dba_ind_partitions c, dba_segments d
    where   a.owner=b.owner 
		and a.owner=c.index_owner
        and a.index_name=b.object_name 
		and a.index_name=c.index_name 
		and b.subobject_name=c.partition_name 
        AND c.index_name=d.segment_name 
        AND c.partition_name=d.partition_name
        and (a.table_owner='STAR_USER' OR a.table_owner='ETL_USER' OR a.table_owner='STAR_ETL')
--        AND a.table_name IN 
--(
--'REF_CBS_LOAN',
--'REF_CBS_CLR'
--)
    group by a.owner, a.table_name, a.index_name, b.object_type, c.tablespace_name
    order by a.owner, a.table_name, a.index_name;



-- List of Indexed "Columns" of a table:
select table_owner, index_owner, table_name, index_name, 
    listagg(column_name|| ',') within Group (order by column_name) index_columns
    from DBA_IND_COLUMNS 
    where   table_owner = 'STAR_ETL'
        and table_name = 'REF_CBS_DATA'
    group by table_owner, table_name, index_owner, index_name;



----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-- List of "Invalid Indexes" on "Non-Partitioned Tables":
select a.owner, a.table_name, a.index_name, a.partitioned, a.status, b.object_type, 
    b.created CREATED 
    from dba_indexes a, dba_objects b
    where   a.owner=b.owner 
        and a.index_name=b.object_name 
        and (a.owner='STAR_ETL' OR a.owner = 'ETL_USER' OR a.owner = 'STAR_USER')
        --and a.table_name='REF_CBS_DATA' 
        --and a.index_name='CBS_DATA_NUMBER'
        --and a.index_name='REF_CBS_DATA_REC'
        and a.partitioned = 'NO'
        and a.status != 'VALID'
order by 1,2,3;


-- List of "Unusable Index Partitions" on "Partitioned Tables":
select a.owner, a.index_name, c.partition_name index_partition_name, a.table_name, b.object_type, c.status, 
    MOSCH.index_partition_hv_to_date(a.owner, a.index_name, c.partition_name) HIGH_VALUE, 
    b.created CREATED 
    from dba_indexes a, dba_objects b, dba_ind_partitions c
    where   a.owner=b.owner 
		and a.owner=c.index_owner
        and a.index_name=b.object_name 
		and a.index_name=c.index_name 
		and b.subobject_name=c.partition_name 
        and (a.owner='STAR_ETL' OR a.owner = 'ETL_USER' OR a.owner = 'STAR_USER')
        --and a.table_name='REF_CBS_DATA' 
        --and a.index_name='CBS_DATA_NUMBER'
        and a.index_name='PRI_IDENTI_CBS'
        --and a.index_name='PRI_IDENTI_SMS'
        and a.partitioned = 'YES'
        and c.status = 'UNUSABLE'
order by 1,2, HIGH_VALUE desc;


----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-- Identify Huge non-partitioned Tables:
select b.owner, b.table_name "Table_name", b.tablespace_name "TableSpace", b.partitioned, round(sum(a.Bytes/1024/1024/1024)) Table_Size_GB
    from DBA_SEGMENTS a, 
         dba_tables b
    where   A.OWNER=B.OWNER
        AND a.segment_name = b.table_name 
        and b.partitioned = 'NO' 
    group by b.table_name, b.owner, b.tablespace_name, b.partitioned 
    having sum(a.Bytes/1024/1024/1024) > 100
    order by Table_Size_GB desc;
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-- List of TEMPORARY Tablespaces:
select  tablespace_name
    from    dba_tablespaces
    where   contents = 'TEMPORARY';


-- List of TempFiles:
select CREATION_TIME, round(bytes/1024/1024/1024,2) size_gb, NAME from v$tempfile;


-- Total/Allocated/Free Space in TEMPORARY Tablespaces:
select  a.tablespace_name, 
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



------ List of "TempFiles":
select 		c.CREATION_TIME 								"CREATION_TIME",
			b.tablespace_name 								"TableSpace", 
			a.autoextensible 								"Auto_Extention",
			b.bigfile 										"BigFile",
			a.file_name 									"File_Name",
			round(a.Bytes/1024/1024/1024,2) 				"Allocated_Size_GB",
			round(a.maxbytes/1024/1024/1024,2)				"Max_Size_GB",
			round((a.maxbytes-a.Bytes)/1024/1024/1024,2)	"Unallocated_Size_GB"
	from 	dba_temp_files a,
			dba_tablespaces b,
			v$tempfile c
	where 	a.tablespace_name=b.tablespace_name  
		AND a.file_name=c.name 
	order by b.tablespace_name, a.Bytes;



-- Determine Size of "TEMP space" used by "Sessions":
select  TU.username, S.SID, S.SERIAL#, S.STATUS, S.SADDR, S.SQL_ID Current_SQL_ID, TU.sql_id_tempseg TEMPSEG_SQL_ID, TU.contents, 
        ROUND(SUM(TU.BLOCKS)*TS.BLOCK_SIZE/1024/1024/1024,4) TEMP_USED_GB 
    from    V$TEMPSEG_USAGE TU, 
            DBA_TABLESPACES TS,
            V$SESSION S
    WHERE   S.serial#=TU.session_num
        and S.SADDR=TU.SESSION_ADDR
        and TU.TABLESPACE=TS.TABLESPACE_NAME
        and TS.CONTENTS='TEMPORARY'
    GROUP BY TU.username, S.SID, S.SERIAL#, S.STATUS, S.SADDR, S.SQL_ID, TU.sql_id, TU.sql_id_tempseg, TU.contents, TS.BLOCK_SIZE
    order by TEMP_USED_GB desc;

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-- Determine Size of "UNDO space" used by "Sessions":
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



----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
