-- INSERT DATA INTO DEPARTMENT INFO WITH TRANSACTION MANAGEMENT --

CREATE OR REPLACE PROCEDURE insert_department_info (
    p_department_id            IN VARCHAR2,
    p_department_name          IN VARCHAR2,
    p_doe                     IN DATE
) IS
    savepoint_name VARCHAR2(20) := 'sp_insert_department';
BEGIN
    SAVEPOINT savepoint_name;
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
        ROLLBACK TO savepoint_name;
        DBMS_OUTPUT.PUT_LINE('Error: Department_ID already exists.');
    WHEN OTHERS THEN
        ROLLBACK TO savepoint_name;
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
    savepoint_name VARCHAR2(20) := 'sp_insert_employee';
BEGIN
    SAVEPOINT savepoint_name;
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
        ROLLBACK TO savepoint_name;
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
    savepoint_name VARCHAR2(40) := 'sp_insert_student_counseling';
BEGIN
    SAVEPOINT savepoint_name;
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
    savepoint_name VARCHAR2(40) := 'sp_insert_student_performance';
BEGIN
    SAVEPOINT savepoint_name;
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

-- DISPLAY DATA --

SELECT * FROM Department_info;
SELECT * FROM Employee_info;
SELECT * FROM Student_counseling;
SELECT * FROM Student_performance;
/
