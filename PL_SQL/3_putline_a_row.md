# putline a row
===========================================================================
---------------------------------------------------------------------------
===========================================================================
```
DECLARE
  l_last_name  			hr.employees.last_name%TYPE;
  l_department_name  	hr.departments.department_name%TYPE;
BEGIN
  SELECT last_name, department_name
    INTO l_last_name, l_department_name
    FROM hr.employees e, hr.departments d
    WHERE e.department_id=d.department_id
          AND e.employee_id=138;
  DBMS_OUTPUT.put_line (l_last_name || ' in ' || l_department_name);
END;
```
===========================================================================
---------------------------------------------------------------------------
===========================================================================

