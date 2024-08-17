SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE Display_Top_10_Departments IS
BEGIN
    FOR rec IN (
        SELECT Department_Name, Number_of_Admissions
        FROM (
            SELECT DI.Department_Name, COUNT(SC.Student_ID) AS Number_of_Admissions
            FROM Student_counseling SC
            JOIN Department_info DI ON SC.Department_Admission = DI.Department_ID
            GROUP BY DI.Department_Name
            ORDER BY COUNT(SC.Student_ID) DESC
        )
        WHERE ROWNUM <= 10
    ) LOOP
        -- Display the results
        DBMS_OUTPUT.PUT_LINE('Department: ' || rec.Department_Name || ' - Admissions: ' || rec.Number_of_Admissions);
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No departments found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

-- Execute the procedure
BEGIN
    Display_Top_10_Departments;
END;
/
