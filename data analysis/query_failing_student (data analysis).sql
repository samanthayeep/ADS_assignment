 -- This query allows the user to input the semester name, paper name, and passing marks to find the failing students
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE find_failing_students (
    p_semester_name IN VARCHAR2,  
    p_paper_name IN VARCHAR2,      
    p_passing_marks IN NUMBER      
) AS
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('Input Parameters:');
    DBMS_OUTPUT.PUT_LINE('Semester Name: ' || p_semester_name);
    DBMS_OUTPUT.PUT_LINE('Paper Name: ' || p_paper_name);
    DBMS_OUTPUT.PUT_LINE('Passing Marks: ' || p_passing_marks);

   
    FOR rec IN (
        SELECT sp.Student_ID, sp.Marks
        FROM Student_performance sp
        WHERE (p_semester_name IS NULL OR UPPER(sp.Semester_Name) = UPPER(p_semester_name))
          AND (p_paper_name IS NULL OR UPPER(sp.Paper_Name) = UPPER(p_paper_name))
          AND sp.Marks < p_passing_marks
        ORDER BY sp.Marks ASC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Failing Student ID: ' || rec.Student_ID);
        DBMS_OUTPUT.PUT_LINE('Marks: ' || rec.Marks);
        DBMS_OUTPUT.PUT_LINE(''); 
    END LOOP;

    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No failing students found for the given input.');
    END IF;
END;
/

ACCEPT semester_name CHAR PROMPT 'Enter Semester Name (leave blank if not filtering by Semester Name): '
ACCEPT paper_name CHAR PROMPT 'Enter Paper Name (leave blank if not filtering by Paper Name): '
ACCEPT passing_marks NUMBER PROMPT 'Enter Passing Marks: '

BEGIN
    find_failing_students(
        p_semester_name => '&semester_name',
        p_paper_name => '&paper_name',
        p_passing_marks => &passing_marks
    );
END;
/
