-- This script allows the user to input the department name to query the number of students and staff in the department
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE calculate_department_totals (
    p_department_name IN VARCHAR2 -- User input for Department Name
) AS
    v_total_students  NUMBER; 
    v_total_employees NUMBER; 
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('Department Name: ' || p_department_name);

    BEGIN
        SELECT COUNT(sc.Student_ID)
        INTO v_total_students
        FROM Department_info d
        JOIN Student_counseling sc ON d.Department_ID = sc.Department_Admission
        WHERE (p_department_name IS NULL OR UPPER(d.Department_Name) = UPPER(p_department_name));

        SELECT COUNT(e.Employee_ID)
        INTO v_total_employees
        FROM Department_info d
        JOIN Employee_info e ON d.Department_ID = e.Department_ID
        WHERE (p_department_name IS NULL OR UPPER(d.Department_Name) = UPPER(p_department_name));

        IF p_department_name IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('Total Students in All Departments: ' || v_total_students);
            DBMS_OUTPUT.PUT_LINE('Total Employees in All Departments: ' || v_total_employees);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total Students in ' || p_department_name || ': ' || v_total_students);
            DBMS_OUTPUT.PUT_LINE('Total Employees in ' || p_department_name || ': ' || v_total_employees);
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No records found for the given input.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
    END;
END;
/

ACCEPT department_name CHAR PROMPT 'Enter Department Name (leave blank for all departments): '

BEGIN
    calculate_department_totals(
        p_department_name => '&department_name'
    );
END;
/
