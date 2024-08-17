-- This script allows the user to input the department name, semester name or paper name find the student with the highest mark
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE find_top_performing_student (
    p_department_name IN VARCHAR2,
    p_semester_name IN VARCHAR2,  
    p_paper_name IN VARCHAR2       
) AS
    v_student_id Student_performance.Student_ID%TYPE;
    v_max_marks Student_performance.Marks%TYPE;
BEGIN
    -- Output input parameters for debugging
    DBMS_OUTPUT.PUT_LINE('Input Parameters:');
    DBMS_OUTPUT.PUT_LINE('Department Name: ' || p_department_name);
    DBMS_OUTPUT.PUT_LINE('Semester Name: ' || p_semester_name);
    DBMS_OUTPUT.PUT_LINE('Paper Name: ' || p_paper_name)

    BEGIN
        SELECT Student_ID, Marks
        INTO v_student_id, v_max_marks
        FROM (
            SELECT sp.Student_ID, sp.Marks
            FROM Student_performance sp
            JOIN student_counseling e ON e.Student_ID = sp.Student_ID
            JOIN Department_info d ON d.Department_ID = e.Department_admission
            WHERE (p_department_name IS NULL OR UPPER(d.Department_Name) = UPPER(p_department_name))
              AND (p_semester_name IS NULL OR UPPER(sp.Semester_Name) = UPPER(p_semester_name))
              AND (p_paper_name IS NULL OR UPPER(sp.Paper_Name) = UPPER(p_paper_name))
            ORDER BY sp.Marks DESC
        )
        WHERE ROWNUM = 1;

      
        DBMS_OUTPUT.PUT_LINE('Top Performing Student Details:');
        DBMS_OUTPUT.PUT_LINE('Student ID: ' || v_student_id);
        DBMS_OUTPUT.PUT_LINE('Max Marks: ' || v_max_marks);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No records found for the given input.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
    END;
END;
/

ACCEPT department_name CHAR PROMPT 'Enter Department Name (leave blank if not filtering by Department Name): '
ACCEPT semester_name CHAR PROMPT 'Enter Semester Name (leave blank if not filtering by Semester Name): '
ACCEPT paper_name CHAR PROMPT 'Enter Paper Name (leave blank if not filtering by Paper Name): '

BEGIN
    find_top_performing_student(
        p_department_name => '&department_name',
        p_semester_name => '&semester_name',
        p_paper_name => '&paper_name'
    );
END;
/
