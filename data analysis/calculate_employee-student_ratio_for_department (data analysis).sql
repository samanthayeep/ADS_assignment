-- allow user to input department name and get the student to employee ratio for each department
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE calculate_ratio_for_department (
    p_department_name IN VARCHAR2 -- User input for Department Name
) AS
BEGIN
    -- Output input parameters for debugging
    DBMS_OUTPUT.PUT_LINE('Input Parameters:');
    DBMS_OUTPUT.PUT_LINE('Department Name: ' || p_department_name);

    FOR ratio_rec IN (
        SELECT d.Department_Name,
               COUNT(e.Employee_ID) AS employee_count,
               COUNT(sc.Student_ID) AS student_count,
               CASE 
                   WHEN COUNT(e.Employee_ID) = 0 THEN 0
                   ELSE ROUND(COUNT(sc.Student_ID) / COUNT(e.Employee_ID), 2) 
               END AS emp_student_ratio 
        FROM Department_info d
        LEFT JOIN Employee_info e ON d.Department_ID = e.Department_ID
        LEFT JOIN Student_counseling sc ON d.Department_ID = sc.Department_Admission
        WHERE (p_department_name IS NULL OR UPPER(d.Department_Name) = UPPER(p_department_name))
        GROUP BY d.Department_Name
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Department: ' || ratio_rec.Department_Name ||
                             ' | Employee Count: ' || ratio_rec.employee_count ||
                             ' | Student Count: ' || ratio_rec.student_count ||
                             ' | Employee-Student Ratio: ' || ratio_rec.emp_student_ratio);
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No records found for the given input.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/
-- Execute procedure with user input
ACCEPT department_name CHAR PROMPT 'Enter Department Name (leave blank for all departments): '

BEGIN
    calculate_ratio_for_department(
        p_department_name => '&department_name'
    );
END;
/
