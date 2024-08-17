//This script allows user to input the student ID, semester name or paper name to query the average marks of the student, semester or paper
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE find_average_marks (
    p_student_id IN VARCHAR2, 
    p_semester_name IN VARCHAR2, 
    p_paper_name IN VARCHAR2 
) AS
    v_avg_marks NUMBER; 
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('Input Parameters:');
    DBMS_OUTPUT.PUT_LINE('Student ID: ' || p_student_id);
    DBMS_OUTPUT.PUT_LINE('Semester Name: ' || p_semester_name);
    DBMS_OUTPUT.PUT_LINE('Paper Name: ' || p_paper_name);

    BEGIN
        SELECT ROUND(AVG(Marks), 2) INTO v_avg_marks
        FROM Student_performance
        WHERE (p_student_id IS NULL OR UPPER(Student_ID) = UPPER(p_student_id))
          AND (p_semester_name IS NULL OR UPPER(Semester_Name) = UPPER(p_semester_name))
          AND (p_paper_name IS NULL OR UPPER(Paper_Name) = UPPER(p_paper_name));

        IF v_avg_marks IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('No records match the given filters.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Average Marks: ' || v_avg_marks);
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No records found for the given filters.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
    END;
END;
/

ACCEPT student_id CHAR PROMPT 'Enter Student ID (leave blank if not filtering by Student ID): '
ACCEPT semester_name CHAR PROMPT 'Enter Semester Name (leave blank if not filtering by Semester Name): '
ACCEPT paper_name CHAR PROMPT 'Enter Paper Name (leave blank if not filtering by Paper Name): '


BEGIN
    find_average_marks(
        p_student_id => '&student_id',
        p_semester_name => '&semester_name',
        p_paper_name => '&paper_name'
    );
END;
/
