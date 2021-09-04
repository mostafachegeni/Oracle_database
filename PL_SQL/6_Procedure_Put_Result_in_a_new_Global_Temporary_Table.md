# Procedure Put Result in a new Global Temporary Table
------------------------------------------------------------------------------
- Create User:
```
CREATE USER MOSCH IDENTIFIED BY SYS123sys;
```
------------------------------------------------------------------------------
- Grant Required Privileges:
```
GRANT CREATE TABLE           TO MOSCH;
GRANT CREATE PROCEDURE       TO MOSCH;
GRANT CREATE SESSION         TO MOSCH;
GRANT CREATE SEQUENCE        TO MOSCH;
GRANT SELECT ON HR.EMPLOYEES TO MOSCH;
```
------------------------------------------------------------------------------
- Create Sequence:
```
-- DROP SEQUENCE mosch_seq_1;
CREATE SEQUENCE mosch_seq_1
  MINVALUE 37615438735
  MAXVALUE 999999999999999999999999999
  START WITH 37615438735
  INCREMENT BY 1
  CACHE 5;
```
------------------------------------------------------------------------------
- Create the Procedure:
```
create or replace procedure mosch.CDR_Date (StartDate IN date, EndDate IN date, CallName in varchar2, TG out varchar2) 
IS 
    mStartDate varchar2(20);
    mEndDate varchar2(20);
    stmt varchar2(1000);
BEGIN 
	IF( (StartDate is not null) and (EndDate is not null) and (CallName is not null) )
	THEN
        mStartDate := to_char(StartDate, 'YYYY-MM-DD HH24:MI:SS');
        mEndDate := to_char(EndDate, 'YYYY-MM-DD HH24:MI:SS');
        TG := 'mosch.cdr_table_' || mosch_seq_1.NEXTVAL;

        stmt := 'create GLOBAL TEMPORARY table '|| TG || ' ON COMMIT PRESERVE ROWS as 
        (select * from hr.employees where first_name=''' || CallName || 
        ''' and hire_date>=to_date(''' || mStartDate || ''',''YYYY-MM-DD HH24:MI:SS'') 
        and hire_date<=to_date(''' || mEndDate || ''',''YYYY-MM-DD HH24:MI:SS''))';
        execute immediate stmt;
    ELSIF( (StartDate is null) and (EndDate is not null) and (CallName is not null) ) 
    THEN
        mEndDate := to_char(EndDate, 'YYYY-MM-DD HH24:MI:SS');
        TG := 'mosch.cdr_table_' || mosch_seq_1.NEXTVAL;
        
        stmt := 'create GLOBAL TEMPORARY table '|| TG || ' ON COMMIT PRESERVE ROWS as 
        (select * from hr.employees where first_name=''' || CallName || 
        ''' and hire_date<=to_date(''' || mEndDate || ''',''YYYY-MM-DD HH24:MI:SS''))';
        execute immediate stmt;
    ELSIF( (StartDate is null) and (EndDate is null) and (CallName is not null) ) 
    THEN
        TG := 'mosch.cdr_table_' || mosch_seq_1.NEXTVAL;
        
        stmt := 'create GLOBAL TEMPORARY table '|| TG || ' ON COMMIT PRESERVE ROWS as 
        (select * from hr.employees where first_name=''' || CallName || 
        ''' )';
        execute immediate stmt;
    END IF;
END;
```
------------------------------------------------------------------------------
- Run The Procedure:
```
declare 
    start_date DATE;
    end_date DATE;
    call_name varchar2(100);
    TG varchar2(100);
begin 
    start_date := to_date('2005-06-01 14:00:00', 'YYYY-MM-DD HH24:MI:SS');
    end_date := to_date('2007-06-01 14:00:00', 'YYYY-MM-DD HH24:MI:SS');
    call_name := 'Peter';
    mosch.CDR_Date(start_date, end_date, call_name, TG);
    dbms_output.put_line('The result is saved in table = "' || TG || '"');


    end_date := to_date('2006-01-01 00:00;00', 'YYYY-MM-DD HH24:MI:SS');
    call_name := 'Peter';
    mosch.CDR_Date(NULL, end_date, call_name, TG);
    dbms_output.put_line('The result is saved in table = "' || TG || '"');


    call_name := 'Peter';
    mosch.CDR_Date(NULL, NULL, call_name, TG);
    dbms_output.put_line('The result is saved in table = "' || TG || '"');
end;
```
------------------------------------------------------------------------------
