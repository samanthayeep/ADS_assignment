-- This script allows user to input department name to query all the students in the department

SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE find_students_by_department (
    p_department_name IN VARCHAR2 -- User input for Department Name
) AS
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('Input Parameter:');
    DBMS_OUTPUT.PUT_LINE('Department Name: ' || p_department_name);

    
    FOR rec IN (
        SELECT sc.Student_ID, sc.DOA, sc.DOB, sc.Department_Choices, sc.Department_Admission, d.Department_Name
        FROM Student_counseling sc
        JOIN Department_info d ON sc.Department_Admission = d.Department_ID
        WHERE UPPER(d.Department_Name) = UPPER(p_department_name)
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Student ID: ' || rec.Student_ID);
        DBMS_OUTPUT.PUT_LINE('Date of Admission: ' || TO_CHAR(rec.DOA, 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE('Date of Birth: ' || TO_CHAR(rec.DOB, 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE(''); -- Blank line for readability
    END LOOP;

    
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No students found for the given department.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/


ACCEPT department_name CHAR PROMPT 'Enter Department Name: '


BEGIN
    find_students_by_department(
        p_department_name => '&department_name'
    );
END;
/
