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
