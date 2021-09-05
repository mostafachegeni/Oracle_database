# Constraints
==================================================================================================================
------------------------------------------------------------------------------------------------------------------
==================================================================================================================
- Add Primary key:
```
SQL> alter table hr.MY_TABLE_TEST_3 add constraint my_constraint_PK primary key (FIRST_NAME,LAST_NAME,EMAIL);
```
- Add Foreign Key:
```
SQL> alter table hr.MY_TABLE_TEST_6 add constraint my_constraint_FK foreign key (f1, f2,f3) references hr.MY_TABLE_TEST_3 (FIRST_NAME,LAST_NAME,EMAIL);
/*
ERROR at line 1:
ORA-02270: no matching unique or primary key for this column-list
*/
```

==================================================================================================================
------------------------------------------------------------------------------------------------------------------
==================================================================================================================
- Number of Constraints for each table in a specific schema:
```
SQL> select t.owner, 
			t.table_name, 
			(select count(*) from dba_constraints c where t.owner=c.owner AND t.table_name=c.table_name AND CONSTRAINT_TYPE='P') P_constraints,
			(select count(*) from dba_constraints c where t.owner=c.owner AND t.table_name=c.table_name AND CONSTRAINT_TYPE='U') U_constraints,
			(select count(*) from dba_constraints c where t.owner=c.owner AND t.table_name=c.table_name AND CONSTRAINT_TYPE='R') R_constraints,
			(select count(*) from dba_constraints c where t.owner=c.owner AND t.table_name=c.table_name AND CONSTRAINT_TYPE='C') C_constraints,
			(select count(*) from dba_constraints c where t.owner=c.owner AND t.table_name=c.table_name AND CONSTRAINT_TYPE='V') V_constraints,
			(select count(*) from dba_constraints c where t.owner=c.owner AND t.table_name=c.table_name AND CONSTRAINT_TYPE='O') O_constraints
	from dba_tables t
	where t.owner='HR';

```

- List of "References to" a specific table:
```
SQL> WITH constraints_cols as (
		select owner, table_name, CONSTRAINT_NAME, rtrim(xmlagg(xmlelement(e, 'column_name: ' || column_name || chr(10)).extract('//text()') order by column_name).getclobval(),', ') columns
			FROM dba_cons_columns 
			group by OWNER, TABLE_NAME, CONSTRAINT_NAME 
			ORDER BY OWNER, TABLE_NAME, CONSTRAINT_NAME 
	)
	select c1.owner, c1.table_name, c1.constraint_name, c1.constraint_type, c1.status, col.owner r_owner, col.table_name r_table_name, col.CONSTRAINT_NAME r_constraint_name, col.columns 
		from dba_constraints c1, constraints_cols col 
		where 	c1.constraint_type = 'R' 
			and c1.r_constraint_name in ( select 	constraint_name 
											from 	dba_constraints c2 
											where 	c2.constraint_type in ('P', 'U') 
												and c2.owner 	= c1.r_owner 
												and c2.owner 	= '&OWNER' 
												--and table_name 	= '&TABLE_NAME' 
										)
			and c1.r_owner=col.owner 
			and c1.r_constraint_name = col.constraint_name
			order by r_owner, r_table_name;

```

- List of "References from" a specific table:
```
SQL> WITH constraints_cols as (
		select owner, table_name, CONSTRAINT_NAME, rtrim(xmlagg(xmlelement(e, 'column_name: ' || column_name || chr(10)).extract('//text()') order by column_name).getclobval(),', ') columns
			FROM dba_cons_columns 
			group by OWNER, TABLE_NAME, CONSTRAINT_NAME 
			ORDER BY OWNER, TABLE_NAME, CONSTRAINT_NAME 
	)
	select 	c1.owner, c1.table_name, c1.constraint_name, c1.constraint_type, c1.status, 
			(select c2.constraint_type from dba_constraints c2 where c2.owner=c1.r_owner and c2.constraint_name=c1.r_constraint_name) "R_CONSTRAINT_TYPE",
			col.owner r_owner, col.table_name r_table_name, col.CONSTRAINT_NAME r_constraint_name, col.columns 
		from dba_constraints c1, constraints_cols col 
		where 	c1.owner			='&OWNER' 
			--and c1.table_name 		= '&TABLE_NAME' 
			and c1.constraint_type 	= 'R' 
			and c1.r_owner=col.owner 
			and c1.r_constraint_name = col.constraint_name
			order by c1.owner, c1.table_name;
```
==================================================================================================================
------------------------------------------------------------------------------------------------------------------
==================================================================================================================
