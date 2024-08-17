-- This script allows the user to input the id to query department, employee, student or admission information

SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE retrieve_data_based_on_input (
    p_table_choice IN NUMBER, -- User input to choose the table
    p_id IN VARCHAR2 -- User input for ID or other relevant data
) AS
    v_found BOOLEAN := FALSE; -- Flag to check if any records are found
BEGIN
    CASE p_table_choice
        WHEN 1 THEN
            
            FOR rec IN (SELECT * FROM Department_info WHERE UPPER(Department_ID) = UPPER(p_id)) LOOP
                v_found := TRUE; -- Set flag to TRUE when a record is found
                DBMS_OUTPUT.PUT_LINE('Department ID: ' || rec.Department_ID);
                DBMS_OUTPUT.PUT_LINE('Department Name: ' || rec.Department_Name);
                DBMS_OUTPUT.PUT_LINE('Date of Establishment: ' || rec.DOE);
            END LOOP;
        
        WHEN 2 THEN
           
            FOR rec IN (
                SELECT e.Employee_ID, e.DOB, e.DOJ, e.Department_ID, d.Department_Name
                FROM Employee_info e
                INNER JOIN Department_info d ON e.Department_ID = d.Department_ID
                WHERE UPPER(e.Employee_ID) = UPPER(p_id)
            ) LOOP
                v_found := TRUE; -- Set flag to TRUE when a record is found
                DBMS_OUTPUT.PUT_LINE('Employee ID: ' || rec.Employee_ID);
                DBMS_OUTPUT.PUT_LINE('Date of Birth: ' || rec.DOB);
                DBMS_OUTPUT.PUT_LINE('Date of Joining: ' || rec.DOJ);
                DBMS_OUTPUT.PUT_LINE('Department ID: ' || rec.Department_ID);
                DBMS_OUTPUT.PUT_LINE('Department Name: ' || rec.Department_Name);
                DBMS_OUTPUT.PUT_LINE('');
            END LOOP;

        WHEN 3 THEN
            
            FOR rec IN (SELECT * FROM Student_counseling WHERE UPPER(Student_ID) = UPPER(p_id)) LOOP
                v_found := TRUE; -- Set flag to TRUE when a record is found
                DBMS_OUTPUT.PUT_LINE('Student ID: ' || rec.Student_ID); 
                DBMS_OUTPUT.PUT_LINE('Date of Admission:'|| rec.DOA);
                DBMS_OUTPUT.PUT_LINE('Date of Birth:' || rec.DOB);
                DBMS_OUTPUT.PUT_LINE('Department Choices:' || rec.Department_Choices);
                DBMS_OUTPUT.PUT_LINE('Department Admission:' || rec.Department_Admission);
            END LOOP;
        
        WHEN 4 THEN
           
            FOR rec IN (SELECT * FROM Student_performance WHERE UPPER(Student_ID) = UPPER(p_id)) LOOP
                v_found := TRUE; -- Set flag to TRUE when a record is found
                DBMS_OUTPUT.PUT_LINE('Student Performance Info:');
                DBMS_OUTPUT.PUT_LINE('Student ID: ' || rec.Student_ID);
                DBMS_OUTPUT.PUT_LINE('Semester Name: ' || rec.Semester_Name);
                DBMS_OUTPUT.PUT_LINE('Paper ID: ' || rec.Paper_ID);
                DBMS_OUTPUT.PUT_LINE('Paper Name: ' || rec.Paper_Name);
                DBMS_OUTPUT.PUT_LINE('Marks: ' || rec.Marks);
                DBMS_OUTPUT.PUT_LINE('');
            END LOOP;
        
        ELSE
            DBMS_OUTPUT.PUT_LINE('Invalid table choice.');
    END CASE;

   
    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE('No records found for the given input.');
    END IF;
END;

ACCEPT table_choice NUMBER PROMPT 'Enter table choice (1 = Department_info, 2 = Employee_info, 3 = Student_counseling, 4 = Student_performance): '
ACCEPT id CHAR PROMPT 'Enter ID or relevant data: '


BEGIN
    retrieve_data_based_on_input(
        p_table_choice => &table_choice,
        p_id => '&id'
    );
END;
/
