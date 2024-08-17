SET SERVEROUTPUT ON SIZE UNLIMITED;

CREATE OR REPLACE PROCEDURE department_growth_over_time IS
BEGIN
    FOR rec IN (
        SELECT d.Department_ID,
               TO_CHAR(e.DOJ, 'YYYY') AS Year,
               COUNT(e.Employee_ID) AS Employee_Count,
               COUNT(sc.Student_ID) AS Student_Count
        FROM Department_info d
        LEFT JOIN Employee_info e ON d.Department_ID = e.Department_ID
            AND e.DOJ IS NOT NULL
        LEFT JOIN Student_counseling sc ON d.Department_ID = sc.Department_Choices
            AND sc.DOA IS NOT NULL
        GROUP BY d.Department_ID, TO_CHAR(e.DOJ, 'YYYY')
        ORDER BY d.Department_ID, Year
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Department ID: ' || rec.Department_ID || 
                             ' - Year: ' || rec.Year || 
                             ' - Number of Employees: ' || rec.Employee_Count || 
                             ', Number of Students: ' || rec.Student_Count);
    END LOOP;
END;
/

BEGIN
    department_growth_over_time;
END;
/

