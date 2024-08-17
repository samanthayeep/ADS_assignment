SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE student_department_preferences IS
BEGIN
    FOR rec IN (
        SELECT Department_Choices, COUNT(*) AS Choice_Count
        FROM Student_counseling
        GROUP BY Department_Choices
        ORDER BY Choice_Count DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Department Choices: ' || rec.Department_Choices || ' - Number of Students: ' || rec.Choice_Count);
    END LOOP;
END;
/

BEGIN
    student_department_preferences;
END;
/
