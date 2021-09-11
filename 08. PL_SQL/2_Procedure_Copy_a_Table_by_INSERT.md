# Procedure Copy a Table by INSERT
===========================================================================
---------------------------------------------------------------------------
===========================================================================
```
--SQL> Drop PROCEDURE procedure_copy_employee_table_data;


CREATE OR REPLACE PROCEDURE hr.procedure_copy_employee_table_data
    (start_time         IN DATE, 
	 end_time           IN DATE,
	 commit_after_in    IN Number)
IS
    cursor c_emp is
	SELECT *
		FROM hr.employees
		WHERE 	HIRE_DATE >= start_time
			and HIRE_DATE < end_time;

	loop_cnt number;
BEGIN 
   loop_cnt := 1;
   FOR r_emp IN c_emp
   LOOP
		INSERT INTO hr.employees_new
					(EMPLOYEE_ID,       FIRST_NAME,         LAST_NAME,          EMAIL,          PHONE_NUMBER,      HIRE_DATE,         JOB_ID,        SALARY,        COMMISSION_PCT,        MANAGER_ID,        DEPARTMENT_ID)
			VALUES 	(r_emp.EMPLOYEE_ID, r_emp.FIRST_NAME,   r_emp.LAST_NAME,    r_emp.EMAIL,    r_emp.PHONE_NUMBER, r_emp.HIRE_DATE,    r_emp.JOB_ID,   r_emp.SALARY,   r_emp.COMMISSION_PCT,   r_emp.MANAGER_ID,   r_emp.DEPARTMENT_ID);

		if(loop_cnt >= commit_after_in)
		then 
			loop_cnt := 1;
			-- DBMS_OUTPUT.put_line (r_emp.FIRST_NAME || ' ' || r_emp.LAST_NAME || ' hired at ' || r_emp.HIRE_DATE);
			COMMIT;
		else
			loop_cnt := loop_cnt + 1;
		end If;
   END LOOP;

   COMMIT; 
END;

```

===========================================================================
---------------------------------------------------------------------------
===========================================================================
- Run procedure:
```
DECLARE 
	start_time  		DATE;
	end_time  			DATE;
	commit_after_in 	Number;
BEGIN
  start_time := TO_DATE('2004/07/15', 'yyyy/mm/dd');
  end_time := TO_DATE('2005/02/18', 'yyyy/mm/dd');
  commit_after_in := 3;

  hr.procedure_copy_employee_table_data(start_time, end_time, commit_after_in);

END;
/
```
===========================================================================
---------------------------------------------------------------------------
===========================================================================
