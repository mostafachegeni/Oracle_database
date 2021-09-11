# Trigger
[docs.oracle.com](https://docs.oracle.com/database/121/DWHSG/basicmv.htm#GUID-1F42F25D-739B-4FEE-BEBC-212869D5CD10__i1006694) \
[oracle-base.com](https://oracle-base.com/articles/misc/materialized-views) 


-------------------------------------------------------------------------------------------------------
- **Trigger**: 
> BEFORE | AFTER 	-> 	(INSERT, UPDATE, DELETE) \
> FOR EACH ROW 	-> 	(row-level trigger) / (statement-level trigger) 

```
SQL> CREATE [OR REPLACE] TRIGGER trigger_name
		{BEFORE | AFTER} triggering_event ON table_name
		[FOR EACH ROW]
		[FOLLOWS | PRECEDES another_trigger]
		[ENABLE / DISABLE]
		[WHEN condition]
	DECLARE
		declaration statements
	BEGIN
		executable statements
	EXCEPTION
		exception_handling statements
	END;
```

-------------------------------------------------------------------------------------------------------

```
SQL> CREATE OR REPLACE TRIGGER TTOINFO_CRIME_before_insert
  BEFORE INSERT ON TTOINFO_CRIME
  FOR EACH ROW
BEGIN
  SELECT Field_2
  INTO :new.Field_2
  FROM Table_1
  WHERE Table_1.Field_1 = :new.Field_1;
END;
```

-------------------------------------------------------------------------------------------------------
