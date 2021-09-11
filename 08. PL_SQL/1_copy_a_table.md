# copy a table
===========================================================================
---------------------------------------------------------------------------
===========================================================================
```
SQL> CREATE TABLE hr.employees_5
	 AS (SELECT *
			FROM hr.employees_4 
			WHERE 1=2);


SQL> INSERT INTO table hr.employees_5(column1, column2, ... column_n ) 
		SELECT expression1, expression2, ... expression_n 
			FROM source_table 
			[WHERE conditions];



SQL> truncate table hr.employees_5;
--SQL> drop table hr.employees_5;


SQL> select count(*) from hr.employees_4;
SQL> select count(*) from hr.employees_5;


SQL> col EMP_NAME format a20
SQL> col EMP_EMAIL format a50
SQL> col EMP_ADDRESS format a30
SQL> col EMP_HIREDATE format a20
SQL> select rownum, a.* from hr.employees_4 a where EMP_NAME='Glenna Aguirre';
SQL> select rownum, a.* from hr.employees_4 a where EMP_Email='nec.ante.blandit@imperdietnonvestibulum.edu';
```
===========================================================================
---------------------------------------------------------------------------
===========================================================================
- Copy All rows of a table to another:

==================================
- Sample 1 (Copy Subset of Columns - NO Bulk Collect):
```
DECLARE 
    l_LOG_DATE 				hr.INTERVAL_TAB.LOG_DATE%TYPE;
    l_RESPONSESTATUSCODE 	hr.INTERVAL_TAB.RESPONSESTATUSCODE%TYPE;	
    l_STARTTIME 			hr.INTERVAL_TAB.STARTTIME%TYPE;	
    l_ENDTIME 				hr.INTERVAL_TAB.ENDTIME%TYPE;	

    CURSOR c1 IS SELECT LOG_DATE , RESPONSESTATUSCODE , STARTTIME , ENDTIME FROM hr.INTERVAL_TAB;
BEGIN 
  OPEN c1; 
  
  LOOP 
    FETCH c1 INTO l_LOG_DATE, l_RESPONSESTATUSCODE, l_STARTTIME , l_ENDTIME;
	EXIT WHEN c1%NOTFOUND;
    INSERT  INTO hr.INTERVAL_TAB_2(LOG_DATE , RESPONSESTATUSCODE , STARTTIME , ENDTIME) VALUES (l_LOG_DATE , l_RESPONSESTATUSCODE , l_STARTTIME , l_ENDTIME); 
  END LOOP; 
  
  CLOSE c1; 
  COMMIT; 
END;
```
==================================
- Sample 2 (Copy Subset of Columns - BULK COLLECT):
```
DECLARE 
    TYPE m_LOG_DATE 			IS TABLE OF hr.INTERVAL_TAB.LOG_DATE%TYPE;
    TYPE m_RESPONSESTATUSCODE 	IS TABLE OF hr.INTERVAL_TAB.RESPONSESTATUSCODE%TYPE;
    TYPE m_STARTTIME 			IS TABLE OF hr.INTERVAL_TAB.STARTTIME%TYPE;
    TYPE m_ENDTIME 				IS TABLE OF hr.INTERVAL_TAB.ENDTIME%TYPE;

    l_LOG_DATE 				m_LOG_DATE 			;
    l_RESPONSESTATUSCODE 	m_RESPONSESTATUSCODE;		
    l_STARTTIME 			m_STARTTIME 		;	
    l_ENDTIME 				m_ENDTIME 			;	

    CURSOR c1 IS SELECT LOG_DATE , RESPONSESTATUSCODE , STARTTIME , ENDTIME FROM hr.INTERVAL_TAB;
BEGIN 
  OPEN c1; 

  LOOP 
    FETCH c1 Bulk Collect INTO l_LOG_DATE, l_RESPONSESTATUSCODE, l_STARTTIME , l_ENDTIME LIMIT 10;
	EXIT WHEN c1%NOTFOUND;
	FORALL i IN 1 .. l_LOG_DATE.COUNT
		INSERT  INTO 	hr.INTERVAL_TAB_2		(LOG_DATE , 	RESPONSESTATUSCODE , 		STARTTIME , 	ENDTIME) 
				VALUES 						(l_LOG_DATE(i), l_RESPONSESTATUSCODE(i), 	l_STARTTIME(i), l_ENDTIME(i)); 
	commit;
  END LOOP; 
  
  CLOSE c1; 
--  COMMIT; 
END;
```
==================================
- Sample 3 (Copy All Columns - BULK COLLECT):
```
DECLARE 
    TYPE mARRAY IS TABLE OF hr.employees_4%ROWTYPE;
    l_data mARRAY;
    CURSOR c1 IS SELECT * FROM hr.employees_4;
BEGIN 
  OPEN c1; 
  
  LOOP 
    FETCH c1 BULK COLLECT INTO l_data LIMIT 10;
    
    FORALL i IN 1 .. l_data.COUNT 
        INSERT INTO hr.employees_5 VALUES l_data(i); 
    COMMIT; 
    
    EXIT WHEN c1%NOTFOUND;
  END LOOP; 
  
  CLOSE c1; 

END;
/
```

==================================
- Sample 4 (Copy All Columns - BULK COLLECT - Parallel):
```
DECLARE 
    TYPE mARRAY IS TABLE OF hr.employees%ROWTYPE;
    l_data mARRAY;
    CURSOR c1 IS SELECT /*+ parallel(employees_new,1) */ * FROM hr.employees_new WHERE HIRE_DATE >= TO_DATE('2004/07/15', 'yyyy/mm/dd') and HIRE_DATE < TO_DATE('2005/02/18', 'yyyy/mm/dd');
BEGIN 
  OPEN c1; 
  
  LOOP 
    FETCH c1 BULK COLLECT INTO l_data LIMIT 1000;
    
    FORALL i IN 1 .. l_data.COUNT 
        INSERT /*+ parallel(hr.employees_new_2,16) */ INTO hr.employees_new_2 VALUES l_data(i); 
    COMMIT; 
    
    EXIT WHEN c1%NOTFOUND;
  END LOOP; 
  
  CLOSE c1; 
--  COMMIT; 
END;
```
===========================================================================
---------------------------------------------------------------------------
===========================================================================
