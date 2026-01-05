-- =====================================================
-- แบบฝึกหัด Advanced SQL สำหรับ HR Analytics Database
-- สำหรับนักศึกษา Computer Science ปี 2-3
-- ระยะเวลา: 6 ชั่วโมง
-- =====================================================

-- =====================================================
-- ส่วนที่ 1: SQL เบื้องต้น (CRUD Operations)
-- เวลา: 1 ชั่วโมง
-- =====================================================

-- ===== 1.1 SELECT & WHERE =====
-- ตัวอย่าง: ดึงข้อมูลพนักงานทั้งหมด
SELECT * FROM employees LIMIT 10;

-- ตัวอย่าง: ดึงพนักงานเพศหญิงอายุมากกว่า 30 ปี
SELECT employee_id, age, gender, marital_status
FROM employees
WHERE gender = 'Female' AND age > 30;

-- ===== 1.2 INSERT =====
-- ตัวอย่าง: เพิ่มแผนกใหม่
INSERT INTO departments (department_name) VALUES ('IT Support');

-- ===== 1.3 UPDATE =====
-- ตัวอย่าง: อัพเดทเงินเดือนของพนักงาน
UPDATE employee_compensation 
SET monthly_income = monthly_income * 1.05
WHERE employee_id = 1;

-- ===== 1.4 DELETE =====
-- ตัวอย่าง: ลบแผนกที่ไม่มีพนักงาน
-- DELETE FROM departments WHERE department_id NOT IN (SELECT DISTINCT department_id FROM employees);

-- ===== 1.5 Aggregate Functions =====
-- ตัวอย่าง: หาเงินเดือนเฉลี่ย, สูงสุด, ต่ำสุด
SELECT 
    AVG(monthly_income) as avg_salary,
    MAX(monthly_income) as max_salary,
    MIN(monthly_income) as min_salary,
    COUNT(*) as total_employees
FROM employee_compensation;

-- =====================================================
-- ส่วนที่ 2: SQL ขั้นสูง - JOINs
-- เวลา: 1.5 ชั่วโมง
-- =====================================================

-- ===== 2.1 INNER JOIN (2 tables) =====
-- ตัวอย่าง: แสดงพนักงานพร้อมชื่อแผนก
SELECT 
    e.employee_id,
    e.age,
    e.gender,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
LIMIT 10;

-- ===== 2.2 JOIN หลายตาราง (3+ tables) =====
-- ตัวอย่าง: แสดงพนักงานพร้อมแผนก, ตำแหน่ง และเงินเดือน
SELECT 
    e.employee_id,
    e.age,
    d.department_name,
    jr.job_role_name,
    jr.job_level,
    ec.monthly_income
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN job_roles jr ON e.job_role_id = jr.job_role_id
INNER JOIN employee_compensation ec ON e.employee_id = ec.employee_id
ORDER BY ec.monthly_income DESC
LIMIT 10;

-- ===== 2.3 LEFT JOIN =====
-- ตัวอย่าง: แสดงแผนกทั้งหมดและจำนวนพนักงาน (รวมแผนกที่ไม่มีพนักงาน)
SELECT 
    d.department_name,
    COUNT(e.employee_id) as employee_count
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name;

-- ===== 2.4 Self JOIN =====
-- ตัวอย่าง: หาพนักงานที่มีอายุเท่ากัน
SELECT 
    e1.employee_id as emp1_id,
    e2.employee_id as emp2_id,
    e1.age
FROM employees e1
INNER JOIN employees e2 ON e1.age = e2.age AND e1.employee_id < e2.employee_id
LIMIT 10;

-- =====================================================
-- ส่วนที่ 3: Subqueries (SELECT ใน SELECT)
-- เวลา: 1 ชั่วโมง
-- =====================================================

-- ===== 3.1 Subquery ใน WHERE =====
-- ตัวอย่าง: หาพนักงานที่มีเงินเดือนสูงกว่าค่าเฉลี่ย
SELECT 
    e.employee_id,
    ec.monthly_income
FROM employees e
JOIN employee_compensation ec ON e.employee_id = ec.employee_id
WHERE ec.monthly_income > (SELECT AVG(monthly_income) FROM employee_compensation);

-- ===== 3.2 Subquery ใน FROM =====
-- ตัวอย่าง: หาแผนกที่มีเงินเดือนเฉลี่ยสูงสุด
SELECT 
    dept_salary.department_name,
    dept_salary.avg_salary
FROM (
    SELECT 
        d.department_name,
        AVG(ec.monthly_income) as avg_salary
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN employee_compensation ec ON e.employee_id = ec.employee_id
    GROUP BY d.department_name
) as dept_salary
ORDER BY dept_salary.avg_salary DESC
LIMIT 1;

-- ===== 3.3 Correlated Subquery =====
-- ตัวอย่าง: หาพนักงานที่มีเงินเดือนสูงกว่าค่าเฉลี่ยในแผนกของตัวเอง
SELECT 
    e.employee_id,
    d.department_name,
    ec.monthly_income
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_compensation ec ON e.employee_id = ec.employee_id
WHERE ec.monthly_income > (
    SELECT AVG(ec2.monthly_income)
    FROM employees e2
    JOIN employee_compensation ec2 ON e2.employee_id = ec2.employee_id
    WHERE e2.department_id = e.department_id
);

-- ===== 3.4 EXISTS =====
-- ตัวอย่าง: หาพนักงานที่ลาออกและทำ Overtime
SELECT 
    e.employee_id,
    e.age,
    d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE EXISTS (
    SELECT 1 
    FROM employee_work_history wh 
    WHERE wh.employee_id = e.employee_id 
    AND wh.attrition = 'Yes' 
    AND wh.over_time = 'Yes'
);

-- =====================================================
-- ส่วนที่ 4: Common Table Expressions (WITH Clause)
-- เวลา: 1 ชั่วโมง
-- =====================================================

-- ===== 4.1 CTE พื้นฐาน =====
-- ตัวอย่าง: ใช้ CTE คำนวณเงินเดือนเฉลี่ยตามแผนก
WITH dept_avg_salary AS (
    SELECT 
        d.department_id,
        d.department_name,
        AVG(ec.monthly_income) as avg_salary
    FROM departments d
    JOIN employees e ON d.department_id = e.department_id
    JOIN employee_compensation ec ON e.employee_id = ec.employee_id
    GROUP BY d.department_id, d.department_name
)
SELECT * FROM dept_avg_salary
ORDER BY avg_salary DESC;

-- ===== 4.2 Multiple CTEs =====
-- ตัวอย่าง: เปรียบเทียบพนักงานที่ลาออกกับไม่ลาออก
WITH attrition_stats AS (
    SELECT 
        'Attrition' as group_type,
        AVG(ec.monthly_income) as avg_salary,
        AVG(wh.years_at_company) as avg_tenure,
        COUNT(*) as employee_count
    FROM employee_work_history wh
    JOIN employee_compensation ec ON wh.employee_id = ec.employee_id
    WHERE wh.attrition = 'Yes'
),
retention_stats AS (
    SELECT 
        'Retention' as group_type,
        AVG(ec.monthly_income) as avg_salary,
        AVG(wh.years_at_company) as avg_tenure,
        COUNT(*) as employee_count
    FROM employee_work_history wh
    JOIN employee_compensation ec ON wh.employee_id = ec.employee_id
    WHERE wh.attrition = 'No'
)
SELECT * FROM attrition_stats
UNION ALL
SELECT * FROM retention_stats;

-- ===== 4.3 Recursive CTE =====
-- ตัวอย่าง: สร้างลำดับเลข 1-10
WITH RECURSIVE numbers AS (
    SELECT 1 as n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT * FROM numbers;

-- =====================================================
-- ส่วนที่ 5: Window Functions
-- เวลา: 1.5 ชั่วโมง
-- =====================================================

-- ===== 5.1 ROW_NUMBER() =====
-- ตัวอย่าง: จัดอันดับพนักงานตามเงินเดือนในแต่ละแผนก
SELECT 
    e.employee_id,
    d.department_name,
    ec.monthly_income,
    ROW_NUMBER() OVER (PARTITION BY d.department_id ORDER BY ec.monthly_income DESC) as salary_rank
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_compensation ec ON e.employee_id = ec.employee_id;

-- ===== 5.2 RANK() vs DENSE_RANK() =====
-- ตัวอย่าง: เปรียบเทียบ RANK และ DENSE_RANK
SELECT 
    e.employee_id,
    ec.monthly_income,
    RANK() OVER (ORDER BY ec.monthly_income DESC) as rank,
    DENSE_RANK() OVER (ORDER BY ec.monthly_income DESC) as dense_rank
FROM employees e
JOIN employee_compensation ec ON e.employee_id = ec.employee_id
LIMIT 20;

-- ===== 5.3 LAG() & LEAD() =====
-- ตัวอย่าง: เปรียบเทียบเงินเดือนกับพนักงานก่อนหน้าและถัดไป
SELECT 
    e.employee_id,
    ec.monthly_income,
    LAG(ec.monthly_income) OVER (ORDER BY ec.monthly_income) as prev_salary,
    LEAD(ec.monthly_income) OVER (ORDER BY ec.monthly_income) as next_salary
FROM employees e
JOIN employee_compensation ec ON e.employee_id = ec.employee_id
LIMIT 20;

-- ===== 5.4 Aggregate Window Functions =====
-- ตัวอย่าง: คำนวณ Running Total ของเงินเดือน
SELECT 
    e.employee_id,
    d.department_name,
    ec.monthly_income,
    SUM(ec.monthly_income) OVER (PARTITION BY d.department_id ORDER BY e.employee_id) as running_total,
    AVG(ec.monthly_income) OVER (PARTITION BY d.department_id) as dept_avg_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_compensation ec ON e.employee_id = ec.employee_id
LIMIT 50;

-- ===== 5.5 NTILE() =====
-- ตัวอย่าง: แบ่งพนักงานเป็น 4 กลุ่มตามเงินเดือน (Quartiles)
SELECT 
    e.employee_id,
    ec.monthly_income,
    NTILE(4) OVER (ORDER BY ec.monthly_income) as salary_quartile
FROM employees e
JOIN employee_compensation ec ON e.employee_id = ec.employee_id;

-- =====================================================
-- ส่วนที่ 6: Advanced Techniques & Performance
-- เวลา: 30 นาที
-- =====================================================

-- ===== 6.1 CASE WHEN =====
-- ตัวอย่าง: จัดกลุ่มอายุพนักงาน
SELECT 
    e.employee_id,
    e.age,
    CASE 
        WHEN e.age < 30 THEN 'Young (< 30)'
        WHEN e.age BETWEEN 30 AND 45 THEN 'Middle (30-45)'
        ELSE 'Senior (> 45)'
    END as age_group
FROM employees e;

-- ===== 6.2 COALESCE & NULLIF =====
-- ตัวอย่าง: จัดการค่า NULL
SELECT 
    employee_id,
    COALESCE(years_since_last_promotion, 0) as years_since_promo,
    NULLIF(years_since_last_promotion, 0) as non_zero_promo_years
FROM employee_work_history
LIMIT 10;

-- ===== 6.3 UNION vs UNION ALL =====
-- ตัวอย่าง: รวมข้อมูลพนักงานจาก 2 แผนก
SELECT employee_id, 'Sales' as source FROM employees WHERE department_id = 1
UNION ALL
SELECT employee_id, 'R&D' as source FROM employees WHERE department_id = 2
LIMIT 20;

-- ===== 6.4 GROUP BY with HAVING =====
-- ตัวอย่าง: หาแผนกที่มีพนักงานมากกว่า 100 คน
SELECT 
    d.department_name,
    COUNT(*) as employee_count,
    AVG(ec.monthly_income) as avg_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_compensation ec ON e.employee_id = ec.employee_id
GROUP BY d.department_name
HAVING COUNT(*) > 100
ORDER BY employee_count DESC;

-- =====================================================
-- แบบฝึกหัด (Exercises)
-- =====================================================

-- ===== แบบฝึกหัดที่ 1: Multi-table JOIN & Aggregation =====
-- โจทย์: จงหาข้อมูลสรุปของแต่ละแผนก ประกอบด้วย:
-- - ชื่อแผนก
-- - จำนวนพนักงานทั้งหมด
-- - จำนวนพนักงานที่ลาออก
-- - เปอร์เซ็นต์การลาออก
-- - เงินเดือนเฉลี่ย
-- - อายุงานเฉลี่ย (years_at_company)
-- เรียงลำดับจากเปอร์เซ็นต์การลาออกมากไปน้อย

-- เฉลย:
SELECT 
    d.department_name,
    COUNT(e.employee_id) as total_employees,
    SUM(CASE WHEN wh.attrition = 'Yes' THEN 1 ELSE 0 END) as attrition_count,
    ROUND(SUM(CASE WHEN wh.attrition = 'Yes' THEN 1 ELSE 0 END)::NUMERIC / COUNT(e.employee_id) * 100, 2) as attrition_rate,
    ROUND(AVG(ec.monthly_income), 2) as avg_salary,
    ROUND(AVG(wh.years_at_company), 2) as avg_tenure
FROM departments d
JOIN employees e ON d.department_id = e.department_id
JOIN employee_work_history wh ON e.employee_id = wh.employee_id
JOIN employee_compensation ec ON e.employee_id = ec.employee_id
GROUP BY d.department_name
ORDER BY attrition_rate DESC;


-- ===== แบบฝึกหัดที่ 2: CTE & Window Functions =====
-- โจทย์: จงหา Top 3 พนักงานที่มีเงินเดือนสูงสุดในแต่ละแผนก พร้อมแสดง:
-- - employee_id
-- - ชื่อแผนก
-- - ตำแหน่งงาน
-- - เงินเดือน
-- - อันดับในแผนก
-- - ความแตกต่างจากเงินเดือนสูงสุดในแผนก

-- เฉลย:
WITH ranked_employees AS (
    SELECT 
        e.employee_id,
        d.department_name,
        jr.job_role_name,
        ec.monthly_income,
        ROW_NUMBER() OVER (PARTITION BY d.department_id ORDER BY ec.monthly_income DESC) as rank_in_dept,
        MAX(ec.monthly_income) OVER (PARTITION BY d.department_id) as max_dept_salary
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN job_roles jr ON e.job_role_id = jr.job_role_id
    JOIN employee_compensation ec ON e.employee_id = ec.employee_id
)
SELECT 
    employee_id,
    department_name,
    job_role_name,
    monthly_income,
    rank_in_dept,
    (max_dept_salary - monthly_income) as salary_gap_from_max
FROM ranked_employees
WHERE rank_in_dept <= 3
ORDER BY department_name, rank_in_dept;


-- ===== แบบฝึกหัดที่ 3: Complex Analysis with Multiple CTEs =====
-- โจทย์: วิเคราะห์ปัจจัยที่เกี่ยวข้องกับการลาออกของพนักงาน
-- สร้าง CTE 3 ตัว:
-- 1. overtime_attrition: สถิติการลาออกของพนักงานที่ทำ Overtime vs ไม่ทำ
-- 2. satisfaction_attrition: ความพึงพอใจเฉลี่ยของพนักงานที่ลาออก vs ไม่ลาออก
-- 3. tenure_attrition: อายุงานเฉลี่ยของพนักงานที่ลาออก vs ไม่ลาออก
-- แล้วรวมผลลัพธ์ทั้ง 3 CTE มาแสดงในรูปแบบสรุป

-- เฉลย:
WITH overtime_attrition AS (
    SELECT 
        wh.over_time,
        COUNT(*) as total_count,
        SUM(CASE WHEN wh.attrition = 'Yes' THEN 1 ELSE 0 END) as attrition_count,
        ROUND(SUM(CASE WHEN wh.attrition = 'Yes' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) as attrition_rate
    FROM employee_work_history wh
    GROUP BY wh.over_time
),
satisfaction_attrition AS (
    SELECT 
        wh.attrition,
        ROUND(AVG(es.job_satisfaction), 2) as avg_job_satisfaction,
        ROUND(AVG(es.environment_satisfaction), 2) as avg_env_satisfaction,
        ROUND(AVG(es.work_life_balance), 2) as avg_work_life_balance
    FROM employee_work_history wh
    JOIN employee_satisfaction es ON wh.employee_id = es.employee_id
    GROUP BY wh.attrition
),
tenure_attrition AS (
    SELECT 
        wh.attrition,
        ROUND(AVG(wh.years_at_company), 2) as avg_years_at_company,
        ROUND(AVG(wh.total_working_years), 2) as avg_total_working_years
    FROM employee_work_history wh
    GROUP BY wh.attrition
)
SELECT 
    'Overtime Analysis' as analysis_type,
    over_time as category,
    total_count::TEXT as value1,
    attrition_rate::TEXT as value2,
    NULL as value3
FROM overtime_attrition
UNION ALL
SELECT 
    'Satisfaction Analysis' as analysis_type,
    attrition as category,
    avg_job_satisfaction::TEXT as value1,
    avg_env_satisfaction::TEXT as value2,
    avg_work_life_balance::TEXT as value3
FROM satisfaction_attrition
UNION ALL
SELECT 
    'Tenure Analysis' as analysis_type,
    attrition as category,
    avg_years_at_company::TEXT as value1,
    avg_total_working_years::TEXT as value2,
    NULL as value3
FROM tenure_attrition;


-- ===== แบบฝึกหัดที่ 4: Advanced Window Functions =====
-- โจทย์: สร้างรายงานแสดงการเคลื่อนไหวของเงินเดือนในแต่ละตำแหน่งงาน:
-- - แสดงพนักงาน 5 คนแรกของแต่ละ job_role (เรียงตาม employee_id)
-- - แสดงเงินเดือนของพนักงานแต่ละคน
-- - แสดงเงินเดือนเฉลี่ยของตำแหน่งนั้นๆ
-- - แสดงเงินเดือนของพนักงานคนก่อนหน้า (ใช้ LAG)
-- - คำนวณความแตกต่างของเงินเดือนจากคนก่อนหน้า

-- เฉลย:
WITH ranked_by_role AS (
    SELECT 
        e.employee_id,
        jr.job_role_name,
        ec.monthly_income,
        ROW_NUMBER() OVER (PARTITION BY jr.job_role_id ORDER BY e.employee_id) as row_num,
        AVG(ec.monthly_income) OVER (PARTITION BY jr.job_role_id) as avg_role_salary,
        LAG(ec.monthly_income) OVER (PARTITION BY jr.job_role_id ORDER BY e.employee_id) as prev_salary
    FROM employees e
    JOIN job_roles jr ON e.job_role_id = jr.job_role_id
    JOIN employee_compensation ec ON e.employee_id = ec.employee_id
)
SELECT 
    employee_id,
    job_role_name,
    monthly_income,
    ROUND(avg_role_salary, 2) as avg_role_salary,
    prev_salary,
    CASE 
        WHEN prev_salary IS NOT NULL THEN (monthly_income - prev_salary)
        ELSE NULL
    END as salary_diff_from_prev
FROM ranked_by_role
WHERE row_num <= 5
ORDER BY job_role_name, employee_id;

-- =====================================================
-- การบ้าน (Homework)
-- =====================================================

-- ===== การบ้านข้อที่ 1: Employee Risk Analysis =====
-- โจทย์: สร้าง query เพื่อหา "High Risk" พนักงานที่มีแนวโน้มจะลาออก
-- เกณฑ์:
-- 1. ทำ Overtime = Yes
-- 2. job_satisfaction <= 2
-- 3. years_at_company < 2
-- 4. percent_salary_hike < 15
-- แสดงข้อมูล: employee_id, แผนก, ตำแหน่ง, เงินเดือน, years_at_company, จำนวนเกณฑ์ที่ตรงจากทั้งหมด 4 ข้อ
-- เรียงตามจำนวนเกณฑ์ที่ตรงจากมากไปน้อย

-- คำตอบนักศึกษาเขียนเอง:
-- ...


-- ===== การบ้านข้อที่ 2: Department Performance Dashboard =====
-- โจทย์: สร้าง query สำหรับ Dashboard ของแต่ละแผนก แสดง:
-- 1. จำนวนพนักงานทั้งหมด
-- 2. จำนวนและเปอร์เซ็นต์พนักงานแต่ละ Gender
-- 3. จำนวนและเปอร์เซ็นต์พนักงานแต่ละ Marital Status  
-- 4. อายุเฉลี่ย
-- 5. เงินเดือนเฉลี่ย, ต่ำสุด, สูงสุด
-- 6. ค่าเฉลี่ย job_satisfaction
-- 7. อัตราการลาออก
-- ใช้ CASE WHEN และ Aggregate Functions

-- คำตอบนักศึกษาเขียนเอง:
-- ...


-- ===== การบ้านข้อที่ 3: Salary Cohort Analysis =====
-- โจทย์: วิเคราะห์เงินเดือนแบบ Cohort (แบ่งกลุ่มตาม total_working_years)
-- 1. ใช้ NTILE แบ่งพนักงานออกเป็น 5 กลุ่มตาม total_working_years (quintiles)
-- 2. สำหรับแต่ละกลุ่ม ให้แสดง:
--    - ช่วงอายุงาน (min-max total_working_years)
--    - จำนวนพนักงานในกลุ่ม
--    - เงินเดือนเฉลี่ย
--    - เปอร์เซ็นต์การลาออก
-- 3. เพิ่มคอลัมน์ที่แสดง "อัตราการเพิ่มขึ้นของเงินเดือนเฉลี่ย" เมื่อเทียบกับกลุ่มก่อนหน้า

-- คำตอบนักศึกษาเขียนเอง:
-- ...


-- ===== การบ้านข้อที่ 4: Predictive Features Ranking =====
-- โจทย์: สร้าง query เพื่อหา "features" ที่มีความสัมพันธ์กับการลาออก
-- เปรียบเทียบค่าเฉลี่ยของแต่ละ feature ระหว่างพนักงานที่ลาออกกับไม่ลาออก:
-- - monthly_income
-- - years_at_company  
-- - distance_from_home
-- - job_satisfaction
-- - environment_satisfaction
-- - work_life_balance
-- แสดงผลในรูปแบบ: feature_name, avg_attrition_yes, avg_attrition_no, difference, abs_difference
-- เรียงตาม abs_difference จากมากไปน้อย
-- ใช้ CASE WHEN และ UNION ALL

-- คำตอบนักศึกษาเขียนเอง:
-- ...

-- =====================================================
-- จบแบบฝึกหัด - ขอให้สนุกกับการเรียน SQL! 🚀
-- =====================================================
