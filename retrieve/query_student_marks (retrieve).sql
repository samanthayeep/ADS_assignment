-- This script allows user to input student id, paper name or semester name to query the marks
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE retrieve_student_performance (
    p_student_id IN VARCHAR2,       
    p_paper_name IN VARCHAR2,       
    p_semester_name IN VARCHAR2     
) AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Input Parameters:');
    DBMS_OUTPUT.PUT_LINE('Student ID: ' || p_student_id);
    DBMS_OUTPUT.PUT_LINE('Paper Name: ' || p_paper_name);
    DBMS_OUTPUT.PUT_LINE('Semester Name: ' || p_semester_name);

    
    FOR rec IN (
        SELECT sp.Student_ID, sp.Semester_Name, sp.Paper_Name, sp.Marks
        FROM Student_performance sp
        JOIN Student_counseling sc ON sp.Student_ID = sc.Student_ID
        WHERE (p_student_id IS NULL OR sp.Student_ID = p_student_id)
          AND (p_paper_name IS NULL OR UPPER(sp.Paper_Name) = UPPER(p_paper_name))
          AND (p_semester_name IS NULL OR UPPER(sp.Semester_Name) = UPPER(p_semester_name))
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Student ID: ' || rec.Student_ID);
        DBMS_OUTPUT.PUT_LINE('Semester Name: ' || rec.Semester_Name);
        DBMS_OUTPUT.PUT_LINE('Paper Name: ' || rec.Paper_Name);
        DBMS_OUTPUT.PUT_LINE('Marks: ' || rec.Marks);
        DBMS_OUTPUT.PUT_LINE(''); 
    END LOOP;
    
    
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No records found for the given input.');
    END IF;
END;
/

ACCEPT student_id CHAR PROMPT 'Enter Student ID (leave blank if not filtering by Student ID): '
ACCEPT paper_name CHAR PROMPT 'Enter Paper Name (leave blank if not filtering by Paper Name): '
ACCEPT semester_name CHAR PROMPT 'Enter Semester Name (leave blank if not filtering by Semester Name): '


BEGIN
    retrieve_student_performance(
        p_student_id => '&student_id',
        p_paper_name => '&paper_name',
        p_semester_name => '&semester_name'
    );
END;
/
