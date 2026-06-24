--- Employee & Workforce Basics


--- 1. How many employees and in the company?
SELECT 
	COUNT(DISTINCT employee_id) AS total_employees
FROM employees;

--- 2. Provide a list of the top 10 highest-paid employees (name and salary).
SELECT 
	COUNT(DISTINCT employee_id) AS total_employees,
	salary
FROM employees
ORDER BY salary DESC
LIMIT 10;

--- 3. What are all the distinct job titles in the organization?
SELECT DISTINCT job_title AS unique_job_title
FROM jobs;

---- 4. How many employees are in each department?

SELECT 
	d.department_name,
	COUNT(DISTINCT e.employee_id) AS total_employees
	FROM employees AS e
LEFT JOIN departments AS d
	ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY total_employees DESC;

---- 5. Find the longest and newest employee (in years)
(
    SELECT
        'Longest Serving' AS employee_type,
        CONCAT(first_name, ' ', last_name) AS employee_name,
        hire_date,
        TIMESTAMPDIFF(YEAR, hire_date, CURDATE()) AS years_in_company
    FROM employees
    ORDER BY hire_date ASC
    LIMIT 1
)
UNION ALL
(
    SELECT
        'Newest Employee' AS employee_type,
        CONCAT(first_name, ' ', last_name) AS employee_name,
        hire_date,
        TIMESTAMPDIFF(YEAR, hire_date, CURDATE()) AS years_in_company
    FROM employees
    ORDER BY hire_date DESC
    LIMIT 1
);


--- 6. Who are the five longest-serving employees (earliest hire dates)?
SELECT
	CONCAT(first_name, ' ', last_name) AS employee_name,
	hire_date,
TIMESTAMPDIFF(YEAR, hire_date, CURDATE()) AS years_in_company
FROM employees
ORDER BY hire_date ASC
LIMIT 5;

--- 7. Which department has the largest number of employees?

SELECT 
	d.department_name,
	COUNT(DISTINCT e.employee_id) AS total_employees
FROM employees AS e
LEFT JOIN departments AS d
	ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY total_employees DESC
LIMIT 1;

--- 8. Which departments have the highest average salary?
SELECT 
	d.department_name,
	ROUND(AVG(e.salary),2) AS average_salary
FROM employees AS e
LEFT JOIN departments AS d
	ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY average_salary DESC
;


--- Salary & Contribution

--- 9. What is the minimum, maximum, and average salary across the company?

SELECT
	MIN(salary) AS min_salary,
	MAX(salary) AS max_salary,
	ROUND(AVG(salary)) AS avg_salary
FROM employees;

--- 10. Who are the top 5 highest-paid employees?
SELECT
	CONCAT(first_name, ' ', last_name) AS employee_name,
	salary
FROM employees
ORDER BY salary DESC
LIMIT 5;

--- 11. How many employees earn more than €10,000?
SELECT
	COUNT(DISTINCT employee_id) AS total_employees
FROM employees
WHERE salary > 10000
;

--- 12. What is the total annual payroll cost for each department?
SELECT
	d.department_name,
	COUNT(e.employee_id) AS total_headcount,
	SUM(e.salary) AS total_annual_payroll
FROM employees AS e
LEFT JOIN departments AS d
	ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY total_annual_payroll DESC;

--- 13. Which employees earn above the company-wide average salary?
SELECT 
	employee_id,
	first_name,
	last_name,
	salary
FROM employees
WHERE salary > (
SELECT 
	ROUND(AVG(salary)) AS avg_salary
FROM employees)
;

--- 14. Are there any employees whose current salary is closest to the maximum defined for their job title?
SELECT
	e.employee_id,
	CONCAT(e.first_name,' ',e.last_name) AS employee_name,
	e.salary,
	j.max_salary,
	ROUND(e.salary / j.max_salary * 100,2) AS pct_of_max_salary
FROM employees e
JOIN jobs j
    ON e.job_id = j.job_id
ORDER BY pct_of_max_salary DESC;

