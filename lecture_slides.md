# 📊 Advanced SQL for Data Engineering
## Lecture Slides (2 Hours)

---

# 📋 Course Overview

## What We'll Learn Today
- ⏱️ **Duration**: 2 Hours
- 🎯 **Main Focus** (90 min): JOINs, Subqueries & CTEs
- 🌟 **Bonus** (30 min): Introduction to Window Functions

## Why This Matters for Data Engineering?
- 🔄 **ETL/ELT Pipelines**: Transform and combine data from multiple sources
- 📊 **Data Transformation**: Build clean, maintainable queries
- 🛠️ **Modern Tools**: Used in dbt, Airflow, data warehouses
- 💼 **Real World**: 90% of data engineering is combining & transforming data

---

# 📊 Dataset: HR Analytics

## About the Data
- **Source**: IBM HR Analytics Employee Attrition Dataset
- **Records**: 1,470 employees
- **Goal**: Analyze employee attrition (turnover)
- **Attrition Rate**: 16.1% (237/1,470 employees left)

## Database Schema (6 Tables)
```
departments (3 departments)
├── job_roles (31 positions)
│   └── employees (1,470 people)
│       ├── employee_compensation (salary, bonuses)
│       ├── employee_satisfaction (ratings 1-4)
│       └── employee_work_history (tenure, attrition)
```

---

# 🔑 Key Tables

## Core Tables
1. **departments**: 3 departments (R&D, Sales, HR)
2. **job_roles**: 31 positions with job_level (1-5)
3. **employees**: Personal info (age, gender, education)
4. **employee_compensation**: Salary data
5. **employee_satisfaction**: Ratings (environment, job, work-life balance)
6. **employee_work_history**: Tenure, overtime, **attrition** ⭐

## Important Fields
- `monthly_income`: 1,009 - 19,999
- `job_satisfaction`: 1-4 scale
- `years_at_company`: 0-40 years
- `over_time`: Yes/No (major attrition factor!)
- `attrition`: Yes/No (TARGET VARIABLE)

---

# 📖 MAIN FOCUS (90 min): JOINs, Subqueries & CTEs

---

# 🔍 Setup & Review (10 min)

## Quick Check ✅
1. Database imported successfully?
2. Can you run basic queries?
3. Familiar with GROUP BY and aggregate functions?

## Test Query
```sql
-- Count employees by department
SELECT d.department_name, COUNT(*) as employee_count
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name;
```

## Schema Exploration
```sql
-- Preview data
SELECT * FROM employees LIMIT 5;
```

---

# 🔗 Multi-table JOINs (20 min)

## Why JOINs in Data Engineering?
- Combine data from multiple sources
- Data warehouses have normalized schemas
- Real-world queries need 3+ table joins

## Basic JOIN Review
```sql
-- INNER JOIN: Only matching rows
SELECT e.employee_id, d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;

-- LEFT JOIN: Keep all from left table
SELECT e.employee_id, d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;
```

---

# 🔗 JOIN 3+ Tables

## Real-World Example
```sql
-- Analyze salary and attrition by department
SELECT 
    d.department_name,
    COUNT(*) as total_employees,
    AVG(c.monthly_income) as avg_salary,
    COUNT(CASE WHEN w.attrition = 'Yes' THEN 1 END) as attrition_count,
    ROUND(COUNT(CASE WHEN w.attrition = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) as attrition_rate
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_compensation c ON e.employee_id = c.employee_id
JOIN employee_work_history w ON e.employee_id = w.employee_id
GROUP BY d.department_name
ORDER BY attrition_rate DESC;
```

Note: JOIN = INNER JOIN

## Output Example
```
department_name          | total_employees | avg_salary | attrition_count | attrition_rate
-------------------------+-----------------+------------+-----------------+----------------
Sales                    |      446        |    6959    |       92        |     20.63
Human Resources          |       63        |    6653    |       12        |     19.05
Research & Development   |      961        |    6868    |      133        |     13.84
```

---

# 🔗 JOIN Exercise

## 🎯 Your Turn!
Join 4 tables to find:
- Employee age
- Department name
- Monthly income
- Job satisfaction
- Attrition status

```sql
-- Template
SELECT 
    e.employee_id,
    e.age,
    d.department_name,
    c.monthly_income,
    s.job_satisfaction,
    w.attrition
FROM employees e
JOIN __________ d ON __________
JOIN __________ c ON __________
JOIN __________ s ON __________
JOIN __________ w ON __________
LIMIT 10;
```

---

# 📦 Subqueries (15 min)

## What are Subqueries?
- Query inside another query
- Used for filtering, calculations, or data preparation
- Can be in WHERE, SELECT, or FROM clause

## Subquery in WHERE
```sql
-- Find employees earning above their department's average
SELECT 
    e.employee_id,
    d.department_name,
    c.monthly_income,
    (SELECT AVG(c2.monthly_income)
     FROM employees e2
     JOIN employee_compensation c2 ON e2.employee_id = c2.employee_id
     WHERE e2.department_id = e.department_id) as dept_avg_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_compensation c ON e.employee_id = c.employee_id
WHERE c.monthly_income > (
    SELECT AVG(c2.monthly_income)
    FROM employees e2
    JOIN employee_compensation c2 ON e2.employee_id = c2.employee_id
    WHERE e2.department_id = e.department_id
);
```

---

# 📦 Subquery in FROM

## Creating Derived Tables
```sql
-- Compare attrition vs non-attrition groups
-- Using subquery to pre-aggregate data before final calculation
SELECT 
    attrition_status,
    COUNT(*) as employee_count,
    ROUND(AVG(avg_income), 2) as avg_monthly_income,
    ROUND(AVG(avg_satisfaction), 2) as avg_job_satisfaction,
    ROUND(AVG(avg_work_life), 2) as avg_work_life_balance
FROM (
    -- Inner query: Get individual employee metrics with their attrition status
    SELECT 
        CASE 
            WHEN w.attrition = 'Yes' THEN 'Left Company'
            ELSE 'Still Working'
        END as attrition_status,
        c.monthly_income as avg_income,
        s.job_satisfaction as avg_satisfaction,
        s.work_life_balance as avg_work_life
    FROM employees e
    JOIN employee_compensation c ON e.employee_id = c.employee_id
    JOIN employee_satisfaction s ON e.employee_id = s.employee_id
    JOIN employee_work_history w ON e.employee_id = w.employee_id
) AS employee_data
GROUP BY attrition_status
ORDER BY attrition_status;
```

## Expected Output (Same as Before!)
```
attrition_status | employee_count | avg_monthly_income | avg_job_satisfaction | avg_work_life_balance
-----------------+----------------+--------------------+----------------------+-----------------------
Left Company     |      237       |      4787.09       |         2.47         |         2.66
Still Working    |     1233       |      6832.74       |         2.78         |         2.78
```

## Problem with Subqueries
❌ Hard to read  
❌ Can't reference multiple times  
❌ Difficult to debug  

✅ **Solution: Use CTEs!**

---

# 📝 Common Table Expressions (CTEs) (45 min)

## What are CTEs?
- **WITH clause** creates temporary named result sets
- Makes complex queries readable and maintainable
- Perfect for data pipelines and transformations
- **Most important skill for Data Engineering!**

## CTE Syntax
```sql
WITH cte_name AS (
    -- Your query here
    SELECT ...
)
SELECT * FROM cte_name;
```

## Why CTEs for Data Engineering?
✅ **Readable**: Break complex logic into steps  
✅ **Reusable**: Reference the same CTE multiple times  
✅ **Testable**: Test each CTE independently  
✅ **Used in dbt**: Modern data transformation tool (95% of dbt models use CTEs)
✅ **Industry Standard**: Preferred over subqueries in production code

---

# 📝 Basic CTE Example

## Analyzing Attrition Factors
```sql
-- Step 1: Calculate attrition statistics
WITH attrition_stats AS (
    SELECT 
        w.attrition,
        COUNT(*) as employee_count,
        AVG(c.monthly_income) as avg_income,
        AVG(s.job_satisfaction) as avg_satisfaction,
        AVG(s.work_life_balance) as avg_work_life_balance
    FROM employees e
    JOIN employee_compensation c ON e.employee_id = c.employee_id
    JOIN employee_satisfaction s ON e.employee_id = s.employee_id
    JOIN employee_work_history w ON e.employee_id = w.employee_id
    GROUP BY w.attrition
)
SELECT 
    attrition,
    employee_count,
    ROUND(avg_income, 2) as avg_income,
    ROUND(avg_satisfaction, 2) as avg_satisfaction,
    ROUND(avg_work_life_balance, 2) as avg_work_life_balance
FROM attrition_stats;
```

## Expected Output
```
attrition | employee_count | avg_income | avg_satisfaction | avg_work_life_balance
----------+----------------+------------+------------------+-----------------------
No        |     1233       |  6832.74   |      2.78        |         2.78
Yes       |      237       |  4787.09   |      2.47        |         2.66
```

---

# 📝 Multiple CTEs

## Data Pipeline Pattern
```sql
WITH 
-- Step 1: Get base employee data
employee_base AS (
    SELECT 
        e.employee_id,
        e.age,
        d.department_name,
        c.monthly_income,
        w.attrition,
        w.over_time
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN employee_compensation c ON e.employee_id = c.employee_id
    JOIN employee_work_history w ON e.employee_id = w.employee_id
),
-- Step 2: Calculate department averages
dept_averages AS (
    SELECT 
        department_name,
        AVG(monthly_income) as dept_avg_salary
    FROM employee_base
    GROUP BY department_name
),
-- Step 3: Overtime analysis
overtime_impact AS (
    SELECT 
        over_time,
        COUNT(*) as total,
        COUNT(CASE WHEN attrition = 'Yes' THEN 1 END) as attrition_count,
        ROUND(COUNT(CASE WHEN attrition = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) as attrition_rate
    FROM employee_base
    GROUP BY over_time
)
-- Final: Combine insights
SELECT * FROM overtime_impact
ORDER BY attrition_rate DESC;
```

---

# 📝 CTE for Data Transformation

## Creating a Clean Dataset
```sql
WITH cleaned_data AS (
    SELECT 
        e.employee_id,
        e.age,
        CASE 
            WHEN e.age < 25 THEN 'Under 25'
            WHEN e.age BETWEEN 25 AND 35 THEN '25-35'
            WHEN e.age BETWEEN 36 AND 45 THEN '36-45'
            ELSE 'Over 45'
        END as age_group,
        d.department_name,
        c.monthly_income,
        CASE 
            WHEN c.monthly_income < 3000 THEN 'Low'
            WHEN c.monthly_income BETWEEN 3000 AND 6000 THEN 'Medium'
            WHEN c.monthly_income BETWEEN 6001 AND 10000 THEN 'High'
            ELSE 'Very High'
        END as income_bracket,
        s.job_satisfaction,
        w.over_time,
        w.attrition
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN employee_compensation c ON e.employee_id = c.employee_id
    JOIN employee_satisfaction s ON e.employee_id = s.employee_id
    JOIN employee_work_history w ON e.employee_id = w.employee_id
)
-- Analyze by age group and income bracket
SELECT 
    age_group,
    income_bracket,
    COUNT(*) as employee_count,
    COUNT(CASE WHEN attrition = 'Yes' THEN 1 END) as attrition_count,
    ROUND(AVG(job_satisfaction), 2) as avg_satisfaction
FROM cleaned_data
GROUP BY age_group, income_bracket
ORDER BY age_group, income_bracket;
```

---

# 🎯 CTE Exercise

## Your Turn: Build a Data Pipeline!

Create a CTE pipeline to find:
1. Employees who work overtime
2. Calculate their average salary vs non-OT employees
3. Show attrition rate for each group

```sql
WITH overtime_employees AS (
    -- Step 1: Your code here
    SELECT ...
),
salary_comparison AS (
    -- Step 2: Your code here
    SELECT ...
)
-- Step 3: Final query
SELECT * FROM salary_comparison;
```

---

# ⏸️ Main Focus Summary (90 min)

## What We Learned
✅ **Multi-table JOINs** (20 min): Combine 3+ tables for complete data views
✅ **Subqueries** (15 min): Nested queries for filtering and calculations  
✅ **CTEs** (45 min): Industry-standard for readable, maintainable pipelines

## 🎯 Critical Takeaways for Data Engineers
1. **JOINs** = 50% of your daily work - master them!
2. **CTEs** = Used in every dbt model, every data pipeline
3. **Code Quality** = Readable queries = Maintainable systems
4. **Think in Steps** = Break complex logic into smaller CTEs

## Real-World Impact
- 📊 **dbt models**: All use CTEs for transformation
- 🔄 **ETL pipelines**: Join data from multiple sources
- 🏗️ **Data Warehouses**: Star schema requires complex JOINs
- 👥 **Team Collaboration**: CTEs make code reviewable

---

---

# 🌟 BONUS (30 min): Introduction to Window Functions

---

# 🪟 Window Functions Overview (5 min)

## What are Window Functions?
- Perform calculations **across rows** related to the current row
- Unlike GROUP BY, they **don't collapse rows**
- Essential for analytics: rankings, running totals, moving averages

## Why Learn This? (Brief intro)
- Used in advanced analytics
- Common in BI dashboards
- Requested in senior data engineer interviews
- Today: Quick introduction to core concepts

---

# 🪟 Window Functions vs GROUP BY (5 min)

### GROUP BY Example
```sql
-- Returns 3 rows (one per department)
SELECT department_id, AVG(monthly_income)
FROM employees e
JOIN employee_compensation c ON e.employee_id = c.employee_id
GROUP BY department_id;
```

### Window Function Example
```sql
-- Returns ALL rows (1,470) with department average added
SELECT 
    e.employee_id,
    e.department_id,
    c.monthly_income,
    AVG(c.monthly_income) OVER (PARTITION BY e.department_id) as dept_avg_salary
FROM employees e
JOIN employee_compensation c ON e.employee_id = c.employee_id;
```

---

# 🪟 Window Function Syntax

## Basic Structure
```sql
function_name() OVER (
    [PARTITION BY column]
    [ORDER BY column]
    [ROWS/RANGE BETWEEN ...]
)
```

## Components
- **Function**: ROW_NUMBER(), RANK(), SUM(), AVG(), etc.
- **OVER**: Defines the window
- **PARTITION BY**: Divide data into groups (like GROUP BY)
- **ORDER BY**: Order within each partition
- **Frame**: Define which rows to include (optional)

---

# 🏆 Ranking Functions - Quick Demo (10 min)

## Most Common: ROW_NUMBER()

**Use Case**: Find Top N in each group (very common in data engineering!)

1. **ROW_NUMBER()**: Unique sequential number (1, 2, 3, 4...)
2. **RANK()**: Same rank for ties, skips next (1, 2, 2, 4...)
3. **NTILE(n)**: Divide into n equal buckets (quartiles, deciles)

## Visual Example
```
Salary  | ROW_NUMBER | RANK | DENSE_RANK
--------+------------+------+------------
10000   |     1      |  1   |     1
9000    |     2      |  2   |     2
9000    |     3      |  2   |     2
8000    |     4      |  4   |     3
7000    |     5      |  5   |     4
```

---

# 🏆 ROW_NUMBER() Example

## Ranking Employees by Salary
```sql
SELECT 
    e.employee_id,
    d.department_name,
    c.monthly_income,
    ROW_NUMBER() OVER (
        PARTITION BY d.department_id 
        ORDER BY c.monthly_income DESC
    ) as salary_rank_in_dept,
    ROW_NUMBER() OVER (
        ORDER BY c.monthly_income DESC
    ) as salary_rank_overall
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_compensation c ON e.employee_id = c.employee_id
LIMIT 10;
```

## Output
```
employee_id | department_name         | monthly_income | salary_rank_in_dept | salary_rank_overall
------------+-------------------------+----------------+---------------------+--------------------
1923        | Research & Development  |     19999      |          1          |          1
1902        | Sales                   |     19973      |          1          |          2
1035        | Research & Development  |     19943      |          2          |          3
```

---

# 🏆 Finding Top N per Group

## Top 3 Highest Paid in Each Department
```sql
WITH ranked_employees AS (
    SELECT 
        e.employee_id,
        d.department_name,
        c.monthly_income,
        ROW_NUMBER() OVER (
            PARTITION BY d.department_id 
            ORDER BY c.monthly_income DESC
        ) as rank_in_dept
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN employee_compensation c ON e.employee_id = c.employee_id
)
SELECT 
    department_name,
    employee_id,
    monthly_income,
    rank_in_dept
FROM ranked_employees
WHERE rank_in_dept <= 3
ORDER BY department_name, rank_in_dept;
```

## Use Case in Data Engineering
- Top N products by revenue per category
- Top N customers by spend per region
- Top N performing ads per campaign

---

# 🏆 NTILE() - Creating Buckets

## What is NTILE(n)?
- Divides rows into **n** equal groups
- Assigns bucket number (1 to n)
- Perfect for quartiles, deciles, percentiles

## Salary Quartiles Example
```sql
SELECT 
    e.employee_id,
    c.monthly_income,
    NTILE(4) OVER (ORDER BY c.monthly_income) as income_quartile,
    CASE 
        WHEN NTILE(4) OVER (ORDER BY c.monthly_income) = 1 THEN 'Q1 - Lowest 25%'
        WHEN NTILE(4) OVER (ORDER BY c.monthly_income) = 2 THEN 'Q2 - Lower Middle'
        WHEN NTILE(4) OVER (ORDER BY c.monthly_income) = 3 THEN 'Q3 - Upper Middle'
        ELSE 'Q4 - Highest 25%'
    END as income_bracket
FROM employees e
JOIN employee_compensation c ON e.employee_id = c.employee_id
ORDER BY c.monthly_income;
```

---

# 🏆 NTILE() - Dividing into Buckets (Optional Demo)

## Quick Example: Salary Quartiles
```sql
WITH income_quartiles AS (
    SELECT 
        e.employee_id,
        c.monthly_income,
        NTILE(4) OVER (ORDER BY c.monthly_income) as income_quartile
    FROM employees e
    JOIN employee_compensation c ON e.employee_id = c.employee_id
)
SELECT 
    income_quartile,
    COUNT(*) as total_employees,
    ROUND(AVG(monthly_income), 2) as avg_income
FROM income_quartiles
GROUP BY income_quartile
ORDER BY income_quartile;
```

## Use Case
- Divide customers into spending tiers
- Performance quartiles
- A/B test cohorts

---

# 📊 Aggregate Window Functions - Quick Intro (10 min)

## Most Useful: AVG() OVER

**Use Case**: Compare individual values to group average

```sql
-- Compare each employee to their department average
SELECT 
    e.employee_id,
    d.department_name,
    c.monthly_income,
    ROUND(AVG(c.monthly_income) OVER (PARTITION BY d.department_id), 2) as dept_avg,
    ROUND(c.monthly_income - AVG(c.monthly_income) OVER (PARTITION BY d.department_id), 2) as diff_from_avg
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_compensation c ON e.employee_id = c.employee_id
ORDER BY d.department_name, diff_from_avg DESC;
```

## Key Concept
- **GROUP BY**: Collapses rows (3 departments = 3 rows)
- **Window Functions**: Keeps all rows (1,470 employees = 1,470 rows)

---

# 🌟 Window Functions - When to Use? (5 min)

## Common Use Cases
1. **Rankings**: Top N per category (ROW_NUMBER)
2. **Segmentation**: Divide into groups (NTILE)
3. **Comparisons**: Individual vs average (AVG OVER)
4. **Time Series**: Running totals, moving averages (SUM/AVG OVER with ORDER BY)

## In Data Engineering
- Analytics dashboards
- Report generation
- Data quality checks (outlier detection)
- Performance monitoring

## Learn More
- Today we covered basics (~20% of window functions)
- Practice: LeetCode SQL, Mode Analytics tutorials
- Advanced: LAG/LEAD, frame clauses (ROWS BETWEEN)

---

## Compare Each Employee to Department Average
```sql
SELECT 
    e.employee_id,
    d.department_name,
    c.monthly_income,
    ROUND(AVG(c.monthly_income) OVER (PARTITION BY d.department_id), 2) as dept_avg_salary,
    ROUND(c.monthly_income - AVG(c.monthly_income) OVER (PARTITION BY d.department_id), 2) as diff_from_avg,
    ROUND((c.monthly_income - AVG(c.monthly_income) OVER (PARTITION BY d.department_id)) * 100.0 / 
          AVG(c.monthly_income) OVER (PARTITION BY d.department_id), 2) as pct_diff_from_avg
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_compensation c ON e.employee_id = c.employee_id
ORDER BY d.department_name, pct_diff_from_avg DESC;
```

## Insights
- Employees earning significantly above/below department average
- Pay equity analysis
- Identify outliers

---

# 📊 Multiple Window Functions

## Comprehensive Employee Analytics
```sql
SELECT 
    e.employee_id,
    d.department_name,
    c.monthly_income,
    -- Department statistics
    ROUND(AVG(c.monthly_income) OVER (PARTITION BY d.department_id), 2) as dept_avg,
    MIN(c.monthly_income) OVER (PARTITION BY d.department_id) as dept_min,
    MAX(c.monthly_income) OVER (PARTITION BY d.department_id) as dept_max,
    -- Rankings
    RANK() OVER (PARTITION BY d.department_id ORDER BY c.monthly_income DESC) as dept_rank,
    NTILE(4) OVER (ORDER BY c.monthly_income) as company_quartile,
    -- Percentile position
    PERCENT_RANK() OVER (ORDER BY c.monthly_income) as percentile_rank
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_compensation c ON e.employee_id = c.employee_id
ORDER BY d.department_name, dept_rank;
```

---

# 🔍 Integration: CTEs + Window Functions (10 min)

## Real-World Data Engineering Example

### Goal: Identify High-Risk Employees
Criteria for "High Risk":
- Works overtime
- In lowest 50% of income (quartile 1-2)
- Job satisfaction below company average
- Less than 5 years at company

---

# 🔍 Complete Example

```sql
-- Build a comprehensive risk assessment model
WITH employee_metrics AS (
    -- Step 1: Gather all relevant metrics
    SELECT 
        e.employee_id,
        e.age,
        d.department_name,
        c.monthly_income,
        s.job_satisfaction,
        s.work_life_balance,
        w.years_at_company,
        w.over_time,
        w.attrition,
        -- Calculate percentiles and rankings
        NTILE(4) OVER (ORDER BY c.monthly_income) as income_quartile,
        ROUND(AVG(s.job_satisfaction) OVER (), 2) as company_avg_satisfaction,
        ROUND(AVG(c.monthly_income) OVER (PARTITION BY d.department_id), 2) as dept_avg_income
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN employee_compensation c ON e.employee_id = c.employee_id
    JOIN employee_satisfaction s ON e.employee_id = s.employee_id
    JOIN employee_work_history w ON e.employee_id = w.employee_id
),
risk_assessment AS (
    -- Step 2: Calculate risk scores
    SELECT 
        *,
        CASE 
            WHEN over_time = 'Yes' 
                AND income_quartile <= 2 
                AND job_satisfaction < company_avg_satisfaction 
                AND years_at_company < 5 
            THEN 'High Risk'
            WHEN (over_time = 'Yes' AND income_quartile <= 2)
                OR (job_satisfaction < company_avg_satisfaction AND years_at_company < 5)
            THEN 'Medium Risk'
            ELSE 'Low Risk'
        END as risk_level,
        -- Risk score (0-100)
        (CASE WHEN over_time = 'Yes' THEN 25 ELSE 0 END +
         CASE WHEN income_quartile <= 2 THEN 25 ELSE 0 END +
         CASE WHEN job_satisfaction < company_avg_satisfaction THEN 25 ELSE 0 END +
         CASE WHEN years_at_company < 5 THEN 25 ELSE 0 END) as risk_score
    FROM employee_metrics
    WHERE attrition = 'No'  -- Only current employees
)
-- Step 3: Summarize and prioritize
SELECT 
    risk_level,
    COUNT(*) as employee_count,
    ROUND(AVG(monthly_income), 2) as avg_income,
    ROUND(AVG(job_satisfaction), 2) as avg_satisfaction,
    ROUND(AVG(years_at_company), 2) as avg_tenure,
    ROUND(AVG(risk_score), 2) as avg_risk_score
FROM risk_assessment
GROUP BY risk_level
ORDER BY 
    CASE risk_level 
        WHEN 'High Risk' THEN 1 
        WHEN 'Medium Risk' THEN 2 
        ELSE 3 
    END;
```

---

# 🔍 Using the Results

## Output: Risk Summary
```
risk_level   | employee_count | avg_income | avg_satisfaction | avg_tenure | avg_risk_score
-------------+----------------+------------+------------------+------------+----------------
High Risk    |       45       |   4231.22  |       2.11       |    2.87    |     100.00
Medium Risk  |      312       |   5674.89  |       2.54       |    5.23    |      50.00
Low Risk     |      876       |   7456.33  |       3.12       |    8.45    |      25.00
```

## Business Actions
1. **High Risk**: Immediate intervention (raise, promotion, workload review)
2. **Medium Risk**: Regular check-ins, career development
3. **Low Risk**: Maintain satisfaction, retention programs

---

---

# 🎓 Course Summary

---

# ✅ What We Learned Today (2 Hours)

## Core Skills (90 min) - Master These! 🎯
- ✅ **Multi-table JOINs** (20 min): Combine data from multiple sources
- ✅ **Subqueries** (15 min): Nested queries for complex filtering
- ✅ **CTEs** (45 min): **Most important!** Readable, maintainable data pipelines

## Bonus Skills (30 min) - Good to Know 🌟
- ✅ **Window Functions Intro**: Rankings, comparisons, running totals
- ✅ **ROW_NUMBER()**: Top N per group
- ✅ **AVG() OVER**: Compare to group averages

---

# 🎯 What to Focus On First

## Priority 1: Master These (Week 1-2) 🔥
1. **JOINs**: Practice joining 3+ tables daily
2. **CTEs**: Rewrite every complex query using CTEs
3. **Think in Pipelines**: Break problems into steps

## Priority 2: Get Comfortable (Week 3-4)
4. **Window Functions**: Learn ROW_NUMBER() and NTILE()
5. **AVG() OVER**: Compare individuals to groups

## Priority 3: Advanced (Later)
6. LAG/LEAD functions
7. Frame clauses (ROWS BETWEEN)
8. Performance optimization

---

# 🛠️ Skills for Data Engineering

## Where You'll Use These Skills Daily

### 1. **ETL/ELT Pipelines** (Every Day!)
```sql
-- This is what you'll write in dbt, Airflow, etc.
WITH source_data AS (
    SELECT * FROM raw_tables  -- Extract
),
cleaned_data AS (
    SELECT ...  -- Transform step 1
),
enriched_data AS (
    SELECT ...  -- Transform step 2
    FROM cleaned_data
    JOIN dimension_table ...  -- JOINs!
),
final_data AS (
    SELECT ...  -- Final transformations
)
SELECT * FROM final_data;  -- Load
```

### 2. **dbt (Data Build Tool)** - Industry Standard
- Every dbt model is a CTE-based query
- JOINs to combine sources
- 95% of modern data teams use dbt
- **Master CTEs = Master dbt**

### 3. **Data Warehousing**
- Star schema queries require multiple JOINs
- Fact tables + Dimension tables
- Aggregate tables built with CTEs

### 4. **Ad-hoc Analysis**
- Business asks: "Why did sales drop?"
- You: Write queries with JOINs + CTEs to investigate
- Quick answers using Window Functions for rankings

---

# 📊 Key Concepts to Remember

## 1. JOINs - 50% of Your Work
- Combine data from multiple sources (databases, APIs, files)
- Use appropriate JOIN type (INNER = matching only, LEFT = keep all from left)
- Always specify join conditions clearly
- Practice joining 3+ tables until it's second nature

## 2. CTEs - Your Best Friend 💚
- **Always use CTEs** instead of nested subqueries in production
- Break complex logic into named steps
- Each CTE is a checkpoint you can test independently
- Makes code reviewable by teammates
- Industry standard in dbt, modern data platforms

## 3. Window Functions - Powerful but Learn Later
- Calculate across rows WITHOUT collapsing them
- Use when GROUP BY won't work (need row-level detail)
- Common: ROW_NUMBER() for Top N, NTILE() for segmentation
- Learn basics today, master with practice

---

# 🎯 Next Steps

## Practice This Week (Critical!) 🔥
1. **Rewrite 3 queries** from past projects using CTEs
2. **Join 3+ tables** in every practice query
3. **Break down** any complex query into CTEs
4. **Explain your code** out loud - if you can't explain it, simplify it

## Learn More - Recommended Order
1. **Week 1-2**: Master JOINs + CTEs
   - Practice on LeetCode SQL (Easy/Medium)
   - Rewrite old queries with CTEs
   
2. **Week 3-4**: Practice Window Functions
   - Mode SQL Tutorial: https://mode.com/sql-tutorial/
   - Focus on ROW_NUMBER(), NTILE(), AVG() OVER
   
3. **Month 2+**: Advanced Topics
   - LAG/LEAD functions
   - Frame clauses
   - Query optimization

## Real-World Tools to Explore
- **dbt**: Free dbt Cloud account - practice CTEs!
- **PostgreSQL/MySQL**: Set up local database
- **Kaggle**: Find datasets to practice on
- **LeetCode SQL**: 50+ problems, start with Easy

---

# 💼 Career Relevance

## Job Titles Using These Skills
- 📊 **Data Engineer** (most common)
- 📈 **Analytics Engineer** (dbt specialist)
- 🔍 **Business Intelligence Developer**
- 🗄️ **Data Warehouse Developer**
- 🧪 **Data Analyst** (senior level)

## Skills Employers Want (Priority Order)
1. ✅ **SQL proficiency** - JOINs and CTEs (95% of job descriptions)
2. ✅ **dbt experience** - Industry standard (70% of modern data roles)
3. ✅ **Data transformation** - ETL/ELT pipelines
4. ✅ **Window functions** - For analytics roles
5. ✅ **Data modeling** - Star schema, normalization

## Real Interview Questions
- "Write a query to find top 3 products per category" → ROW_NUMBER()
- "Combine data from 5 tables" → Multiple JOINs
- "Make this subquery readable" → Convert to CTEs
- "Find users above their cohort average" → Window Functions

## Salary Impact
- SQL + JOINs: Entry level ($60-80K)
- + CTEs + dbt: Mid level ($80-120K)
- + Window Functions + Optimization: Senior ($120-180K)

---

# 📝 Homework

## Exercise 1: Employee Analysis with CTEs (Required)
Build a multi-step analysis:
- Use 3+ CTEs to organize your logic
- JOIN at least 4 tables
- Calculate aggregates and use CASE WHEN
- Find employees at risk of leaving

**Goal**: Practice breaking down complex problems into CTEs

**Due**: Next week  
**Hint**: Start with base data CTE, then add calculations

---

## Exercise 2: Top Performers Dashboard (Optional)
If you finish Exercise 1, try this:
- Find Top 3 performers per department (ROW_NUMBER)
- Compare salaries to department average (AVG OVER)
- Use CTEs to organize the logic

**Challenge**: Make it readable with clear CTE names and comments!

**Bonus**: Add NTILE() to divide into performance quartiles

---

# ❓ Questions?

## Get Help
- Office hours: [Your schedule]
- Email: [Your email]
- Discussion forum: [Link if applicable]

## Resources
- Teaching guide: `teaching_guide.md`
- Database setup: `hr_database_setup.sql`
- Exercises: `sql_exercises.sql`

---

# 🎉 Thank You!

## Today's Key Takeaways
- 🎯 **JOINs**: Your daily bread and butter (practice until automatic)
- 💚 **CTEs**: Industry standard, use them everywhere
- 🌟 **Window Functions**: Powerful tool when you need it

## Remember
- 💪 **Practice consistently** - 30 min daily beats 3 hours once a week
- 🔍 **Start simple** - Master JOINs + CTEs before advanced topics
- 📚 **Learn from mistakes** - Every error teaches you something
- 🚀 **These skills are your foundation** - Everything else builds on this

## Final Advice
1. **This week**: Rewrite 3 old queries using CTEs
2. **This month**: Complete 20 LeetCode SQL problems
3. **This year**: Build a portfolio project with dbt

## Good luck with your Data Engineering journey! 🎯

**Questions? Let's discuss! Keep querying!**

---

# 📎 Quick Reference

## Syntax Cheat Sheet

### JOIN
```sql
SELECT ...
FROM table1 t1
JOIN table2 t2 ON t1.id = t2.id
JOIN table3 t3 ON t1.id = t3.id;
```

### CTE
```sql
WITH cte1 AS (
    SELECT ...
),
cte2 AS (
    SELECT ... FROM cte1
)
SELECT * FROM cte2;
```

### Window Functions
```sql
-- Ranking
ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC)

-- Aggregates
AVG(salary) OVER (PARTITION BY dept)
SUM(salary) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

-- NTILE
NTILE(4) OVER (ORDER BY salary)
```

---
