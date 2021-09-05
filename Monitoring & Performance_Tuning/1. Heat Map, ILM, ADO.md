# Heat Map, ILM, ADO

[oracle-base.com](https://oracle-base.com/articles/12c/heat-map-ilm-ado-12cr2)


- Heat Map, Information Lifecycle Management (ILM) and Automatic Data Optimization (ADO):

================================================================================
--------------------------------------------------------------------------------
================================================================================
- Heat Map:
```
SQL> select a.name, a.value from v$parameter a where name='heat_map';
--SQL> ALTER SYSTEM SET heat_map = ON;

SQL> select a.* FROM v$heat_map_segment a;

SQL> select a.* FROM dba_heat_map_seg_histogram a;

SQL> SELECT a.* FROM TABLE(DBMS_HEAT_MAP.object_heat_map('OWNER','TABLE_NAME')) a;

```
================================================================================
--------------------------------------------------------------------------------
================================================================================
- Automatic Data Optimization (ADO), Information Lifecycle Management (ILM):


- List of ILM ADO Parameters:
```
SQL> SELECT a.* FROM dba_ilmparameters a;
--BEGIN DBMS_ILM_ADMIN.CUSTOMIZE_ILM(DBMS_ILM_ADMIN.retention_time, 60); END;

```
- List of ILM Policies:
```
SQL> SELECT a.* FROM DBA_ILMPOLICIES a;

```
- List of ILM Objects:   
```
SQL> SELECT a.* FROM DBA_ilmobjects a;

```
- Views for displaying policy details:
```
SQL> DBA_ILMDATAMOVEMENTPOLICIES
SQL> DBA_ILMTASKS
SQL> DBA_ILMEVALUATIONDETAILS
SQL> DBA_ILMOBJECTS
SQL> DBA_ILMPOLICIES
SQL> DBA_ILMRESULTS
SQL> DBA_ILMPARAMETERS
```
================================================================================
--------------------------------------------------------------------------------
================================================================================
- ILM Policies : 	
1. Compress Policy		: 
2. Storage Tier Policy	: 



- Add "Compress Policy" for "Table":
```
SQL> ALTER TABLE invoices ILM ADD POLICY ROW STORE COMPRESS BASIC SEGMENT AFTER 3 MONTHS OF NO ACCESS;
```
- Add "Storage Tier Policy" fro "Partition":
```
SQL> ALTER TABLE invoices MODIFY PARTITION invoices_2017_q2 ILM ADD POLICY TIER TO medium_storage_ts READ ONLY SEGMENT AFTER 3 MONTHS OF NO ACCESS;
```


- Table-level:
```
SQL> ALTER TABLE TABLE_NAME ILM DISABLE POLICY <POLICY_NAME>;
SQL> ALTER TABLE TABLE_NAME ILM DELETE POLICY  <POLICY_NAME>;
SQL> ALTER TABLE TABLE_NAME ILM DISABLE_ALL;
SQL> ALTER TABLE TABLE_NAME ILM DELETE_ALL;
```
- Partition-level:
```
SQL> ALTER TABLE TABLE_NAME MODIFY PARTITION PARTITION_NAME ILM DISABLE POLICY <POLICY_NAME>;
SQL> ALTER TABLE TABLE_NAME MODIFY PARTITION PARTITION_NAME ILM DELETE POLICY  <POLICY_NAME>;
SQL> ALTER TABLE TABLE_NAME MODIFY PARTITION PARTITION_NAME ILM DISABLE_all;
SQL> ALTER TABLE TABLE_NAME MODIFY PARTITION PARTITION_NAME ILM DELETE_ALL;



SQL> BEGIN DBMS_ILM_ADMIN.CUSTOMIZE_ILM(DBMS_ILM_ADMIN.retention_time, 60); END;
```
================================================================================
--------------------------------------------------------------------------------
================================================================================
