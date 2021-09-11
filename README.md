# Oracle Database

------------------------------------------------
In this repository, several configurations for the **Oracle database** are provided. 
These configuration settings are categorized into 17 different realms as follows:

1. **Installation**
    > 1- Install Oracle Database **12cR2** with **ASM** on **Oracle linux 7.4** (with 2 OS users: oracle & grid) \
    > 2- Install Oracle Database **19c3** with **ASM** on **RHEL 7.6** (with 2 OS users: oracle & grid)


2. **User Management**
    > 1- Identify Users of a Database + Create New Users


3. **File & Tablespace Management**
    > 1- Identify Tablespaces + Create/Drop TBSs + Add New File (**TEMPORARY**/**UNDO**/**PERMANENT** TBSs )


4. **Monitoring & Performance Tuning**
    >   1- Automatic Workload Repository (AWR) and Active Session History (ASH) Report \
    >   2- Heat Map, Information Lifecycle Management (ILM) and Automatic Data Optimization (ADO) \
    >   3- Auditing


5. **Archive Log Management**
    > A list of parameters is presented that can be used to configure Archive Logs.


6. **Backup Recovery**
    >   1- Three Backup Recovery Scenarios \
    >   2- Recovery Catalog Management \
    >   3- Backup/Recovery for "Data Guard" 

7. **Scheduled Job**
    >   1- Alarm_Locks (OS Scheduled Job): setting an OS Alarm for "Locking Sessions" to be reported \
    >   2- Alarm_Long_Running (OS Scheduled Job): setting an OS Alarm for "Long Running SQLs" to be reported 

    >   3- Copy_Table_Stale_Stats (DB Scheduled Job): copying the statistics of new partitions to partitions with stale statistics \
    >   4- Gather_Table_Stale_Stats (DB Scheduled Job): gathering statistics of partitions with stale statistics \
    >   5- Long_Running_Sessions (DB Scheduled Job): reporting "Long Running SQLs" \
    >   6- Active_Sessions_TEMP_Usage (DB Scheduled Job): reporting how much "TEMP space" is used by each session \
    >   7- Disk_Usage (DB Scheduled Job): reporting how much DISK is used over time \
    >   8- InMemory_Space (DB Scheduled Job): reporting how much MEMORY is used for storing columnar data (in-memory) over time \
    >   9- Tablespace_Space (DB Scheduled Job): reporting how much free space is available in each tablespace over time \
    >   10- Rebuild_Indexes (DB Scheduled Job): rebuilding unusable index partitions \
    >   11- Convert_HighValue_to_Date (DB Scheduled Job): two oracle functions which convert the high_value of a table/index partition to date value


8. **PL_SQL**


9. **Export-Import**


10. **Partitioning**


11. **Indexing**


12. **Trigger**


13. **Materialized View**


14. **Container Database**


15. **Oracle Sharding**


16. **Oracle GoldenGate**



------------------------------------------------
