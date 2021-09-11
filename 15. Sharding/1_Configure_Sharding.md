# Configure Sharding
[db.geeksinsight.com](http://db.geeksinsight.com/2017/02/20/oracle-sharding-part-2-installating-configuring-shards/) \
[access.redhat.com](https://access.redhat.com/documentation/en-us/reference_architectures/2017/html-single/deploying_oracle_database_12c_release_2_on_red_hat_enterprise_linux_7/index) \
[www.uxora.com](https://www.uxora.com/oracle/dba/41-install-oracle-grid-infrastructure-12cr2-for-rac) \
[www.uxora.com](https://www.uxora.com/oracle/dba/47-install-oracle-grid-infrastructure-12cr2-standalone) \
[www.oracle-wiki.net](http://www.oracle-wiki.net/startdocshowtoinstalloracle12clinuxasm#Known-Issues) 
-------------------------------------------------------------------------------------

- Oracle Linux 7.4 (Kernel Version: 4.1.12-94.3.9.el7uek.x86_64)
- Oracle Database 12c Release 2 Grid Infrastructure for Linux x86-64 (Version: 12.2.0.1.0) [linuxx64_12201_grid_home.zip]
- Oracle Database 12c Release 2 for Linux x86-64 (Version: 12.2.0.1.0) [linuxx64_12201_database.zip]
-------------------------------------------------------------------------------------
- GSM:
    Oracle base:		/u01/app/oracle \
    Software Location:	/u01/app/oracle/product/12.2.0/gsmhome_1 

- Grid:
    Oracle base: 		/u01/app/12.2.0 \
    Software location:	/u01/app/12.2.0/grid 

- Database:
    Oracle base:		/u01/app/oracle \
    Software Location:	/u01/app/oracle/product/12.2.0/dbhome_1

====================================================
- Shard Catalog:
```
SQL> show parameter name
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
_cloud_name                          string      oradbcloud
_dbpool_name                         string      sdb
_region_name                         string      region1
_shardgroup_name                     string      primary_shardgroup
_shardspace_name                     string      shardspaceora
cdb_cluster_name                     string      sh1
cell_offloadgroup_name               string
db_file_name_convert                 string      *, /u01/app/oracle/oradata/SH1/datafile/
db_name                              string      sh1
db_unique_name                       string      sh1
global_names                         boolean     FALSE
instance_name                        string      sh1
lock_name_space                      string
log_file_name_convert                string
pdb_file_name_convert                string
processor_group_name                 string
service_names                        string      sh1
```
==========================================
- Shard 1:
```
SQL> show parameter name
NAME                    TYPE     VALUE
----------------------- ------   ------------------------------
_cloud_name             string   oradbcloud
_dbpool_name            string   sdb
_region_name            string   region1
_shardgroup_name        string   primary_shardgroup
_shardspace_name        string   shardspaceora
cdb_cluster_name        string   sh1
cell_offloadgroup_name  string  
db_file_name_convert    string   *, /u01/app/oracle/oradata/SH1/datafile/
db_name                 string   sh1
db_unique_name          string   sh1
global_names            boolean  FALSE
instance_name           string   sh1
lock_name_space         string  
log_file_name_convert   string  
pdb_file_name_convert   string  
processor_group_name    string  
service_names           string   sh1
```
==========================================
- Shard 2:
```
SQL> show parameter name
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
_cloud_name                          string      oradbcloud
_dbpool_name                         string      sdb
_region_name                         string      region1
_shardgroup_name                     string      primary_shardgroup
_shardspace_name                     string      shardspaceora
cdb_cluster_name                     string      sh2
cell_offloadgroup_name               string
db_file_name_convert                 string      *, /u01/app/oracle/oradata/SH2/datafile/
db_name                              string      sh2
db_unique_name                       string      sh2
global_names                         boolean     FALSE
instance_name                        string      sh2
lock_name_space                      string
log_file_name_convert                string
pdb_file_name_convert                string
processor_group_name                 string
service_names                        string      sh2
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Step 1. Install Oracle Software Only 12cR2.
-- (On shardcat) & (On Shard1) & (On shard2):

1. Install grid infrastructure. (user "oracle" -> DO NOT add user "grid")


2. Install oracle database software-only. (user "oracle")

====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Step 2. Install Pluggable database.
-- (On shardcat):

===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 3. Install GSM Software at Separate Home.
-- (On shardcat):

1. Login as "root":
```
[root@shardcat ~]$ mkdir -p /tmp
[root@shardcat ~]$ chmod 1777 /tmp

[root@shardcat ~]$ mkdir -p /u01/app/software/GSM
[root@shardcat ~]$ chown -R oracle:oinstall /u01/app/software/GSM

[root@shardcat ~]$ cd /u01/app/software/GSM
[root@shardcat GSM]$ unzip -q /root/linuxx64_12_2_0_1_gsm.zip
[root@shardcat GSM]# chown -R oracle:oinstall /u01/app/software/GSM
```
-----------------------------------------
2. Login as "oracle".
```
[oracle@shardcat ~]$ vi .bash_profile
	alias gsm_env='. /home/oracle/gsm_env.sh'

[oracle@shardcat ~]$ . ./.bash_profile


[oracle@shardcat ~]$ vi gsm_env.sh
export ORACLE_SID=shardcat 
export ORACLE_BASE=/u01/app/oracle 
export ORACLE_HOME=$ORACLE_BASE/product/12.2.0/gsmhome_1 
export LD_LIBRARY_PATH=$ORACLE_HOME/lib 
export PATH=$BASE_PATH:$ORACLE_HOME/bin


[oracle@shardcat ~]$ gsm_env
[oracle@shardcat ~]$ echo $ORACLE_HOME
/u01/app/oracle/product/12.2.0.1/gsmhome_1


```
3. Install GSM at a home directory separate from "database home directory".
```
[oracle@shardcat ~]$ gsm_env
[oracle@shardcat ~]$ echo $ORACLE_HOME
/u01/app/oracle/product/12.2.0.1/gsmhome_1

[oracle@shardcat ~]$ mkdir -p /u01/app/oracle/product/12.2.0/gsmhome_1
[oracle@shardcat ~]$ chown -R oracle:oinstall /u01/app/oracle/product/12.2.0/gsmhome_1
[oracle@shardcat ~]$ chmod -R 775 /u01/app/oracle/product/12.2.0/gsmhome_1

[oracle@shardcat ~]$ /u01/app/software/GSM/gsm/runInstaller
```
- Select the location of "ORACLE_BASE" and the "GSM_HOME" locations:
```
[Wizard: Specify Installation Location]:
	Oracle base: 		/u01/app/oracle
	Software location: 	/u01/app/oracle/product/12.2.0/gsmhome_1
```
4. Login as "root":
```
[root@shardcat ~]# /u01/app/oracle/product/12.2.0/gsmhome_1/root.sh
press "Enter"

```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 4. Create Environment Setup.
 

1. (On shardcat) & (On Shard1) & (On shard2):
```
[root@shardcat ~]$ vi /etc/hosts
192.168.96.146      shard1     shard1.mosch.co
192.168.96.147      shard2     shard2.mosch.co
192.168.96.144      shardcat   shardcat.mosch.co

```
2. (On shardcat) & (On Shard1) & (On shard2):
```
[oracle@shardcat ~]$ mkdir -p /u01/app/oracle/admin/sdb/adump
[oracle@shardcat ~]$ mkdir -p /u01/app/oracle/fast_recovery_area
[oracle@shardcat ~]$ mkdir -p /u01/app/oracle/oradata/sdb/

```
3. (On shardcat):
```
[oracle@shardcat ~]$ vi /u01/app/oracle/product/12.2.0/gsmhome_1/network/admin/tnsnames.ora
DBSCAT =
  (DESCRIPTION =
	(ADDRESS = (PROTOCOL = TCP)(HOST = shardcat.mosch.co)(PORT = 1521))
	(CONNECT_DATA =
		(SID = shardcat)
	)
  )

/*
[oracle@shardcat ~]$ cd $HOME

[oracle@shardcat ~]$ vi shardcat.sh
export ORACLE_SID=shardcat 
export ORACLE_BASE=/u01/app/oracle 
export ORACLE_HOME=/u01/app/oracle/product/12.2.0/dbhome_1 
export LD_LIBRARY_PATH=$ORACLE_HOME/lib 
export PATH=$SAVEPATH:$ORACLE_HOME/bin

[oracle@shardcat ~]$ vi shard-director1.sh
export ORACLE_BASE=/u01/app/oracle 
export ORACLE_HOME=/u01/app/oracle/product/12.2.0/GSM 
export LD_LIBRARY_PATH=$ORACLE_HOME/lib 
export PATH=$SAVEPATH:$ORACLE_HOME/bin
*/
```
4. (On shard1):
/*
```
--[oracle@shard1 ~]$ vi shard1.sh
[oracle@shard1 ~]$ vi .bash_profile
export ORACLE_SID=sh1 
#export ORACLE_BASE=/u01/app/oracle 
#export ORACLE_HOME=/u01/app/oracle/product/12.2.0/dbhome_1 
#export LD_LIBRARY_PATH=$ORACLE_HOME/lib 
#export PATH=$SAVEPATH:$ORACLE_HOME/bin

[oracle@shard1 ~]$ . ./.bash_profile
*/

```
5. (On shard2):
/*
```
--[oracle@shard2 ~]$ vi shard1.sh
[oracle@shard2 ~]$ vi .bash_profile
export ORACLE_SID=sh2 
#export ORACLE_BASE=/u01/app/oracle 
#export ORACLE_HOME=/u01/app/oracle/product/12.2.0/dbhome_1 
#export LD_LIBRARY_PATH=$ORACLE_HOME/lib 
#export PATH=$SAVEPATH:$ORACLE_HOME/bin

[oracle@shard2 ~]$ . ./.bash_profile
*/
```

===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 5. Prepare SCAT database for Sharding - Prerequisities.
-- (On shardcat):

1. Login as "oracle":
```
[oracle@shardcat ~]$ db_env
[oracle@shardcat ~]$ sqlp
SQL> show parameter name
NAME             TYPE        VALUE
---------------- ----------- --------
cdb_cluster_name string      sdb
db_name          string      sdb
db_unique_name   string      sdb
global_names     boolean     FALSE
instance_name    string      shardcat
service_names    string      sdb     
```
2. 
```
SQL> alter system set db_create_file_dest='/u01/app/oracle/oradata' scope=both;
SQL> alter system set open_links=16 scope=spfile;
SQL> alter system set open_links_per_instance=16 scope=spfile;
SQL> startup force
SQL> alter user gsmcatuser account unlock;
SQL> alter user gsmcatuser identified by SYS123sys;
SQL> CREATE USER mygdsadmin IDENTIFIED BY SYS123sys;
SQL> GRANT connect, create session, gsmadmin_role to mygdsadmin;
SQL> grant inherit privileges on user SYS to GSMADMIN_INTERNAL; 
SQL> execute dbms_xdb.sethttpport(8080);
SQL> commit;
```
3. 
```
SQL> @?/rdbms/admin/prvtrsch.plb
SQL> exec DBMS_SCHEDULER.SET_AGENT_REGISTRATION_PASS('oracleagent');
```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 6. Create Shard Catalog in SCAT.
-- (On shardcat):

1. 
```
[oracle@shardcat ~]$ gsm_env
[oracle@shardcat ~]$ gdsctl
Warning: current GSM name is not set automatically because gsm.ora contains zero or several GSM entries. 
Use "set  gsm" command to set GSM for the session.
Current GSM is set to GSMORA
```
2. 
/*
```
create shardcatalog -database connect_identifier 
                   [-user username[/password]] 
                   [-region region_name_list] 
                   [-configname config_name] 
                   [-autovncr {ON | OFF}] 
                   [-force] 
                   [-sdb sdb_name] 
                   [-shardspace shardspace_name_list] 
                   [-agent_password password] 
                   [-repl DG] 
                   [-repfactor number] 
                   [-sharding {system | composite}] 
                   [-chunks number] 
                   [-protectmode dg_protection_mode]
                   [-agent_port port]
*/
--GDSCTL> delete catalog [-connect [user/[password]@] conn_str] [-force]
--GDSCTL> delete catalog -connect mygdsadmin/SYS123sys@DBSCAT;
--GDSCTL> delete catalog;
GDSCTL> create shardcatalog -database DBSCAT -chunks 12 -user mygdsadmin/SYS123sys -sdb sdb -region region1;
Catalog is created

```
3. 
/*
```
add gsm -gsm gsm_name
        -catalog connect_id
       [-pwd password]
       [-wpwd password]
       [-region region_name]
       [-localons ons_port]
       [-remoteons ons_port]
       [-listener listener_port]
       [-endpoint gmsendpoint]
       [-remote_endpoint remote_endpoint]
       [-trace_level level]
*/
--GDSCTL> Remove gsm -gsm sharddirector1;
GDSCTL> add gsm -gsm sharddirector1 -listener 1571 -pwd SYS123sys -catalog DBSCAT -region region1;
GSM successfully added

```
4. 
```
--GDSCTL> stop gsm -gsm sharddirector1;
GDSCTL> start gsm -gsm sharddirector1;
GSM is started successfully

```
5. 
```
-- Special Characters are ALLOWED in password.
--GDSCTL> remove credential -credential oracle_cred 
GDSCTL> add credential -credential oracle_cred -osaccount oracle -ospassword *********
The operation completed successfully
```

6. 
```
GDSCTL> exit
```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 7. Start the "Scheduler Agent" & Register "Shard Nodes":
-- (On Shard1) & (On shard2):

1. 
```
--[oracle@shard1 ~]$ schagent -stop
[oracle@shard1 ~]$ schagent -start
Scheduler agent started using port 15200
```
2. 
```
[oracle@shard1 ~]$ schagent -status
Agent running with PID 26637
Agent_version:12.2.0.1.2
Running_time:00:00:12
Total_jobs_run:0
Running_jobs:0
Platform:Linux
ORACLE_HOME:/u01/app/oracle/product/12.2.0/dbhome_1
ORACLE_BASE:/u01/app/oracle
Port:15200
Host:shard1
```
3. 
```
--[oracle@shard1 ~]$ schagent -unregisterdatabase shardcat.mosch.co 8080
--password = oracleagent
[oracle@shard1 ~]$ echo oracleagent | schagent -registerdatabase shardcat.mosch.co 8080
Agent Registration Password ?
Oracle Scheduler Agent Registration for 12.2.0.1.2 Agent
Agent Registration Successful!
```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 8. Create Shard Group/Director/Add Shards.
-- (On shardcat):

1. 
```
[oracle@shardcat ~]$ gdsctl
Current GSM is set to SHARDDIRECTOR1s
```
2. 
```
GDSCTL> set gsm -gsm sharddirector1;
```
3. 
```
GDSCTL> connect mygdsadmin/SYS123sys
Catalog connection is established
```

4. 
/*
```
add shardgroup -shardgroup shardgroup_name 
              [-region region_name] 
              [-shardspace shardspace_name]
              [-deploy_as {PRIMARY | STANDBY | ACTIVE_STANDBY}]

*/
--GDSCTL> Remove shardgroup -shardgroup primary_shardgroup;
GDSCTL> add shardgroup -shardgroup primary_shardgroup -deploy_as primary -region region1;
The operation completed successfully

```
5. 
/*
```
add {invitednode | invitedsubnet}
	[-group group_name] 
	[-catalog catalog_dbname [-user user_name/password]]
	vncr_id
*/
--GDSCTL> Remove invitednode shard1;
GDSCTL> add invitednode shard1;

```
6. 
/*
```
create shard  [{-shardgroup shardgroup_name | –shardspace shardspace_name}] 
               [-deploy_as {primary | standby | active_standby}]
               [-rack rack_id]
                -destination destination_name 
               {-credential credential_name | -osaccount account_name  -ospassword password [-windows_domain domain_name]}
               [-dbparam db_parameter_file | -dbparamfile db_parameter_file]
               [-dbtemplate db_template_file | -dbtemplatefile db_template_file]
               [-netparam net_parameter_file | -netparamfile net_parameter_file]
               [-serviceuserpassword pwd] 
               [-sys_password]
               [-system_password]
*/
--GDSCTL> Remove shard -shardgroup primary_shardgroup;
GDSCTL> create shard -shardgroup primary_shardgroup -destination shard1 -credential oracle_cred;
The operation completed successfully
DB Unique Name: sh1

```
7. 
--add shard2
```
GDSCTL> add invitednode shard2;
GDSCTL> create shard -shardgroup primary_shardgroup -destination shard2 -credential oracle_cred;
The operation completed successfully
DB Unique Name: sh2
```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 9. Deploy Shards.
-- (On shardcat):

1. 
```
[oracle@shardcat ~]$ gdsctl
Current GSM is set to SHARDDIRECTOR1
```
2. 
```
GDSCTL> set gsm -gsm sharddirector1;
```
3. 
```
GDSCTL> connect mygdsadmin/SYS123sys
Catalog connection is established
```
4. 
-- Note: This will create the databases in "shard1" and "shard2" \
-- using dbca and create listeners automatically.
```
GDSCTL> deploy
The operation completed successfully

/*
- NETCA ERROR:
```
1. 
```
[oracle@shard1 ~]$ grid_env
[oracle@shard1 ~]$ netca
-> Delete listener...
```
2. 
```
[oracle@shard1 ~]$ db_env
[oracle@shard1 ~]$ srvctl status listener
PRCN-2044 : No listener exists

*/
```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 10. Verify Shard Status.
-- (On shardcat):

1. 
```
GDSCTL> config
```
2. 
```
GDSCTL> config shard
Name Shard Group        Status State    Region  Availability
---- ------------------ ------ -------- ------- ------------
sh1  primary_shardgroup Ok     Deployed region1 ONLINE
sh2  primary_shardgroup Ok     Deployed region1 ONLINE
```
3. 
```
GDSCTL> config shard -shard sh1
GDSCTL> config shard -shard sh2
Name: sh1
Shard Group: primary_shardgroup
Status: Ok
State: Deployed
Region: region1
Connection string: shard1:1521/sh1:dedicated
SCAN address:
ONS remote port: 0
Disk Threshold, ms: 20
CPU Threshold, %: 75
Version: 12.2.0.0
Failed DDL:
DDL Error: ---
Failed DDL id:
Availability: ONLINE
Rack:
```
4. 
```
GDSCTL> config shardgroup
Shard Group        Chunks Region  Shard space
------------------ ------ ------- -------------
primary_shardgroup 12     region1 shardspaceora
```
5. 
```
GDSCTL> config vncr
Name            Group ID
--------------- --------
192.168.96.144  
shard1          
shard2          
shard2.mosch.co 
shard1.mosch.co 
192.168.96.146  
192.168.96.147  
```
6. 
```
GDSCTL> databases
Database: "sh1" Registered: Y State: Ok ONS: N. Role: PRIMARY Instances: 1 Region: region1
   Registered instances:
     sdb%1
Database: "sh2" Registered: Y State: Ok ONS: N. Role: PRIMARY Instances: 1 Region: region1
   Registered instances:
     sdb%11
```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 11 : Create "Global Service" using GSDCTL
-- (shardcat):

1. 
```
[oracle@shardcat ~]$ gdsctl
Current GSM is set to SHARDDIRECTOR1
```
2. 
```
GDSCTL> set gsm -gsm sharddirector1;
```
3. 
```
GDSCTL> connect mygdsadmin/SYS123sys
Catalog connection is established
```
4. 
```
GDSCTL> add service -service test_srv -role primary
The operation completed successfully
```
5. 
```
GDSCTL> config service
Name      Network name             Pool  Started  Preferred all
--------  -----------------------  ----  -------  -------------
test_srv  test_srv.sdb.oradbcloud  sdb   No       Yes
```
6. 
```
GDSCTL> start service
The operation completed successfully
```
7. 
```
GDSCTL> status service
Service "test_srv.sdb.oradbcloud" has 2 instance(s). Affinity: ANYWHERE
   Instance "sdb%1", name: "sh1", db: "sh1", region: "region1", status: ready.
   Instance "sdb%11", name: "sh2", db: "sh2", region: "region1", status: ready.
```
8. 
```
GDSCTL> exit
```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 12: Create sample "schema" and "Tablespace" set and see that propagate to shard1/shard2
-- (shardcat):

1. 
```
[oracle@shardcat ~]$ db_env
[oracle@shardcat ~]$ sqlplus / as sysdba
Connected to:
Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
```
2. 
```
SQL> alter session enable shard ddl;
SQL> create user app_schema identified by SYS123sys;
SQL> grant all privileges to app_schema;
SQL> grant gsmadmin_role to app_schema;
SQL> grant select_catalog_role to app_schema;
SQL> grant connect, resource to app_schema;
SQL> grant dba to app_schema;
SQL> grant execute on dbms_crypto to app_schema;
```
3. 
```
SQL> conn app_schema/SYS123sys
SQL> alter session enable shard ddl;
SQL> CREATE TABLESPACE SET TSP_SET_1 using template (datafile size 100m extent management local segment space management auto );
SQL> CREATE TABLESPACE products_tsp datafile size 100m extent management local uniform size 1m;
```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 13: Create Shard "Tables" in SCAT Database
-- (shardcat):

1. 
```
[oracle@shardcat ~]$ db_env
[oracle@shardcat ~]$ sqlplus / as sysdba
Connected to:
Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
```
2. 
```
SQL> conn app_schema/SYS123sys
```
3. 
```
SQL> CREATE SHARDED TABLE Customers
(
CustId VARCHAR2(60) NOT NULL,
FirstName VARCHAR2(60),
LastName VARCHAR2(60),
Class VARCHAR2(10),
Geo VARCHAR2(8),
CustProfile VARCHAR2(4000),
Passwd RAW(60),
CONSTRAINT pk_customers PRIMARY KEY (CustId),
CONSTRAINT json_customers CHECK (CustProfile IS JSON)
) TABLESPACE SET TSP_SET_1
PARTITION BY CONSISTENT HASH (CustId) PARTITIONS AUTO;
```
4. 
```
SQL> CREATE SHARDED TABLE Orders
(
OrderId INTEGER NOT NULL,
CustId VARCHAR2(60) NOT NULL,
OrderDate TIMESTAMP NOT NULL,
SumTotal NUMBER(19,4),
Status CHAR(4),
constraint pk_orders primary key (CustId, OrderId),
constraint fk_orders_parent foreign key (CustId) 
references Customers on delete cascade
) partition by reference (fk_orders_parent);
```
5. 
```
SQL> CREATE SEQUENCE Orders_Seq;
```
6. 
```
SQL> CREATE SHARDED TABLE LineItems
(
OrderId INTEGER NOT NULL,
CustId VARCHAR2(60) NOT NULL,
ProductId INTEGER NOT NULL,
Price NUMBER(19,4),
Qty NUMBER,
constraint pk_items primary key (CustId, OrderId, ProductId),
constraint fk_items_parent foreign key (CustId, OrderId)
references Orders on delete cascade
) partition by reference (fk_items_parent);
```

7. duplicated table.
```
SQL> CREATE DUPLICATED TABLE Products
(
ProductId INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
Name VARCHAR2(128),
DescrUri VARCHAR2(128),
LastPrice NUMBER(19,4)
) TABLESPACE products_tsp;
```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================
- Step 14: Verify Distribution of Tables to shards
-- (On shardcat) & (On Shard1) & (On shard2):

1. 
-- (On shardcat):
```
[oracle@shardcat ~]$ db_env
[oracle@shardcat ~]$ sqlplus / as sysdba
SQL> SELECT tablespace_name, bytes/1024/1024 Size_MB from sys.dba_data_files order by tablespace_name;
TABLESPACE_NAME SIZE_MB
--------------- -------
PRODUCTS_TSP        100
SYSAUX              480
SYSTEM              800
TSP_SET_1           100
UNDOTBS1             70
USERS                 5

SQL> col table_name format a20
SQL> col partition_name format a20
SQL> col tablespace_name format a20
SQL> SELECT table_name, partition_name, tablespace_name from dba_tab_partitions where tablespace_name like '%SET%';
TABLE_NAME PARTITION_NAME TABLESPACE_NAME
---------- -------------- --------------------
CUSTOMERS  CUSTOMERS_P1   TSP_SET_1
ORDERS     CUSTOMERS_P1   TSP_SET_1
LINEITEMS  CUSTOMERS_P1   TSP_SET_1

SQL> Select a.name shard, count(b.chunk_number) Number_of_Chunks from gsmadmin_internal.database a, gsmadmin_internal.chunk_loc b where a.database_num=b.database_num group by a.name;
SHARD NUMBER_OF_CHUNKS
----- ----------------
sh1                  6
sh2                  6
```
2. 
-- (On shard1) The table and tablespace are partitioned and distributed some partitions:
```
[oracle@shard1 ~]$ db_env
[oracle@shard1 ~]$ sqlplus / as sysdba
SQL> col table_name format a20
SQL> col partition_name format a20
SQL> col tablespace_name format a20
SQL> SELECT table_name, partition_name, tablespace_name from dba_tab_partitions where tablespace_name like '%SET%' order by table_name;
```
3. 
-- (On shard2) The tables and tablespace are partitioned and distributed some partitions:
```
[oracle@shard2 ~]$ db_env
[oracle@shard2 ~]$ sqlplus / as sysdba
SQL> col table_name format a20
SQL> col partition_name format a20
SQL> col tablespace_name format a20
SQL> SELECT table_name, partition_name, tablespace_name from dba_tab_partitions where tablespace_name like '%SET%' order by table_name;
```
===============================================================================
-------------------------------------------------------------------------------
===============================================================================


