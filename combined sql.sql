-- CREATE TABLE

--connect to database--

CREATE USER assignment IDENTIFIED BY 1234;

GRANT CONNECT TO assignment;
GRANT CREATE SESSION, CREATE TABLE,CREATE TRIGGER, CREATE PROCEDURE, UNLIMITED TABLESPACE TO assignment;


-- Step 1: Drop Existing Tables
DROP TABLE Department_info CASCADE CONSTRAINTS;
DROP TABLE Employee_info CASCADE CONSTRAINTS;
DROP TABLE Student_counseling CASCADE CONSTRAINTS;
DROP TABLE Student_performance CASCADE CONSTRAINTS;

-- Step 2: Create Tables without Primary Keys and Foreign Keys
CREATE TABLE Department_info (
    Department_ID VARCHAR2(20),
    Department_Name VARCHAR2(100),
    DOE DATE
);

CREATE TABLE Employee_info (
    Employee_ID VARCHAR2(20),
    DOB DATE,
    DOJ DATE,
    Department_ID VARCHAR2(20)
);

CREATE TABLE Student_counseling (
    Student_ID VARCHAR2(20),
    DOA DATE,
    DOB DATE,
    Department_Choices VARCHAR2(20),
    Department_Admission VARCHAR2(20)
);

CREATE TABLE Student_performance (
    Student_ID VARCHAR2(20),
    Semester_Name VARCHAR2(20),
    Paper_ID VARCHAR2(20),
    Paper_Name VARCHAR2(100),
    Marks NUMBER
);

-- Step 3: Insert Data
-- Insert data into the tables here

--注： import student performance的时候， 有error的话check下右边target table column有没有match到（column definition那边)有时候会乱--

--接remove duplication的script---


-- REMOVE DUPLICATION
-- Step 4: Remove Duplicates
DELETE FROM Department_info
WHERE ROWID IN (
    SELECT ROWID
    FROM (
        SELECT ROWID, ROW_NUMBER() OVER (PARTITION BY Department_ID ORDER BY ROWID) AS rn
        FROM Department_info
    )
    WHERE rn > 1
);

DELETE FROM Employee_info
WHERE ROWID IN (
    SELECT ROWID
    FROM (
        SELECT ROWID, ROW_NUMBER() OVER (PARTITION BY Employee_ID ORDER BY ROWID) AS rn
        FROM Employee_info
    )
    WHERE rn > 1
);

DELETE FROM Student_counseling
WHERE ROWID IN (
    SELECT ROWID
    FROM (
        SELECT ROWID, ROW_NUMBER() OVER (PARTITION BY Student_ID ORDER BY ROWID) AS rn
        FROM Student_counseling
    )
    WHERE rn > 1
);

DELETE FROM Student_performance
WHERE ROWID IN (
    SELECT ROWID
    FROM (
        SELECT ROWID, ROW_NUMBER() OVER (PARTITION BY Student_ID, Semester_Name, Paper_ID ORDER BY ROWID) AS rn
        FROM Student_performance
    )
    WHERE rn > 1
);


-- Step 5: Add Primary Keys
ALTER TABLE Department_info
ADD CONSTRAINT pk_Department PRIMARY KEY (Department_ID);

ALTER TABLE Employee_info
ADD CONSTRAINT pk_Employee PRIMARY KEY (Employee_ID);

ALTER TABLE Student_counseling
ADD CONSTRAINT pk_Student_counseling PRIMARY KEY (Student_ID);

ALTER TABLE Student_performance
ADD CONSTRAINT pk_Student_performance PRIMARY KEY (Student_ID, Semester_Name, Paper_ID);


-- Step 6: Add Foreign Keys
ALTER TABLE Employee_info
ADD CONSTRAINT fk_Employee_Department FOREIGN KEY (Department_ID) REFERENCES Department_info (Department_ID);

ALTER TABLE Student_counseling
ADD CONSTRAINT fk_Student_Admission FOREIGN KEY (Department_Admission) REFERENCES Department_info (Department_ID);

ALTER TABLE Student_performance
ADD CONSTRAINT fk_Student_performance_Student FOREIGN KEY (Student_ID) REFERENCES Student_counseling (Student_ID);




--Index on Department_Name for faster searches--
CREATE INDEX IDX_Department_Name ON Department_info (Department_Name);


-- Foreign key index to improve joins with Department_Info
CREATE INDEX IDX_Employee_Department ON Employee_info (Department_ID);


-- Foreign key index to improve joins with Department_Info
CREATE INDEX IDX_Student_Department ON Student_counseling (Department_Admission);


-- Foreign key index to improve joins with Student_Counseling
CREATE INDEX IDX_Student_Performance_Couns ON Student_performance (Student_ID);
--------------------------------------------------------------------------------------------------------------------------------






-- Check primary keys
SELECT constraint_name, column_name
FROM all_cons_columns
WHERE table_name IN ('DEPARTMENT_INFO', 'EMPLOYEE_INFO', 'STUDENT_COUNSELING', 'STUDENT_PERFORMANCE')
AND constraint_name IN (
    SELECT constraint_name
    FROM all_constraints
    WHERE constraint_type = 'P'
    AND table_name IN ('DEPARTMENT_INFO', 'EMPLOYEE_INFO', 'STUDENT_COUNSELING', 'STUDENT_PERFORMANCE')
);


-- Check foreign keys
SELECT a.constraint_name, a.column_name, c_pk.table_name AS referenced_table, c_pk.column_name AS referenced_column
FROM all_cons_columns a
JOIN all_constraints c ON a.constraint_name = c.constraint_name
JOIN all_cons_columns c_pk ON c.r_constraint_name = c_pk.constraint_name
WHERE c.constraint_type = 'R'
AND a.table_name IN ('EMPLOYEE_INFO', 'STUDENT_COUNSELING', 'STUDENT_PERFORMANCE');


-- CREATE PART WITH TRIGGER
-- INSERT DATA INTO DEPARTMENT INFO WITH TRANSACTION MANAGEMENT --

CREATE OR REPLACE PROCEDURE insert_department_info (
    p_department_id            IN VARCHAR2,
    p_department_name          IN VARCHAR2,
    p_doe                     IN DATE
) IS
BEGIN
    SAVEPOINT sp_insert_department;
    INSERT INTO Department_info (
        Department_ID, 
        Department_Name, 
        DOE
    ) VALUES (
        p_department_id, 
        p_department_name, 
        p_doe
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Department inserted successfully.');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK TO sp_insert_department;
        DBMS_OUTPUT.PUT_LINE('Error: Department_ID already exists.');
    WHEN OTHERS THEN
        ROLLBACK TO sp_insert_department;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/ 

-- TRIGGERS FOR Department_info --

-- Before Insert Trigger: Validate data before inserting into Department_info
CREATE OR REPLACE TRIGGER tg_before_insert_department
BEFORE INSERT ON Department_info
FOR EACH ROW
BEGIN
    IF :NEW.Department_Name IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Department_Name cannot be null.');
    END IF;
END;
/ 

-- After Insert Trigger: Perform action after a record is inserted into Department_info
CREATE OR REPLACE TRIGGER tg_after_insert_department
AFTER INSERT ON Department_info
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Department with ID ' || :NEW.Department_ID || ' inserted.');
END;
/ 

-- USER INTERFACE FOR INSERT INTO DEPARTMENT INFO --

ACCEPT v_department_id CHAR PROMPT 'Enter Department ID: '
ACCEPT v_department_name CHAR PROMPT 'Enter Department Name: '
ACCEPT v_doe DATE FORMAT 'DD/MM/YYYY' PROMPT 'Enter Date of Establishment (DD/MM/YYYY): '

DECLARE
    l_department_id            VARCHAR2(20) := '&v_department_id';
    l_department_name          VARCHAR2(100) := '&v_department_name';
    l_doe                     DATE := TO_DATE('&v_doe', 'DD/MM/YYYY');
BEGIN
    insert_department_info(
        p_department_id => l_department_id,
        p_department_name => l_department_name,
        p_doe => l_doe
    );
END;
/ 

-- INSERT DATA INTO EMPLOYEE INFO --

CREATE OR REPLACE PROCEDURE insert_employee_info (
    p_employee_id              IN VARCHAR2,
    p_dob                     IN DATE,
    p_doj                     IN DATE,
    p_department_id            IN VARCHAR2
) IS
BEGIN
    SAVEPOINT sp_insert_employee;
    INSERT INTO Employee_info (
        Employee_ID, 
        DOB, 
        DOJ, 
        Department_ID
    ) VALUES (
        p_employee_id, 
        p_dob, 
        p_doj, 
        p_department_id
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Employee inserted successfully.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_insert_employee;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/


-- TRIGGERS FOR Employee_info --

-- Before Insert Trigger: Validate data before inserting into Employee_info
CREATE OR REPLACE TRIGGER trg_before_insert_employee
BEFORE INSERT ON Employee_info
FOR EACH ROW
BEGIN
    IF :NEW.Employee_ID IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Employee_ID cannot be null.');
    END IF;
END;
/ 

-- After Insert Trigger: Perform action after a record is inserted into Employee_info
CREATE OR REPLACE TRIGGER trg_after_insert_employee
AFTER INSERT ON Employee_info
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Employee with ID ' || :NEW.Employee_ID || ' inserted.');
END;
/ 

-- USER INTERFACE FOR INSERT INTO EMPLOYEE INFO --

ACCEPT v_employee_id CHAR PROMPT 'Enter Employee ID: '
ACCEPT v_dob DATE FORMAT 'DD/MM/YYYY' PROMPT 'Enter Date of Birth (DD/MM/YYYY): '
ACCEPT v_doj DATE FORMAT 'DD/MM/YYYY' PROMPT 'Enter Date of Joining (DD/MM/YYYY): '
ACCEPT v_department_id CHAR PROMPT 'Enter Department ID: '

DECLARE
    l_employee_id              VARCHAR2(20) := '&v_employee_id';
    l_dob                     DATE := TO_DATE('&v_dob', 'DD/MM/YYYY');
    l_doj                     DATE := TO_DATE('&v_doj', 'DD/MM/YYYY');
    l_department_id            VARCHAR2(20) := '&v_department_id';
BEGIN
    insert_employee_info(
        p_employee_id => l_employee_id,
        p_dob => l_dob,
        p_doj => l_doj,
        p_department_id => l_department_id
    );
END;
/ 

-- INSERT DATA INTO STUDENT COUNSELING --

CREATE OR REPLACE PROCEDURE insert_student_counseling (
    p_student_id               IN VARCHAR2,
    p_doa                     IN DATE,
    p_dob                     IN DATE,
    p_department_choices       IN VARCHAR2,
    p_department_admission     IN VARCHAR2
) IS
BEGIN
    SAVEPOINT sp_insert_student_counselin;
    INSERT INTO Student_counseling (
        Student_ID, 
        DOA, 
        DOB, 
        Department_Choices, 
        Department_Admission
    ) VALUES (
        p_student_id, 
        p_doa, 
        p_dob, 
        p_department_choices, 
        p_department_admission
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Student counseling info inserted successfully.');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK TO sp_insert_student_counseling;
        DBMS_OUTPUT.PUT_LINE('Error: Student_ID already exists.');
    WHEN OTHERS THEN
        ROLLBACK TO sp_insert_student_counseling;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/



-- TRIGGERS FOR Student_counseling --

-- Before Insert Trigger: Validate data before inserting into Student_counseling
CREATE OR REPLACE TRIGGER trg_before_insert_student
BEFORE INSERT ON Student_counseling
FOR EACH ROW
BEGIN
    IF :NEW.Student_ID IS NULL THEN
        RAISE_APPLICATION_ERROR(-20003, 'Student_ID cannot be null.');
    END IF;
END;
/ 

-- After Insert Trigger: Perform action after a record is inserted into Student_counseling
CREATE OR REPLACE TRIGGER trg_after_insert_student
AFTER INSERT ON Student_counseling
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Student with ID ' || :NEW.Student_ID || ' inserted.');
END;
/ 

-- USER INTERFACE FOR INSERT INTO STUDENT COUNSELING --

ACCEPT v_student_id CHAR PROMPT 'Enter Student ID: '
ACCEPT v_doa DATE FORMAT 'DD/MM/YYYY' PROMPT 'Enter Date of Admission (DD/MM/YYYY): '
ACCEPT v_dob DATE FORMAT 'DD/MM/YYYY' PROMPT 'Enter Date of Birth (DD/MM/YYYY): '
ACCEPT v_department_choices CHAR PROMPT 'Enter Department Choices: '
ACCEPT v_department_admission CHAR PROMPT 'Enter Department Admission: '

DECLARE
    l_student_id               VARCHAR2(20) := '&v_student_id';
    l_doa                     DATE := TO_DATE('&v_doa', 'DD/MM/YYYY');
    l_dob                     DATE := TO_DATE('&v_dob', 'DD/MM/YYYY');
    l_department_choices       VARCHAR2(20) := '&v_department_choices';
    l_department_admission     VARCHAR2(20) := '&v_department_admission';
BEGIN
    insert_student_counseling(
        p_student_id => l_student_id,
        p_doa => l_doa,
        p_dob => l_dob,
        p_department_choices => l_department_choices,
        p_department_admission => l_department_admission
    );
END;
/ 

-- INSERT DATA INTO STUDENT PERFORMANCE --

CREATE OR REPLACE PROCEDURE insert_student_performance (
    p_student_id               IN VARCHAR2,
    p_semester_name            IN VARCHAR2,
    p_paper_id                 IN VARCHAR2,
    p_paper_name               IN VARCHAR2,
    p_marks                    IN NUMBER
) IS
BEGIN
    SAVEPOINT sp_insert_student_performance;
    INSERT INTO Student_performance (
        Student_ID, 
        Semester_Name, 
        Paper_ID, 
        Paper_Name, 
        Marks
    ) VALUES (
        p_student_id, 
        p_semester_name, 
        p_paper_id, 
        p_paper_name, 
        p_marks
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Student performance info inserted successfully.');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK TO sp_insert_student_performance;
        DBMS_OUTPUT.PUT_LINE('Error: Student_ID, Semester_Name, and Paper_ID combination already exists.');
    WHEN OTHERS THEN
        ROLLBACK TO sp_insert_student_performance;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/


-- TRIGGERS FOR Student_performance --

-- Before Insert Trigger: Validate data before inserting into Student_performance
CREATE OR REPLACE TRIGGER trg_before_insert_performance
BEFORE INSERT ON Student_performance
FOR EACH ROW
BEGIN
    IF :NEW.Marks < 0 OR :NEW.Marks > 100 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Marks must be between 0 and 100.');
    END IF;
END;
/ 

-- After Insert Trigger: Perform action after a record is inserted into Student_performance
CREATE OR REPLACE TRIGGER trg_after_insert_performance
AFTER INSERT ON Student_performance
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Performance record for Student ID ' || :NEW.Student_ID || ' inserted.');
END;
/ 


-- USER INTERFACE FOR INSERT INTO STUDENT PERFORMANCE --

ACCEPT v_student_id CHAR PROMPT 'Enter Student ID: '
ACCEPT v_semester_name CHAR PROMPT 'Enter Semester Name: '
ACCEPT v_paper_id CHAR PROMPT 'Enter Paper ID: '
ACCEPT v_paper_name CHAR PROMPT 'Enter Paper Name: '
ACCEPT v_marks NUMBER PROMPT 'Enter Marks: '

DECLARE
    l_student_id               VARCHAR2(20) := '&v_student_id';
    l_semester_name            VARCHAR2(20) := '&v_semester_name';
    l_paper_id                 VARCHAR2(20) := '&v_paper_id';
    l_paper_name               VARCHAR2(100) := '&v_paper_name';
    l_marks                    NUMBER := &v_marks;
BEGIN
    insert_student_performance(
        p_student_id => l_student_id,
        p_semester_name => l_semester_name,
        p_paper_id => l_paper_id,
        p_paper_name => l_paper_name,
        p_marks => l_marks
    );
END;
/ 



-- RETRIEVE PART

-- QUERY EMPLOYEES
-- This script allows users to input the department name to query all the employees in the department
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE find_employees_by_department (
    p_department_name IN VARCHAR2 
) AS
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('Input Parameter:');
    DBMS_OUTPUT.PUT_LINE('Department Name: ' || p_department_name);

   
    FOR rec IN (
        SELECT e.Employee_ID, e.DOB, e.DOJ, e.Department_ID, d.Department_Name
        FROM Employee_info e
        JOIN Department_info d ON e.Department_ID = d.Department_ID
        WHERE UPPER(d.Department_Name) = UPPER(p_department_name)
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Employee ID: ' || rec.Employee_ID);
        DBMS_OUTPUT.PUT_LINE('Date of Birth: ' || TO_CHAR(rec.DOB, 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE('Date of Joining: ' || TO_CHAR(rec.DOJ, 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE(''); 
    END LOOP;

    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No employees found for the given department.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

ACCEPT department_name CHAR PROMPT 'Enter Department Name: '

BEGIN
    find_employees_by_department(
        p_department_name => '&department_name'
    );
END;
/

-- QUERY STUDENT MARKS
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


-- QUERY STUDENTS
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


-- QUERY_TOP_PERFORMING_STUDENT

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


-- QUERY BY ID

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

-- UPDATE PART

-- QUERY DEPARTMENT
SET SERVEROUTPUT ON;

-- Update into department_info
CREATE OR REPLACE PROCEDURE updateDepartmentInfo(
    s_department_id VARCHAR2, 
    dataChange VARCHAR2, 
    selection NUMBER
) AS
    
BEGIN
    SAVEPOINT sav1;

    IF selection = 1 THEN 
        UPDATE Department_info 
        SET department_name = dataChange 
        WHERE department_id = s_department_id;
    ELSIF selection = 2 THEN
        UPDATE Department_info 
        SET doe = TO_DATE(dataChange, 'DD/MM/YYYY') 
        WHERE department_id = s_department_id;
    ELSE
        dbms_output.put_line('Invalid selection value: ' || selection);
        ROLLBACK TO sav1;
        RETURN;
    END IF;

    -- Check if rows were updated
    IF SQL%ROWCOUNT = 0 THEN
        dbms_output.put_line('Unable to perform UPDATE! Department ID: ' || s_department_id || ' not found.');
    ELSE
        COMMIT;
    END IF;

END;
/

-- Trigger for Department info
-- BEFORE UPDATE Trigger:
CREATE OR REPLACE TRIGGER before_update_department
BEFORE UPDATE ON Department_info
FOR EACH ROW
BEGIN
    -- Ensure Department_Name not null
    IF :NEW.Department_Name IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Department Name cannot be null.');
    END IF;

    -- Check date format
    IF TO_CHAR(TO_DATE(:NEW.doe, 'DD/MM/YYYY'), 'DD/MM/YYYY') != :NEW.doe THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid date format. Please use DD/MM/YYYY format.');
    END IF;
END;
/

--After Update Trigger 
CREATE OR REPLACE TRIGGER after_update_department
AFTER UPDATE ON Department_info
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Department with ID ' || :NEW.DEPARTMENT_ID || ' updated.');
END;
/



-- Execute update Department Info
ACCEPT s_department_id CHAR PROMPT 'Please enter Department ID: ';
ACCEPT s_selection NUMBER PROMPT 'Please enter selection number 1-2 (1=DepartmentName, 2=DOE): ';
ACCEPT s_dataChange CHAR PROMPT 'Please enter change data (for date use DD/MM/YYYY format): ';

DECLARE 
    l_selection NUMBER := '&s_selection';
    l_departmentID VARCHAR2(255) := '&s_department_id';
    l_dataChange VARCHAR2(255) := '&s_dataChange';
BEGIN
    updateDepartmentInfo(
        l_departmentID, 
        l_dataChange, 
        l_selection
    );
END;
/


-- display update data
SELECT * FROM Department_info WHERE department_id = '&s_department_id';


-- QUERY_EMPLOYEE
SET SERVEROUTPUT ON;

-- Update into employee_info
CREATE OR REPLACE PROCEDURE updateEmployeeInfo(
    s_employee_id VARCHAR2, 
    dataChange VARCHAR2, 
    selection NUMBER
) AS
BEGIN
    SAVEPOINT sav1;

    IF selection = 1 THEN 
        -- Update DATE_OF_BIRTH
        UPDATE Employee_info 
        SET DOB = TO_DATE(dataChange, 'DD/MM/YYYY') 
        WHERE EMPLOYEE_ID = s_employee_id;
    ELSIF selection = 2 THEN
        -- Update DATE_OF_UNIVERSITY_JOINING
        UPDATE Employee_info 
        SET DOJ = TO_DATE(dataChange, 'DD/MM/YYYY') 
        WHERE EMPLOYEE_ID = s_employee_id;
    ELSIF selection = 3 THEN
        -- Update Department_ID
        UPDATE Employee_info 
        SET Department_ID = dataChange 
        WHERE EMPLOYEE_ID = s_employee_id;
    ELSE 
        dbms_output.put_line('Invalid selection value: ' || selection);
        ROLLBACK TO sav1;
        RETURN;
    END IF;

    -- Check if rows were updated
    IF SQL%ROWCOUNT = 0 THEN
        dbms_output.put_line('Unable to perform UPDATE! Employee ID: ' || s_employee_id || ' not found.');
        ROLLBACK TO sav1;
    ELSE
        COMMIT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('An error occurred: ' || SQLERRM);
        ROLLBACK TO sav1;
END;
/

-- Trigger 
-- Before Update Trigger
CREATE OR REPLACE TRIGGER before_update_employee
BEFORE UPDATE ON Employee_info
FOR EACH ROW
BEGIN
    -- Validate date format for DATE_OF_BIRTH
    IF :NEW.DOB IS NOT NULL AND 
       TO_CHAR(TO_DATE(:NEW.DOB, 'DD/MM/YYYY'), 'DD/MM/YYYY') != :NEW.DOB THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid date format for DATE_OF_BIRTH. Please use DD/MM/YYYY format.');
    END IF;

    -- Validate date format for DATE_OF_UNIVERSITY_JOINING
    IF :NEW.DOJ IS NOT NULL AND 
       TO_CHAR(TO_DATE(:NEW.DOJ, 'DD/MM/YYYY'), 'DD/MM/YYYY') != :NEW.DOJ THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid date format for DATE_OF_UNIVERSITY_JOINING. Please use DD/MM/YYYY format.');
    END IF;

    -- Check if the Department_ID exists in the Department_info
    IF :NEW.Department_ID != :OLD.Department_ID THEN
        DECLARE
            v_count INTEGER;
        BEGIN
            SELECT COUNT(*)
            INTO v_count
            FROM Department_info
            WHERE Department_ID = :NEW.Department_ID;

            IF v_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20003, 'The new Department_ID does not exist in the Department_info table.');
            END IF;
        END;
    END IF;
END;
/

--After Update Trigger 
CREATE OR REPLACE TRIGGER after_update_employee
AFTER UPDATE ON Employee_info
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Employee with ID ' || :NEW.EMPLOYEE_ID || ' updated.');
END;
/

-- Execute update Employee Info
accept s_employee_id char prompt 'Please enter Employee ID: '
accept s_selection number prompt 'Please enter selection number 1-3 (1=DateOfBirth, 2=DateOfUniversityJoining, 3=DepartmentID): '
accept s_dataChange char prompt 'Please enter change data (for date use DD/MM/YYYY format): ';

DECLARE 
    l_selection NUMBER := '&s_selection';
    l_employeeID VARCHAR2(255) := '&s_employee_id';
    l_dataChange VARCHAR2(255) := '&s_dataChange';

BEGIN
    updateEmployeeInfo(
        l_employeeID, 
        l_dataChange, 
        l_selection
    );
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('An error occurred: ' || SQLERRM);
END;
/

-- display updated data
SELECT * FROM Employee_info WHERE EMPLOYEE_ID = '&s_employee_id';
/


-- QUERY STUDENT COUNSELING
SET SERVEROUTPUT ON;

-- Create or replace the procedure for updating student counseling info
CREATE OR REPLACE PROCEDURE updateStudentCounseling(
    s_student_id VARCHAR2, 
    dataChange VARCHAR2, 
    selection NUMBER
) AS
BEGIN 
    SAVEPOINT sav1;

    IF selection = 1 THEN
        BEGIN
            UPDATE Student_counseling 
            SET DOA = TO_DATE(dataChange, 'MM/DD/YYYY') 
            WHERE Student_ID = s_student_id;
        END;
    ELSIF selection = 2 THEN  
        BEGIN
            UPDATE Student_counseling 
            SET DOB = TO_DATE(dataChange, 'MM/DD/YYYY') 
            WHERE Student_ID = s_student_id;
        END;
    ELSIF selection = 3 THEN
        BEGIN
            UPDATE Student_counseling 
            SET Department_Choices = dataChange 
            WHERE Student_ID = s_student_id;
        END;
    ELSIF selection = 4 THEN
        BEGIN
            UPDATE Student_counseling 
            SET Department_Admission = dataChange 
            WHERE Student_ID = s_student_id;
        END;
    ELSE 
        dbms_output.put_line('Invalid selection value: ' || selection);
        ROLLBACK TO sav1;
    END IF;

    -- Check if rows were updated
    IF SQL%ROWCOUNT = 0 THEN
        dbms_output.put_line('Unable to perform UPDATE! Student ID: ' || s_student_id || ' not found.');
    ELSE
        COMMIT;
    END IF;

END;
/

-- Trigger 
-- Before Update Trigger
CREATE OR REPLACE TRIGGER before_update_stu_counsel
BEFORE UPDATE ON Student_counseling
FOR EACH ROW
BEGIN
    -- Validate date format for DOA
    IF :NEW.DOA IS NOT NULL AND 
       TO_CHAR(TO_DATE(:NEW.DOA, 'DD/MM/YYYY'), 'DD/MM/YYYY') != :NEW.DOA THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid date format for DOA. Please use DD/MM/YYYY format.');
    END IF;

    -- Validate date format for DOB
    IF :NEW.DOB IS NOT NULL AND 
       TO_CHAR(TO_DATE(:NEW.DOB, 'DD/MM/YYYY'), 'DD/MM/YYYY') != :NEW.DOB THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid date format for DOB. Please use DD/MM/YYYY format.');
    END IF;

    -- Check if the DEPARTMENT_CHOICES exists
    IF :NEW.DEPARTMENT_CHOICES != :OLD.DEPARTMENT_CHOICES THEN
        DECLARE
            v_count INTEGER;
        BEGIN
            SELECT COUNT(*)
            INTO v_count
            FROM Department_info
            WHERE Department_Name = :NEW.DEPARTMENT_CHOICES;

            IF v_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20003, 'The new Department_Choices does not exist.');
            END IF;
        END;
    END IF;

    -- Check if the DEPARTMENT_ADMISSION exists
    IF :NEW.DEPARTMENT_ADMISSION != :OLD.DEPARTMENT_ADMISSION THEN
        DECLARE
            v_count INTEGER;
        BEGIN
            SELECT COUNT(*)
            INTO v_count
            FROM Department_info
            WHERE Department_Name = :NEW.DEPARTMENT_ADMISSION;

            IF v_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20004, 'The new Department_Admission does not exist.');
            END IF;
        END;
    END IF;
END;
/

-- After Update Trigger
CREATE OR REPLACE TRIGGER after_update_stu_counsel
AFTER UPDATE ON Student_counseling
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Student with ID ' || :NEW.STUDENT_ID || ' updated.');
END;
/


-- Execute the procedure for updating Student Counseling Info
accept s_student_id char prompt 'Please enter Student ID: '
accept s_selection number prompt 'Please enter selection number 1-4 (1=DateOfAdmission, 2=DateOfBirth, 3=DepartmentChoices, 4=DepartmentAdmission): '
accept s_dataChange char prompt 'Please enter change data (for date use DD/MM/YYYY format): '

DECLARE 
    l_selection NUMBER := '&s_selection';
    l_studentID VARCHAR2(255) := '&s_student_id';
    l_dataChange VARCHAR2(255) := '&s_dataChange';

BEGIN
    updateStudentCounseling(
        l_studentID, 
        l_dataChange, 
        l_selection
    );
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('An error occurred: ' || SQLERRM);
END;
/

-- Display updated data
SELECT * FROM Student_counseling WHERE Student_ID = '&s_student_id';
/


-- QUERY STUDENT PERFORMANCE
CREATE OR REPLACE PROCEDURE updateStudent_performance(
    s_student_id VARCHAR2, 
    dataChange VARCHAR2, 
    selection NUMBER
) AS
BEGIN
    SAVEPOINT sav1;

    IF selection = 1 THEN
        UPDATE Student_performance 
        SET Semester_Name = dataChange 
        WHERE Student_ID = s_student_id;
    ELSIF selection = 2 THEN
        UPDATE Student_performance 
        SET Paper_ID = dataChange 
        WHERE Student_ID = s_student_id;
    ELSIF selection = 3 THEN
        UPDATE Student_performance 
        SET Paper_Name = dataChange 
        WHERE Student_ID = s_student_id;
    ELSIF selection = 4 THEN
        UPDATE Student_performance 
        SET Marks = dataChange 
        WHERE Student_ID = s_student_id;
    ELSE
        dbms_output.put_line('Invalid selection value: ' || selection);
        ROLLBACK TO sav1;
        RETURN;
    END IF;

    -- Check if rows were updated
    IF SQL%ROWCOUNT = 0 THEN
        dbms_output.put_line('Unable to perform UPDATE! Student ID: ' || s_student_id || ' not found.');
    ELSE
        COMMIT;
    END IF;

END;
/

CREATE OR REPLACE TRIGGER before_update_stu_pref
BEFORE UPDATE ON Student_performance
FOR EACH ROW
BEGIN
    -- Validate Marks
    IF :NEW.Marks < 0 OR :NEW.Marks > 100 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Marks must be between 0 and 100.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER after_update_stu_perf
AFTER UPDATE ON Student_performance
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Student with ID ' || :NEW.Student_ID || ' updated.');
END;
/


-- Execute the procedure for updating Student Performance Info
ACCEPT s_student_id CHAR PROMPT 'Please enter Student ID: '
ACCEPT s_selection NUMBER PROMPT 'Please enter selection number 1-4 (1=SemesterName, 2=PaperID, 3=PaperName, 4=Marks): '
ACCEPT s_dataChange CHAR PROMPT 'Please enter change data: '

DECLARE 
    l_selection NUMBER := '&s_selection';
    l_studentID VARCHAR2(255) := '&s_student_id';
    l_dataChange VARCHAR2(255) := '&s_dataChange';

BEGIN
    updateStudent_performance(
        l_studentID, 
        l_dataChange, 
        l_selection
    );
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('An error occurred: ' || SQLERRM);
END;
/

-- Display updated data
SELECT * FROM Student_performance WHERE Student_ID = '&s_student_id';
/




-- DELETE PART
-- DELETE_TRIGGER
--insert deleted data into new table for backup--

CREATE TABLE Department_info_Deleted (
    Department_ID VARCHAR2(20), 
    Department_Name VARCHAR2(100), 
    DOE DATE, 
    deleted_at TIMESTAMP
);


CREATE TABLE Employee_info_Deleted (
    Employee_ID VARCHAR2(20), 
    DOB DATE, 
    DOJ DATE, 
    Department_ID VARCHAR2(20), 
    deleted_at TIMESTAMP
);


CREATE TABLE Student_counseling_Deleted (
    Student_ID VARCHAR2(20), 
    DOA DATE, 
    DOB DATE, 
    Department_Choices VARCHAR2(20), 
    Department_Admission VARCHAR2(20), 
    deleted_at TIMESTAMP
);


CREATE TABLE Student_performance_Deleted (
    Student_ID VARCHAR2(20), 
    Semester_Name VARCHAR2(20), 
    Paper_ID VARCHAR2(20), 
    Paper_Name VARCHAR2(100), 
    Marks NUMBER, 
    deleted_at TIMESTAMP
);


CREATE OR REPLACE TRIGGER after_delete_department
AFTER DELETE ON Department_info 
FOR EACH ROW 
BEGIN 
    INSERT INTO Department_info_Deleted (
        Department_ID, Department_Name, DOE, deleted_at
    ) 
    VALUES (
        :OLD.Department_ID, :OLD.Department_Name, :OLD.DOE, SYSTIMESTAMP
    ); 
END; 
/


CREATE OR REPLACE TRIGGER after_delete_employee
AFTER DELETE ON Employee_info 
FOR EACH ROW 
BEGIN 
    INSERT INTO Employee_info_Deleted (
        Employee_ID, DOB, DOJ, Department_ID, deleted_at
    ) 
    VALUES (
        :OLD.Employee_ID, :OLD.DOB, :OLD.DOJ, :OLD.Department_ID, SYSTIMESTAMP
    ); 
END; 
/


CREATE OR REPLACE TRIGGER after_delete_stu_counsel
AFTER DELETE ON Student_counseling 
FOR EACH ROW 
BEGIN 
    INSERT INTO Student_counseling_Deleted (
        Student_ID, DOA, DOB, Department_Choices, Department_Admission, deleted_at
    ) 
    VALUES (
        :OLD.Student_ID, :OLD.DOA, :OLD.DOB, :OLD.Department_Choices, :OLD.Department_Admission, SYSTIMESTAMP
    ); 
END; 
/



CREATE OR REPLACE TRIGGER after_delete_stu_perf
AFTER DELETE ON Student_performance 
FOR EACH ROW 
BEGIN 
    INSERT INTO Student_performance_Deleted (
        Student_ID, Semester_Name, Paper_ID, Paper_Name, Marks, deleted_at
    ) 
    VALUES (
        :OLD.Student_ID, :OLD.Semester_Name, :OLD.Paper_ID, :OLD.Paper_Name, :OLD.Marks, SYSTIMESTAMP
    ); 
END; 
/



--before update trigger--
CREATE OR REPLACE TRIGGER before_delete_department
BEFORE DELETE ON Department_info
FOR EACH ROW
BEGIN
    -- Check if the record exists
    IF :OLD.Department_ID IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Department ID is required and cannot be NULL.');
    END IF;

END;
/

CREATE OR REPLACE TRIGGER before_delete_employee
BEFORE DELETE ON Employee_info
FOR EACH ROW
BEGIN
    -- Check if the Employee_ID is valid (not NULL)
    IF :OLD.Employee_ID IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Employee ID is required and cannot be NULL.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER before_delete_stud_counsel
BEFORE DELETE ON Student_counseling
FOR EACH ROW
BEGIN
    -- Check if the record exists 
    IF :OLD.Student_ID IS NULL THEN
        RAISE_APPLICATION_ERROR(-20003, 'Student ID is required and cannot be NULL.');
    END IF;

END;
/

CREATE OR REPLACE TRIGGER before_delete_stu_perf
BEFORE DELETE ON Student_performance
FOR EACH ROW
BEGIN
    -- Check if the record exists 
    IF :OLD.Student_ID IS NULL THEN
        RAISE_APPLICATION_ERROR(-20004, 'Student ID is required and cannot be NULL.');
    END IF;
END
/

-- DELETE PROCEDURE AND EXECUTION

CREATE OR REPLACE PROCEDURE delete_from_chosen_table(
    p_choice IN NUMBER,
    p_id IN VARCHAR2
) AS
    v_table_name VARCHAR2(255);
    v_column_name VARCHAR2(255);
    v_sql VARCHAR2(1000);
BEGIN
    -- Determine the table and column name based on the user's choice
    CASE p_choice
        WHEN 1 THEN
            v_table_name := 'Department_info';
            v_column_name := 'Department_ID';
        WHEN 2 THEN
            v_table_name := 'Employee_info';
            v_column_name := 'Employee_ID';
        WHEN 3 THEN
            v_table_name := 'Student_counseling';
            v_column_name := 'Student_ID';
        WHEN 4 THEN
            v_table_name := 'Student_performance';
            v_column_name := 'Student_ID';
        ELSE
            DBMS_OUTPUT.PUT_LINE('Invalid choice. Please choose a valid option (1-4).');
            RETURN;
    END CASE;

    --Savepoint before selete
    SAVEPOINT before_delete;

    -- Perform the DELETE operation
    v_sql := 'DELETE FROM ' || v_table_name || ' WHERE ' || v_column_name || ' = :1';
    EXECUTE IMMEDIATE v_sql USING p_id;

    -- Check if any rows were deleted
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No record found with ID ' || p_id || ' in ' || v_table_name || '. Deletion was not performed.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Record with ID ' || p_id || ' has been deleted from ' || v_table_name || '.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO before_delete;
        RAISE; 
END;
/





--enable on delete cascade to handle the child record deletion--

ALTER TABLE Employee_info DROP CONSTRAINT fk_Employee_Department;

ALTER TABLE Student_counseling DROP CONSTRAINT fk_Student_Admission;

ALTER TABLE Student_performance DROP CONSTRAINT fk_Student_performance_Student;


ALTER TABLE Employee_info
ADD CONSTRAINT fk_Employee_Department FOREIGN KEY (Department_ID)
REFERENCES Department_info (Department_ID) ON DELETE CASCADE;

ALTER TABLE Student_counseling
ADD CONSTRAINT fk_Student_Admission FOREIGN KEY (Department_Admission)
REFERENCES Department_info (Department_ID) ON DELETE CASCADE;

ALTER TABLE Student_performance
ADD CONSTRAINT fk_Student_performance_Student FOREIGN KEY (Student_ID)
REFERENCES Student_counseling (Student_ID) ON DELETE CASCADE;






--Execution--
--Prompt user to choose the table--
ACCEPT v_choice NUMBER PROMPT 'Choose the table to delete from: 1. Department_info, 2. Employee_info, 3. Student_counseling, 4. Student_performance: '

--Validate the choice and proceed only if it's valid--
DECLARE
    v_choice NUMBER := &v_choice;
BEGIN
    IF v_choice NOT IN (1, 2, 3, 4) THEN
        DBMS_OUTPUT.PUT_LINE('Invalid choice. Please choose a valid option (1-4).');
        RAISE_APPLICATION_ERROR(-20001, 'Invalid choice.');
    END IF;
END;
/

--If the choice is valid, prompt for the corresponding ID--
ACCEPT v_id CHAR PROMPT 'Enter the corresponding ID to delete: '

--Execute the delete procedure with the provided inputs--
DECLARE
    v_choice NUMBER := &v_choice;
    v_id VARCHAR2(255) := '&v_id';
BEGIN
    delete_from_chosen_table(p_choice => v_choice, p_id => v_id);
END;
/


-- DATA ANALYSIS PART

-- 3.1.1 Find failing students 
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

-- 3.1.2 Find average marks 
-- This script allows user to input the student ID, semester name or paper name to query the average marks of the student, semester or paper
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

-- 3.1.3 Find the number of employees and students in a department 
-- This script allows the user to input the department name to query the number of students and staff in the department
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE calculate_department_totals (
    p_department_name IN VARCHAR2 
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

-- 3.1.4 Find the average tenure of employees for each department 
-- Display average tenure of employees for each department (listed from logest to shortest)
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE calculate_avg_tenure IS
BEGIN
    FOR rec IN (
        SELECT d.Department_Name, 
               AVG(MONTHS_BETWEEN(SYSDATE, e.DOJ) / 12) AS Average_Tenure_Years
        FROM Employee_info e
        JOIN Department_info d ON e.Department_ID = d.Department_ID
        GROUP BY d.Department_Name
        ORDER BY AVG(MONTHS_BETWEEN(SYSDATE, e.DOJ) / 12) DESC
    ) LOOP
        -- Display the results with formatted average tenure
        DBMS_OUTPUT.PUT_LINE('Department Name: ' || rec.Department_Name || 
                             ' - Average Tenure: ' || 
                             TO_CHAR(rec.Average_Tenure_Years, 'FM999990.00') || ' years');
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No records found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

-- Execute the procedure
BEGIN
    calculate_avg_tenure;
END;
/


-- 3.1.5 Find the ratio of employees and student for each department 
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


-- 3.1.6 Find top 10 department 
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


-- 3.1.7 Find department growth over time 

SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE find_department_growth_over_time IS
BEGIN
    FOR rec IN (
        SELECT d.Department_Name,
               TO_CHAR(e.DOJ, 'YYYY') AS Year,
               COUNT(DISTINCT e.Employee_ID) AS Employee_Count,
               COUNT(DISTINCT sc.Student_ID) AS Student_Count
        FROM Department_info d
        LEFT JOIN Employee_info e ON d.Department_ID = e.Department_ID  
        LEFT JOIN Student_counseling sc ON d.Department_ID = sc.Department_Choices  
        GROUP BY d.Department_Name, TO_CHAR(e.DOJ, 'YYYY')
        ORDER BY d.Department_Name, Year
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Department: ' || rec.Department_Name ||
                             ' | Year: ' || rec.Year ||
                             ' | Employee Count: ' || rec.Employee_Count ||
                             ' | Student Count: ' || rec.Student_Count);
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No records found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

BEGIN
    find_department_growth_over_time;
END;
/



-- 3.1.8 Find student counseling needs by department 
SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE find_student_counseling_needs IS
BEGIN
    FOR rec IN (
        SELECT d.Department_Name AS Department_Name,
               COUNT(sc.Student_ID) AS Number_of_Students
        FROM Student_counseling sc
        JOIN Department_info d ON sc.Department_Admission = d.Department_ID
        GROUP BY d.Department_Name
        ORDER BY Number_of_Students DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Department: ' || rec.Department_Name || 
                             ' | Number of Students: ' || rec.Number_of_Students);
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No records found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/
BEGIN
    find_student_counseling_needs;
END;
/





