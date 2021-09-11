# Create Drop Index

-----------------------------------------------------------------------------------------------------
- Create a "Local Partitioned" "Unusable" Index:
	> (From 11gR2, database does NOT create an index segment when creating an "unusable" index.)

```
SQL> CREATE INDEX ETL_USER.MSISDN_RECDATE_IND ON ETL_USER.REF_MSC (MSISDN,RECORD_DATE) 
		TABLESPACE TBS_MSC_INDX 
		LOCAL 
		UNUSABLE
		PARALLEL 
		NOLOGGING 
		PCTFREE 10 
		INITRANS 2 
		MAXTRANS 255 
		STORAGE (	INITIAL 64K 
					NEXT 1M 
					MINEXTENTS 1 
					MAXEXTENTS UNLIMITED 
					PCTINCREASE 0 
					BUFFER_POOL DEFAULT
				);
```

-----------------------------------------------------------------------------------------------------
- Change "default Tablespace" for an Index:
```
SQL> ALTER TABLE OWNER.TBL_NAME MODIFY DEFAULT ATTRIBUTES TABLESPACE NEW_TBS;
```

-----------------------------------------------------------------------------------------------------
- "Rebuild" an Index Partition:
```
SQL> ALTER INDEX OWNER.IDX_NAME	REBUILD PARTITION index_partition_name ONLINE PARALLEL 40;
```

-----------------------------------------------------------------------------------------------------
- Make an Index Partition "Unusable":
```
SQL> ALTER INDEX OWNER.IDX_NAME MODIFY PARTITION index_partition_name UNUSABLE;
```

-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
- **Drop an Index**:
```
SQL> DROP INDEX OWNER.IDX_NAME;
```

-----------------------------------------------------------------------------------------------------
- **DROP a Unique Index**:

0.
```
SQL> CREATE UNIQUE INDEX MOSCH.DUPLICATE_CHECKSUM_UNIQUE_CONS ON MOSCH.TEST1 (DUPLICATE_CHECKSUM);
```
1. 
```
SQL> DROP INDEX MOSCH.DUPLICATE_CHECKSUM_UNIQUE_CONS;
--Error!!!!
```

2. 
```
SQL> ALTER table MOSCH.TEST1 drop constraint DUPLICATE_CHECKSUM_UNIQUE_CONS;
```
3. 
```
SQL> DROP INDEX MOSCH.DUPLICATE_CHECKSUM_UNIQUE_CONS;
```
4. 
```
SQL> ALTER TABLE MOSCH.TEST1 ADD CONSTRAINT DUPLICATE_CHECKSUM_UNIQUE_CONS UNIQUE (DUPLICATE_CHECKSUM) ENABLE NOVALIDATE;
```
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
