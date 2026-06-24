--- 1. Which departments are over-budgeted based on job salary bands?
	--- Compare actual salary cost vs expected budget based on job min/max salary

WITH department_budget AS ( 
SELECT
    d.department_id,
	d.department_name,
	COUNT(e.employee_id) AS employee_count,
	ROUND(SUM(e.salary)) AS actual_salary_cost,
	ROUND(MIN(j.min_salary)) AS minimum_expected_budget,
	ROUND(MAX(j.min_salary)) AS maximum_expected_budget,
	ROUND(SUM((j.min_salary + j.max_salary) / 2)) AS planned_budget
FROM employees AS e
LEFT JOIN departments AS d 
	ON e.department_id = d.department_id
LEFT JOIN jobs AS j
	ON e.job_id = j.job_id
GROUP BY
	d.department_id,
	d.department_name
)
SELECT
	department_id,
    department_name,
    employee_count,
    actual_salary_cost,
    planned_budget,
    actual_salary_cost - planned_budget AS budget_difference,
CASE 
	WHEN actual_salary_cost > planned_budget THEN 'Over Budget'
    WHEN actual_salary_cost < planned_budget THEN 'Under Budget'
    ELSE 'On Budget'
END AS budget_status
FROM department_budget
ORDER BY budget_difference DESC;

--- 2. Which employees are paid above the average salary of their own department?

WITH department_avg AS (
SELECT
d.department_id,
ROUND(AVG(e.salary)) AS avg_department_salary
FROM employees AS e
LEFT JOIN departments AS d
	ON e.department_id = d.department_id
GROUP BY d.department_id
)
SELECT
e. employee_id,
CONCAT(e.first_name, ' ' , e.last_name) AS employee_name,
e.salary AS employee_salary,
ROUND(da.avg_department_salary,2) AS avg_department_salary,
ROUND(e.salary - da.avg_department_salary, 2) AS difference
FROM employees AS e
LEFT JOIN department_avg AS da
	ON e.department_id = da.department_id
WHERE e.salary > da.avg_department_salary
ORDER BY difference DESC;


--- 3. Which countries have the highest salary cost?

SELECT
r.region_name,
c.country_name,
COUNT(e.employee_id) AS employee_count,
ROUND(SUM(e.salary)) AS total_salary_cost,
ROUND(AVG(e.salary)) AS avg_salary_cost
FROM employees AS e
LEFT JOIN departments AS d
	ON e.department_id = d.department_id
LEFT JOIN locations AS l
	ON d.location_id = l.location_id
LEFT JOIN countries AS c
	ON l.country_id = c.country_id
LEFT JOIN regions AS r
	ON c.region_id = r.region_id
GROUP BY
	r.region_name,
	c.country_name
ORDER BY total_salary_cost DESC;

--- 4. Which departments have the highest percentage of high earners?

WITH company_avg AS (
SELECT
AVG(salary) AS avg_salary_cost
FROM employees
)
SELECT
d.department_name,
COUNT(e.employee_id) AS employee_count,
SUM(CASE WHEN e.salary > ca.avg_salary_cost THEN 1 ELSE 0 END) AS high_earners,
ROUND (
	100 * SUM(CASE WHEN e.salary > ca.avg_salary_cost THEN 1 ELSE 0 END) / COUNT(e.employee_id)
    ,2) AS high_earners_percentage
FROM employees AS e
LEFT JOIN departments AS d
	ON e.department_id = d.department_id
CROSS JOIN company_avg AS ca
GROUP BY d.department_name
ORDER BY high_earners_percentage DESC;

--- 5. Which managers control the largest salary cost?
SELECT
    m.employee_id AS manager_id,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    COUNT(e.employee_id) AS team_size,
    SUM(e.salary) AS team_salary_cost,
    ROUND(AVG(e.salary), 2) AS average_team_salary
FROM employees AS e
JOIN employees AS m
    ON e.manager_id = m.employee_id
GROUP BY m.employee_id, manager_name
ORDER BY team_salary_cost DESC;


--- 6. Which departments are the most expensive relative to their size?
SELECT
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    SUM(e.salary) AS total_salary_cost,
    ROUND(AVG(e.salary), 2) AS salary_cost_per_employee
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY salary_cost_per_employee DESC;

--- 7. Which departments depend too much on senior employees?

SELECT
    d.department_name,
    COUNT(e.employee_id) AS total_employees,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE())), 2) AS avg_years_in_company,
    SUM(CASE 
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) >= 10 
        THEN 1 ELSE 0 
    END) AS senior_employees
FROM employees AS e
JOIN departments AS d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY senior_employees DESC;


--- 8. Which job roles create the biggest salary pressure?

SELECT
    j.job_title,
    COUNT(e.employee_id) AS employees_in_role,
    SUM(e.salary) AS total_salary_cost,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    ROUND(AVG(j.max_salary), 2) AS job_max_salary,
    ROUND(AVG(e.salary / j.max_salary) * 100, 2) AS avg_pct_of_max_salary
FROM employees AS e
JOIN jobs AS j
    ON e.job_id = j.job_id
GROUP BY j.job_title
ORDER BY avg_pct_of_max_salary DESC;

--- 9. Which departments would save the most money if salaries were brought back to the midpoint of each job range?

WITH salary_midpoint AS (
    SELECT
        e.employee_id,
        e.department_id,
        e.salary,
        ((j.min_salary + j.max_salary) / 2) AS midpoint_salary
    FROM employees AS e
    JOIN jobs AS j
        ON e.job_id = j.job_id
)
SELECT
    d.department_name,
    COUNT(sm.employee_id) AS employee_count,
    SUM(sm.salary) AS actual_salary_cost,
    SUM(sm.midpoint_salary) AS target_salary_cost,
    ROUND(SUM(sm.salary - sm.midpoint_salary), 2) AS potential_saving,
    CASE
        WHEN SUM(sm.salary) > SUM(sm.midpoint_salary) THEN 'Above Target'
        WHEN SUM(sm.salary) < SUM(sm.midpoint_salary) THEN 'Below Target'
        ELSE 'On Target'
    END AS target_status
FROM salary_midpoint AS sm
JOIN departments AS d
    ON sm.department_id = d.department_id
GROUP BY d.department_name
ORDER BY potential_saving DESC;

--- 10. Which departments rely too heavily on a single manager?
WITH manager_team_size AS (
    SELECT
        e.manager_id,
        COUNT(e.employee_id) AS team_size
    FROM employees e
    WHERE e.manager_id IS NOT NULL
    GROUP BY e.manager_id
)
SELECT
    m.employee_id AS manager_id,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    d.department_name,
    mts.team_size,
    CASE
        WHEN mts.team_size >= 50 THEN 'High Manager Dependency'
        WHEN mts.team_size >= 20 THEN 'Medium Manager Dependency'
        ELSE 'Normal Manager Dependency'
    END AS dependency_level
FROM manager_team_size mts
JOIN employees AS m
    ON mts.manager_id = m.employee_id
JOIN departments AS d
    ON m.department_id = d.department_id
ORDER BY mts.team_size DESC;