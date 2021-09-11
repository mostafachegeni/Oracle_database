# Auditing
-----------------------------------------------------------------------------------------------------

# References:
[oracle-base.com](https://oracle-base.com/articles/12c/auditing-enhancements-12cr1) \
[docs.oracle.com](https://docs.oracle.com/database/121/SQLRF/statements_4008.htm#SQLRF56110) \
[dbpilot.net](https://dbpilot.net/2020/how-to-turn-off-oracle-12c-unified-auditing-and-clean-up-all-unified-auditing-records/) \
[www.dba-oracle.com](http://www.dba-oracle.com/t_audit_when_not_successful.htm)


=====================================================================================================
-----------------------------------------------------------------------------------------------------
=====================================================================================================
- Enabling Unified Auditing in Oracle 12c:

0.
```
SQL> grant AUDIT_SYSTEM to sys;
```

1.
```
SQL> shutdown immediate;
```

2. Stop Listener:
```
[ ]$ lsnrctl stop
```

3. Stop the Enterprise Manager:
```
[ ]$ cd /u01/app/oracle/product/middleware/oms

[ ]$ export OMS_HOME=/u01/app/oracle/product/middleware/oms

[ ]$ $OMS_HOME/bin/emctl stop oms

```
4. Relink Oracle DB with the "uniaud option":
```
[ ]$ cd $ORACLE_HOME/rdbms/lib

[ ]$ make -f ins_rdbms.mk uniaud_on ioracle

SQL> startup;
 
[ ]$ lsnrctl start
```

7. Restart the Enterprise Manager:
```
[ ]$ cd /u01/app/oracle/product/middleware/oms

[ ]$ export OMS_HOME=/u01/app/oracle/product/middleware/oms

[ ]$ $OMS_HOME/bin/emctl start oms

```
8. Verify that unified auditing is enabled (verify VALUE = "TRUE"):
```
SQL> select * from v$option where PARAMETER = 'Unified Auditing';
```
=====================================================================================================
-----------------------------------------------------------------------------------------------------
=====================================================================================================
- Create Unified Audit Policy:

1. Create/Drop Audit Policy:
```
SQL> DROP AUDIT POLICY policy_name;
SQL> CREATE AUDIT POLICY policy_name
    { 
		{PRIVILEGE 	[action_audit_clause] [role_audit_clause ]	}
      | {ACTION  	[role_audit_clause 	] 						} 
      | {ROLE													}
    }
    [WHEN audit_condition EVALUATE PER {STATEMENT|SESSION|INSTANCE}] 
    [CONTAINER = {CURRENT | ALL}];


SQL> CREATE AUDIT POLICY test_audit_policy
		PRIVILEGES CREATE TABLE, CREATE SEQUENCE
		WHEN    'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') = ''&myUSERNAME'''
		EVALUATE PER SESSION
		CONTAINER = CURRENT;

SQL> CREATE AUDIT POLICY test_audit_policy
		ACTIONS DELETE ON test.tab1,
			  INSERT ON test.tab1,
			  UPDATE ON test.tab1,
			  SELECT ON test.tab1_seq,
			  ALL ON test.tab2,
			  SELECT ON test.tab2_seq
		WHEN    'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') = ''&myUSERNAME'''
		EVALUATE PER SESSION
		CONTAINER = CURRENT;

SQL> CREATE AUDIT POLICY create_table_role_policy
		ROLES create_table_role
		WHEN    'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') = ''&myUSERNAME'''
		EVALUATE PER SESSION
		CONTAINER = CURRENT;

```
2. Amend Unified Audit Policy:
```
SQL> ALTER AUDIT POLICY test_audit_policy
		DROP ACTIONS ALL ON test.tab2,
		SELECT ON test.tab2_seq;

```
3. Enable/Disable Unified Audit Policy:
```
SQL> NOAUDIT POLICY system_priv_list | statement_opt_list | object_opt_list;
SQL> AUDIT POLICY test_audit_policy;

/*
```
- Traditional Auditing:
```
SQL> AUDIT system_priv_list | statement_opt_list
		[BY user_list | proxy[ON BEHALF OF user|ANY]	]
		[BY SESSION|ACCESS								]
		[WHENEVER [NOT] SUCCESSFUL						];

SQL> AUDIT object_opt_list|ALL ON 
		[schema.]object_name | DIRECTORY dir_name | DEFAULT
		[BY SESSION|ACCESS								]
		[WHENEVER [NOT]SUCCESSFUL						]

SQL> NOAUDIT system_priv_list | statement_opt_list
		[BY user_list | proxy[ON BEHALF OF user|ANY]	]
		[WHENEVER [NOT] SUCCESSFUL						];

SQL> NOAUDIT object_opt_list | ALL ON 
		[schema.]object_name | DIRECTORY dir_name | DEFAULT
		[BY SESSION|ACCESS								]
		[WHENEVER [NOT]SUCCESSFUL						];
*/
```

=====================================================================================================
-----------------------------------------------------------------------------------------------------
=====================================================================================================
- Show "Audit Trails" and "Audit Policies":

1. You might need to flush the audit information before it is visible.
```
SQL> EXEC DBMS_AUDIT_MGMT.flush_unified_audit_trail;
```

2. Check Configuration of Auditing:
```
SQL> select name, value from v$parameter where name like '%audit%';

SQL> select * from v$option where PARAMETER = 'Unified Auditing';

```
3. List of All "Available Unified_Policies":
```
SQL> select * from audit_unified_policies;
SQL> SELECT  policy_name, rtrim(xmlagg(xmlelement(e, '(Audit_option_type:' || Audit_option_type || ', Audit_condition:' || Audit_condition || ', Condition_eval_opt:' || condition_eval_opt || ', Object_schema:' || Object_schema || ', Object_name:' || Object_name || ', Object_type:' || Object_type || ', common:' || common || ', Inherited:' || Inherited || ', Audit_option:' || Audit_option || ')' || chr(10)).extract('//text()') order by Audit_option).getclobval(),', ') x FROM audit_unified_policies  group by policy_name  ORDER BY policy_name;

```
4. List of All "Enabled Unified_Policies":
```
SQL> select * from audit_unified_enabled_policies;
```

5. List of Unified "Audit Trails":
```
SQL> select a.dbusername, a.event_timestamp, a.action_name, a.OBJECT_SCHEMA, a.object_name  
		from unified_audit_trail a
		where a.dbusername like '&myUSERNAME'
		order by a.event_timestamp desc;
```
=====================================================================================================
-----------------------------------------------------------------------------------------------------
=====================================================================================================
- Read audit xml-files in os:
```
SQL> select * from v$xml_audit_trail;

SQL> select * from dba_audit_trail;
SQL> select * from dba_audit_session;
SQL> select * from dba_audit_exists;


-- List of 
SQL> select distinct(audit_option) from dba_stmt_audit_opts;

SQL> select a.username, a.timestamp, a.action_name, a.owner, a.obj_name  
		from dba_audit_trail a
		where   a.username like 'INVENTIVE'
            AND a.action_name like '%TRUNC%'
		order by a.timestamp desc;

SQL> select * from dba_audit_session 
    where username in ('STAR_USER') 
    --where username in ('TABARI') 
    --where username in ('TAKBIRI') 
    order by timestamp desc;


```
=====================================================================================================
-----------------------------------------------------------------------------------------------------
=====================================================================================================
