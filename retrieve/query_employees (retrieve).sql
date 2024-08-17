-- This script allows users to input the department name to query all the employees in the department
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE find_employees_by_department (
    p_department_name IN VARCHAR2 
) AS
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('Input Parameter:');
    DBMS_OUTPUT.PUT_LINE('Department Name: ' || p_department_name);

   
    FOR rec IN (
        SELECT e.Employee_ID, e.DOB, e.DOJ, e.Department_ID, d.Department_Name
        FROM Employee_info e
        JOIN Department_info d ON e.Department_ID = d.Department_ID
        WHERE UPPER(d.Department_Name) = UPPER(p_department_name)
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Employee ID: ' || rec.Employee_ID);
        DBMS_OUTPUT.PUT_LINE('Date of Birth: ' || TO_CHAR(rec.DOB, 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE('Date of Joining: ' || TO_CHAR(rec.DOJ, 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE(''); 
    END LOOP;

    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No employees found for the given department.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

ACCEPT department_name CHAR PROMPT 'Enter Department Name: '

BEGIN
    find_employees_by_department(
        p_department_name => '&department_name'
    );
END;
/
