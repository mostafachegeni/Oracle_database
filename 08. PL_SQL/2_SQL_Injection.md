# SQL Injection

[docs.oracle.com](https://docs.oracle.com/cd/E11882_01/appdev.112/e25519/dynamic.htm#LNPLS645)

---------------------------------------------------------------------
1. **SQL Injection Type 1 (Statement Modification)**:
> The following SELECT statement is vulnerable to modification because it uses "concatenation" to build WHERE clause.

```
CREATE OR REPLACE PROCEDURE get_record (
  query := 'SELECT value FROM secret_records WHERE user_name='''
           || user_name 
           || ''' AND service_type=''' 
           || service_type 
           || '''';
  EXECUTE IMMEDIATE query INTO rec ;
);


get_record(
'Anybody '' OR service_type=''Merger''--',
'Anything',
record_value);
```


- Guarding Against SQL Injection:

```
CREATE OR REPLACE PROCEDURE get_record_2 (
  query := 'SELECT value FROM secret_records
            WHERE user_name=:a
            AND service_type=:b';
  EXECUTE IMMEDIATE query INTO rec USING user_name, service_type;
);

```

- Attempt statement modification:
```
get_record_2('Anybody '' OR service_type=''Merger''--',
		   'Anything',
		   record_value);
*
ERROR at line 1:
ORA-01403: no data found
ORA-06512: at "HR.GET_RECORD_2", line 14
ORA-06512: at line 4
```


---------------------------------------------------------------------
---------------------------------------------------------------------
2. **SQL Injection Type 2**:
> The following block is vulnerable to statement injection because it is built by "concatenation".


```
CREATE OR REPLACE PROCEDURE p (
  block1 :=
    'BEGIN
    DBMS_OUTPUT.PUT_LINE(''user_name: ' || user_name || ''');'
    || 'DBMS_OUTPUT.PUT_LINE(''service_type: ' || service_type || ''');
    END;';
);


p('Anybody', 'Anything'');
DELETE FROM secret_records WHERE service_type=INITCAP(''Merger');
```


---------------------------------------------------------------------
---------------------------------------------------------------------
3. **SQL Injection Type 3**:
> The following SELECT statement is vulnerable to modification because it uses "concatenation" to build WHERE clause \
> and because SYSDATE depends on the value of "NLS_DATE_FORMAT".

```
CREATE OR REPLACE PROCEDURE get_recent_record (
  query := 'SELECT value FROM secret_records WHERE user_name='''
           || user_name
           || ''' AND service_type='''
           || service_type
           || ''' AND date_created>'''
           || (SYSDATE - 30)
           || '''';

  EXECUTE IMMEDIATE query INTO rec;
);


--ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY';
ALTER SESSION SET NLS_DATE_FORMAT='"'' OR service_type=''Merger"';
get_recent_record('Anybody', 'Anything', record_value);

```


- Guarding Against SQL Injection (Explicit Format Models):
```
CREATE OR REPLACE PROCEDURE get_recent_record (
  -- Following SELECT statement is vulnerable to modification
  -- because it uses concatenation to build WHERE clause.
  query := 'SELECT value FROM secret_records WHERE user_name='''
           || user_name 
           || ''' AND service_type=''' 
           || service_type 
           || ''' AND date_created> DATE ''' 
           || TO_CHAR(SYSDATE - 30,'YYYY-MM-DD') 
           || '''';
);


ALTER SESSION SET NLS_DATE_FORMAT='"'' OR service_type=''Merger"'; 
get_recent_record('Anybody', 'Anything', record_value);
* 
ERROR at line 1: 
ORA-01403: no data found 
ORA-06512: at "SYS.GET_RECENT_RECORD", line 21 
ORA-06512: at line 4 
```




