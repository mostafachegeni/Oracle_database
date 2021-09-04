# Drop a Table

[docs.oracle.com](https://docs.oracle.com/cd/B28359_01/server.111/b28310/tables010.htm#ADMIN01505) \
[docs.oracle.com](https://docs.oracle.com/cd/B28359_01/server.111/b28310/general007.htm#ADMIN11557) 
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- "PURGE": 
	- Using PURGE, "DROP TABLE" statement Immediately release the space 
	associated with the table.
	- Without PURGE, "DROP TABLE" statement renames the table and places 
	it in a "recycle bin", where it can later be recovered with the "FLASHBACK TABLE" statement.


- "indexes" and "triggers": are dropped.


- "synonyms": remain, but return an error when used. 


- "views" and "PL/SQL program units":
	All views and PL/SQL program units dependent on a dropped table remain, 
	yet become invalid (not usable). See "Managing Object Dependencies" for 
	information about how the database manages dependencies.

	- "dependent object":  An object that references another object.
	  "referenced object": An object being referenced.

	- "Object Invalidation": 
		When a referenced object is changed in a way that might affect a dependent 
		object, the dependent object is marked "invalid". 

	- "Recompilation": 
		An "invalid" dependent object must be recompiled against the new definition 
		of a referenced object before the dependent object can be used.

=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Drop the hr.int_admin_emp table:
```
SQL> DROP TABLE hr.int_admin_emp;
```

- Drop the FOREIGN KEY constraints of the child tables:
```
SQL> DROP TABLE hr.admin_emp CASCADE CONSTRAINTS;


-- Immediately release the space associated with the table.
-- Normally (Without using PURGE), The database renames the table and places 
-- it in a "recycle bin", where it can later be recovered with the "FLASHBACK TABLE" statement.
SQL> DROP TABLE hr.admin_emp PURGE;
```

- List of Commands to Drop "all tables" of a "user":
```
SQL> SELECT 'drop table ' || OWNER || '.' || table_name || ' cascade constraints PURGE;' SQL FROM dba_tables where owner='SHAHKAR3';
SQL
------------------------------------------------------------------
drop table SHAHKAR3.CUSTOMER_CACHE cascade constraints PURGE;
drop table SHAHKAR3.AGENT cascade constraints PURGE;
drop table SHAHKAR3.SUBSCRIPTION_POLICY cascade constraints PURGE;
drop table SHAHKAR3.VALIDATION_REQUEST cascade constraints PURGE;
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================


