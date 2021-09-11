# User Management

- List of all Schemas:
```
SQL> select username, account_status, default_tablespace, temporary_tablespace, PROFILE, CREATED from dba_users where ACCOUNT_STATUS='OPEN' order by username;
```
- List of privileges/roles granted to "user/role":
```
SQL> SELECT * FROM DBA_SYS_PRIVS  where grantee = '&USER_or_ROLE';	-- List of Granted "System Privileges" 
SQL> SELECT * FROM DBA_TAB_PRIVS  where grantee = '&USER_or_ROLE';	-- List of Granted "Object Privileges"
SQL> SELECT * FROM DBA_COL_PRIVS  where grantee = '&USER_or_ROLE';	-- List of Granted "Column-specific Object Privileges"
SQL> SELECT * FROM DBA_ROLE_PRIVS where grantee = '&USER_or_ROLE';	-- List of Granted "Roles"
```
- List of Limits Defilned in a "profile":
```
SQL> SELECT * FROM DBA_PROFILES WHERE PROFILE = '&PROFILE';
```
-------------------------------------------------------------------------
- List of "all Profiles":
```
SQL> SELECT * FROM DBA_PROFILES ORDER BY PROFILE;
SQL> SELECT profile, listagg(resource_name || '  (Type:' || resource_type || ', Limit:' || limit || ')' || chr(10)) within Group (order by resource_name) 	 FROM DBA_PROFILES group by profile ORDER BY PROFILE;
SQL> SELECT profile, rtrim(xmlagg(xmlelement(e, resource_name || '  (Type:' || resource_type || ', Limit:' || limit || ')' || chr(10)).extract('//text()') order by resource_name).getclobval(),', ') x 	 FROM DBA_PROFILES group by profile ORDER BY PROFILE;
```
- List of "all Quotas" for tablespaces:
```
SQL> SELECT * FROM DBA_TS_QUOTAS;
```
- List of "all roles":
```
SQL> SELECT * FROM DBA_ROLES;
```
-------------------------------------------------------------------------
- List of privileges/roles granted to "current session":
```
SQL> SELECT * FROM SESSION_PRIVS ORDER BY privilege;
SQL> SELECT * FROM SESSION_ROLES;
```

- List of all oracle system privileges:
```
SQL> SELECT name FROM system_privilege_map ORDER BY name;
```

-------------------------------------------------------------------------
-------------------------------------------------------------------------
- Add/Drop User:
```
SQL> CREATE USER new_user IDENTIFIED BY new_password;
SQL> GRANT CREATE SESSION TO new_user;
```
------------
- Drop the user and all associated objects 
- and foreign keys that depend on the tables of the user:
```
SQL> DROP USER new_user CASCADE;
```
------------
- Add new "User":
```
SQL> CREATE USER new_user
		IDENTIFIED BY new_password
		DEFAULT TABLESPACE my_tbs_1
		QUOTA 100M 	ON my_tbs_1
		QUOTA 500K 	ON my_tbs_2
		TEMPORARY TABLESPACE my_temp_tbs
		PROFILE new_profile;
```
------------
- Revoke "Quota" on "Tablespace" for User:
```
SQL> ALTER USER new_user
		IDENTIFIED BY new_password
		DEFAULT TABLESPACE my_tbs_1
		QUOTA 100M 	ON my_tbs_1
		QUOTA 0 	ON my_tbs_2
		TEMPORARY TABLESPACE my_temp_tbs
		PROFILE new_profile;
```
---------------------------
- Change limits in a profile:
```
SQL> ALTER PROFILE myProfile LIMIT PASSWORD_LIFE_TIME unlimited;

```
---------------------------
- Reopen an "Expired" User:
```
USERNAME ACCOUNT_STATUS 
-------- --------------
MYUSER  EXPIRED        

SQL> set long 9999999
SQL> set line 400
SQL> select dbms_metadata.get_ddl('USER','MYUSER') from dual;
DBMS_METADATA.GET_DDL('USER','MYUSER')
--------------------------------------------------------------------------------
CREATE USER "MYUSER" IDENTIFIED BY VALUES 'S:1B2C583C0C4FC558D3C4165017A5347
E21F340388E46779C78CA966C95AC;T:C03B2A8E651A086B8435CD6ECEA94117E93C1161AD699F90
235DDF8E647C079856D2A9130B3CCEAA115B6E644AECBA0B7B500FF8A2F26283914E6248118BCD35
A6F90BCD780D6DC599675F4DE2092CCA'
      DEFAULT TABLESPACE "USERS"
      TEMPORARY TABLESPACE "TEMP"
      PASSWORD EXPIRE

SQL> Alter user "MYUSER" identified by values 'S:1B2C583C0C4FC558D3C4165017A5347E21F340388E46779C78CA966C95AC;T:C03B2A8E651A086B8435CD6ECEA94117E93C1161AD699F90235DDF8E647C079856D2A9130B3CCEAA115B6E644AECBA0B7B500FF8A2F26283914E6248118BCD35A6F90BCD780D6DC599675F4DE2092CCA';
User altered.
```

-------------------------------------------------------------------------
-------------------------------------------------------------------------
- Add/Drop Role:
```
SQL> CREATE ROLE new_role IDENTIFIED BY new_password;
------------
SQL> DROP ROLE new_role;


-- Some Predefined Roles:
	- CONNECT 	->	(Following system privileges: ALTER SESSION, CREATE CLUSTER, CREATE DATABASE LINK, CREATE SEQUENCE, CREATE SESSION, CREATE SYNONYM, CREATE TABLE, CREATE VIEW)
	- RESOURCE 	-> 	(Following system privileges: CREATE CLUSTER, CREATE INDEXTYPE, CREATE OPERATOR, CREATE PROCEDURE, CREATE SEQUENCE, CREATE TABLE, CREATE TRIGGER, CREATE TYPE)
	- DBA 	 	-> 	(All system privileges WITH ADMIN OPTION)
```

-------------------------------------------------------------------------
- Add/Drop Profile:
```
SQL> CREATE PROFILE new_profile LIMIT SESSIONS_PER_USER 1 IDLE_TIME 30 CONNECT_TIME 600;
------------
SQL> DROP PROFILE new_profile CASCADE;
```


-------------------------------------------------------------------------
-------------------------------------------------------------------------
- Grant Privileges:
```
-- CONNECT role: "Set Container", and "Create Session" privileges.
-- RESOURCE role: allow user to "create" named types for custom schemas.
-- DBA role: allow user to "create", "alter", and "destroy" custom named types.


SQL> GRANT CONNECT, RESOURCE, DBA TO new_user;

SQL> GRANT ALL PRIVILEGES TO new_user;

SQL> GRANT UNLIMITED TABLESPACE TO new_user;
```
- Grant "DDL" to user:
```
SQL> GRANT CREATE TABLE TO new_user;
SQL> REVOKE CREATE TABLE FROM new_user;
```
- Grant "DML" to user:
```
SQL> GRANT SELECT, INSERT, UPDATE, DELETE ON hr.employees TO new_user;
SQL> REVOKE SELECT, INSERT, UPDATE, DELETE ON hr.employees FROM new_user;
```
- Grant "All Object Privileges" to user:
```
SQL> GRANT ALL ON hr.employees TO new_user;

SQL> GRANT CREATE PROFILE, ALTER PROFILE, DROP PROFILE,
		CREATE ROLE, DROP ANY ROLE, GRANT ANY ROLE, AUDIT ANY,
		AUDIT SYSTEM, CREATE USER, BECOME USER, ALTER USER, DROP USER
		TO security_admin WITH ADMIN OPTION;
```
- "Session Browser" and "Execution Plan" Privilleges:
```
SQL> GRANT select on v_$session to dump;
SQL> GRANT SELECT_CATALOG_ROLE to dump;
SQL> GRANT select any dictionary to dump;
```


-------------------------------------------------------------------------
-------------------------------------------------------------------------
- Create a User ZABBIX for DBforBIX to access your Oracle Database. You can use the following script:
```
  CREATE USER ZABBIX
  IDENTIFIED BY Zabbix#123
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT
  ACCOUNT UNLOCK;
  -– 2 Roles for ZABBIX
  GRANT CONNECT TO ZABBIX;
  GRANT RESOURCE TO ZABBIX;
  ALTER USER ZABBIX DEFAULT ROLE ALL;
  –- 5 System Privileges for ZABBIX
  -- removed as it is too permissive GRANT SELECT ANY TABLE TO ZABBIX;
  GRANT CREATE SESSION TO ZABBIX;	
  GRANT SELECT ANY DICTIONARY TO ZABBIX;
  --GRANT UNLIMITED TABLESPACE TO ZABBIX;
 GRANT SELECT ANY DICTIONARY TO ZABBIX;
NOTE : If you are using Oracle 11g, you will need to add the following:

  exec dbms_network_acl_admin.create_acl(acl => 'resolve.xml',description => 'resolve acl', principal =>'ZABBIX',is_grant => true, privilege => 'resolve');
  exec dbms_network_acl_admin.assign_acl(acl => 'resolve.xml', host =>'*');
You can verify the above is correct by running:

  select utl_inaddr.get_host_name('127.0.0.1') from dual;
NOTE: To create a User (ZABBIX) for DBforBIX with MINIMAL grants you can use the following script:

 CREATE USER ZABBIX
  IDENTIFIED BY <REPLACE WITH PASSWORD>
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT
  ACCOUNT UNLOCK;
  GRANT ALTER SESSION TO ZABBIX;
  GRANT CREATE SESSION TO ZABBIX;
  GRANT CONNECT TO ZABBIX;
  ALTER USER ZABBIX DEFAULT ROLE ALL;
  GRANT SELECT ON V_$INSTANCE TO ZABBIX;
  GRANT SELECT ON DBA_USERS TO ZABBIX;
  GRANT SELECT ON V_$LOG_HISTORY TO ZABBIX;
  GRANT SELECT ON V_$PARAMETER TO ZABBIX;
  GRANT SELECT ON SYS.DBA_AUDIT_SESSION TO ZABBIX;
  GRANT SELECT ON V_$LOCK TO ZABBIX;
  GRANT SELECT ON DBA_REGISTRY TO ZABBIX;
  GRANT SELECT ON V_$LIBRARYCACHE TO ZABBIX;
  GRANT SELECT ON V_$SYSSTAT TO ZABBIX;
  GRANT SELECT ON V_$PARAMETER TO ZABBIX;
  GRANT SELECT ON V_$LATCH TO ZABBIX;
  GRANT SELECT ON V_$PGASTAT TO ZABBIX;
  GRANT SELECT ON V_$SGASTAT TO ZABBIX;
  GRANT SELECT ON V_$LIBRARYCACHE TO ZABBIX;
  GRANT SELECT ON V_$PROCESS TO ZABBIX;
  GRANT SELECT ON DBA_DATA_FILES TO ZABBIX;
  GRANT SELECT ON DBA_TEMP_FILES TO ZABBIX;
  GRANT SELECT ON DBA_FREE_SPACE TO ZABBIX;
  GRANT SELECT ON V_$SYSTEM_EVENT TO ZABBIX;
```


-------------------------------------------------------------------------
-------------------------------------------------------------------------
- Add TALKUSER in TALK project:
```
SQL> select username, account_status, default_tablespace, temporary_tablespace from dba_users where ACCOUNT_STATUS='OPEN' order by username;
USERNAME             ACCOUNT_STATUS                   DEFAULT_TABLESPACE             TEMPORARY_TABLESPACE
-------------------- -------------------------------- ------------------------------ ------------------------------
SYS                  OPEN                             SYSTEM                         TEMP
SYSTEM               OPEN                             SYSTEM                         TEMP
TALKUSER             OPEN                             USERS                          TEMP
TALKUSER_TEST        OPEN                             USERS                          TEMP
ZABBIX               OPEN                             USERS                          TEMP

SQL> SELECT * FROM DBA_SYS_PRIVS  where grantee = 'TALKUSER';
GRANTEE  PRIVILEGE                                ADM COM INH
-------- ---------------------------------------- --- --- ---
TALKUSER UNLIMITED TABLESPACE                     NO  NO  NO
TALKUSER CREATE ANY SEQUENCE                      NO  NO  NO
TALKUSER CREATE ANY TABLE                         NO  NO  NO
TALKUSER CREATE SESSION                           NO  NO  NO

SQL> SELECT * FROM DBA_TAB_PRIVS  where grantee = 'TALKUSER';
GRANTEE              OWNER                TABLE_NAME           GRANTOR              PRIVILEGE            GRA HIE COM TYPE                     INH
-------------------- -------------------- -------------------- -------------------- -------------------- --- --- --- ------------------------ ---
TALKUSER             SYS                  KILL_SESSION         SYS                  EXECUTE              NO  NO  NO  FUNCTION                 NO

SQL> SELECT * FROM DBA_ROLE_PRIVS where grantee = 'TALKUSER';
GRANTEE              GRANTED_ROLE                                                                                                                     ADM DEL DEF COM INH
-------------------- -------------------------------------------------------------------------------------------------------------------------------- --- --- --- --- ---
TALKUSER             CONNECT                                                                                                                          NO  NO  YES NO  NO

SQL> SELECT * FROM DBA_COL_PRIVS  where grantee = 'TALKUSER';
no rows selected
```

