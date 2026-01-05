"""
HR Data Processing Script
แปลงข้อมูล HR.csv เป็น normalized database tables (3NF)
และ generate SQL script สำหรับ PostgreSQL

แหล่งที่มาของข้อมูล:
IBM HR Analytics - Predictive Employee Attrition
https://www.kaggle.com/datasets/nicolaszalazar73/ibm-hr-analytics-predictive-employee-attrition/data
"""

import pandas as pd
import numpy as np
from datetime import datetime

# อ่านข้อมูล HR
print("กำลังอ่านข้อมูล HR.csv...")
df = pd.read_csv('HR.csv')
print(f"อ่านข้อมูลสำเร็จ: {len(df)} แถว")

# ==================== 1. DEPARTMENTS TABLE ====================
print("\n1. สร้างตาราง departments...")
departments_df = pd.DataFrame({
    'department_id': range(1, df['Department'].nunique() + 1),
    'department_name': sorted(df['Department'].unique())
})

# สร้าง mapping dict
dept_map = dict(zip(departments_df['department_name'], departments_df['department_id']))
print(f"   - จำนวนแผนก: {len(departments_df)}")

# ==================== 2. JOB_ROLES TABLE ====================
print("\n2. สร้างตาราง job_roles...")
# รวมข้อมูล JobRole และ JobLevel
job_data = df[['JobRole', 'JobLevel', 'Department']].drop_duplicates()
job_data = job_data.sort_values(['JobRole', 'JobLevel'])

job_roles_df = job_data.reset_index(drop=True)
job_roles_df['job_role_id'] = range(1, len(job_roles_df) + 1)
job_roles_df['department_id'] = job_roles_df['Department'].map(dept_map)
job_roles_df = job_roles_df[['job_role_id', 'JobRole', 'JobLevel', 'department_id']]
job_roles_df.columns = ['job_role_id', 'job_role_name', 'job_level', 'department_id']

# สร้าง mapping dict
job_map = {}
for _, row in df[['JobRole', 'JobLevel', 'Department']].iterrows():
    key = (row['JobRole'], row['JobLevel'], row['Department'])
    if key not in job_map:
        match = job_roles_df[
            (job_roles_df['job_role_name'] == row['JobRole']) & 
            (job_roles_df['job_level'] == row['JobLevel']) &
            (job_roles_df['department_id'] == dept_map[row['Department']])
        ]
        if not match.empty:
            job_map[key] = match.iloc[0]['job_role_id']

print(f"   - จำนวนตำแหน่งงาน: {len(job_roles_df)}")

# ==================== 3. EMPLOYEES TABLE ====================
print("\n3. สร้างตาราง employees...")
employees_df = pd.DataFrame({
    'employee_id': df['EmployeeNumber'],
    'age': df['Age'],
    'gender': df['Gender'],
    'marital_status': df['MaritalStatus'],
    'education': df['Education'],
    'education_field': df['EducationField'],
    'distance_from_home': df['DistanceFromHome'],
    'department_id': df['Department'].map(dept_map)
})

# Map job_role_id
employees_df['job_role_id'] = df.apply(
    lambda row: job_map.get((row['JobRole'], row['JobLevel'], row['Department'])), 
    axis=1
)

print(f"   - จำนวนพนักงาน: {len(employees_df)}")

# ==================== 4. EMPLOYEE_COMPENSATION TABLE ====================
print("\n4. สร้างตาราง employee_compensation...")
employee_compensation_df = pd.DataFrame({
    'compensation_id': range(1, len(df) + 1),
    'employee_id': df['EmployeeNumber'],
    'monthly_income': df['MonthlyIncome'],
    'monthly_rate': df['MonthlyRate'],
    'daily_rate': df['DailyRate'],
    'hourly_rate': df['HourlyRate'],
    'percent_salary_hike': df['PercentSalaryHike'],
    'stock_option_level': df['StockOptionLevel'],
    'standard_hours': df['StandardHours']
})

print(f"   - จำนวนรายการ: {len(employee_compensation_df)}")

# ==================== 5. EMPLOYEE_SATISFACTION TABLE ====================
print("\n5. สร้างตาราง employee_satisfaction...")
employee_satisfaction_df = pd.DataFrame({
    'satisfaction_id': range(1, len(df) + 1),
    'employee_id': df['EmployeeNumber'],
    'environment_satisfaction': df['EnvironmentSatisfaction'],
    'job_satisfaction': df['JobSatisfaction'],
    'relationship_satisfaction': df['RelationshipSatisfaction'],
    'work_life_balance': df['WorkLifeBalance'],
    'job_involvement': df['JobInvolvement'],
    'performance_rating': df['PerformanceRating']
})

print(f"   - จำนวนรายการ: {len(employee_satisfaction_df)}")

# ==================== 6. EMPLOYEE_WORK_HISTORY TABLE ====================
print("\n6. สร้างตาราง employee_work_history...")
employee_work_history_df = pd.DataFrame({
    'work_history_id': range(1, len(df) + 1),
    'employee_id': df['EmployeeNumber'],
    'total_working_years': df['TotalWorkingYears'],
    'years_at_company': df['YearsAtCompany'],
    'years_in_current_role': df['YearsInCurrentRole'],
    'years_since_last_promotion': df['YearsSinceLastPromotion'],
    'years_with_curr_manager': df['YearsWithCurrManager'],
    'num_companies_worked': df['NumCompaniesWorked'],
    'training_times_last_year': df['TrainingTimesLastYear'],
    'business_travel': df['BusinessTravel'],
    'over_time': df['OverTime'].map({1: 'Yes', 0: 'No'}),
    'attrition': df['Attrition'].map({1: 'Yes', 0: 'No'})
})

print(f"   - จำนวนรายการ: {len(employee_work_history_df)}")

# ==================== บันทึกข้อมูลเป็น CSV ====================
print("\n7. บันทึกข้อมูลเป็น CSV files...")
departments_df.to_csv('departments.csv', index=False)
job_roles_df.to_csv('job_roles.csv', index=False)
employees_df.to_csv('employees.csv', index=False)
employee_compensation_df.to_csv('employee_compensation.csv', index=False)
employee_satisfaction_df.to_csv('employee_satisfaction.csv', index=False)
employee_work_history_df.to_csv('employee_work_history.csv', index=False)

print("   ✓ บันทึก departments.csv")
print("   ✓ บันทึก job_roles.csv")
print("   ✓ บันทึก employees.csv")
print("   ✓ บันทึก employee_compensation.csv")
print("   ✓ บันทึก employee_satisfaction.csv")
print("   ✓ บันทึก employee_work_history.csv")

# ==================== สร้าง SQL Script ====================
print("\n8. สร้าง SQL script สำหรับ PostgreSQL...")

sql_content = """-- =====================================================
-- HR Analytics Database - PostgreSQL Script
-- สร้างโดย: process_hr_data.py
-- วันที่: """ + datetime.now().strftime("%Y-%m-%d %H:%M:%S") + """
-- =====================================================

-- Drop tables if exists (เรียงลำดับจากตารางที่มี foreign key ก่อน)
DROP TABLE IF EXISTS employee_work_history CASCADE;
DROP TABLE IF EXISTS employee_satisfaction CASCADE;
DROP TABLE IF EXISTS employee_compensation CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS job_roles CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- =====================================================
-- 1. DEPARTMENTS TABLE
-- =====================================================
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE
);

"""

# เพิ่ม INSERT statements สำหรับ departments
sql_content += "-- Insert departments data\n"
for _, row in departments_df.iterrows():
    sql_content += f"INSERT INTO departments (department_id, department_name) VALUES ({row['department_id']}, '{row['department_name']}');\n"

sql_content += """
-- =====================================================
-- 2. JOB_ROLES TABLE
-- =====================================================
CREATE TABLE job_roles (
    job_role_id SERIAL PRIMARY KEY,
    job_role_name VARCHAR(100) NOT NULL,
    job_level INTEGER NOT NULL CHECK (job_level BETWEEN 1 AND 5),
    department_id INTEGER NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    UNIQUE(job_role_name, job_level, department_id)
);

"""

# เพิ่ม INSERT statements สำหรับ job_roles
sql_content += "-- Insert job_roles data\n"
for _, row in job_roles_df.iterrows():
    sql_content += f"INSERT INTO job_roles (job_role_id, job_role_name, job_level, department_id) VALUES ({row['job_role_id']}, '{row['job_role_name']}', {row['job_level']}, {row['department_id']});\n"

sql_content += """
-- =====================================================
-- 3. EMPLOYEES TABLE
-- =====================================================
CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    age INTEGER NOT NULL CHECK (age BETWEEN 18 AND 100),
    gender VARCHAR(10) NOT NULL,
    marital_status VARCHAR(20) NOT NULL,
    education INTEGER NOT NULL CHECK (education BETWEEN 1 AND 5),
    education_field VARCHAR(50) NOT NULL,
    distance_from_home INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    job_role_id INTEGER NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (job_role_id) REFERENCES job_roles(job_role_id)
);

-- Insert employees data
"""

# เพิ่ม INSERT statements สำหรับ employees (batch insert)
for i in range(0, len(employees_df), 100):
    batch = employees_df.iloc[i:i+100]
    for _, row in batch.iterrows():
        sql_content += f"INSERT INTO employees VALUES ({row['employee_id']}, {row['age']}, '{row['gender']}', '{row['marital_status']}', {row['education']}, '{row['education_field']}', {row['distance_from_home']}, {row['department_id']}, {row['job_role_id']});\n"

sql_content += """
-- =====================================================
-- 4. EMPLOYEE_COMPENSATION TABLE
-- =====================================================
CREATE TABLE employee_compensation (
    compensation_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    monthly_income INTEGER NOT NULL,
    monthly_rate INTEGER NOT NULL,
    daily_rate INTEGER NOT NULL,
    hourly_rate INTEGER NOT NULL,
    percent_salary_hike INTEGER NOT NULL,
    stock_option_level INTEGER NOT NULL CHECK (stock_option_level BETWEEN 0 AND 3),
    standard_hours INTEGER NOT NULL DEFAULT 80,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Insert employee_compensation data
"""

for i in range(0, len(employee_compensation_df), 100):
    batch = employee_compensation_df.iloc[i:i+100]
    for _, row in batch.iterrows():
        sql_content += f"INSERT INTO employee_compensation VALUES ({row['compensation_id']}, {row['employee_id']}, {row['monthly_income']}, {row['monthly_rate']}, {row['daily_rate']}, {row['hourly_rate']}, {row['percent_salary_hike']}, {row['stock_option_level']}, {row['standard_hours']});\n"

sql_content += """
-- =====================================================
-- 5. EMPLOYEE_SATISFACTION TABLE
-- =====================================================
CREATE TABLE employee_satisfaction (
    satisfaction_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    environment_satisfaction INTEGER NOT NULL CHECK (environment_satisfaction BETWEEN 1 AND 4),
    job_satisfaction INTEGER NOT NULL CHECK (job_satisfaction BETWEEN 1 AND 4),
    relationship_satisfaction INTEGER NOT NULL CHECK (relationship_satisfaction BETWEEN 1 AND 4),
    work_life_balance INTEGER NOT NULL CHECK (work_life_balance BETWEEN 1 AND 4),
    job_involvement INTEGER NOT NULL CHECK (job_involvement BETWEEN 1 AND 4),
    performance_rating INTEGER NOT NULL CHECK (performance_rating BETWEEN 1 AND 4),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Insert employee_satisfaction data
"""

for i in range(0, len(employee_satisfaction_df), 100):
    batch = employee_satisfaction_df.iloc[i:i+100]
    for _, row in batch.iterrows():
        sql_content += f"INSERT INTO employee_satisfaction VALUES ({row['satisfaction_id']}, {row['employee_id']}, {row['environment_satisfaction']}, {row['job_satisfaction']}, {row['relationship_satisfaction']}, {row['work_life_balance']}, {row['job_involvement']}, {row['performance_rating']});\n"

sql_content += """
-- =====================================================
-- 6. EMPLOYEE_WORK_HISTORY TABLE
-- =====================================================
CREATE TABLE employee_work_history (
    work_history_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    total_working_years INTEGER NOT NULL,
    years_at_company INTEGER NOT NULL,
    years_in_current_role INTEGER NOT NULL,
    years_since_last_promotion INTEGER NOT NULL,
    years_with_curr_manager INTEGER NOT NULL,
    num_companies_worked INTEGER NOT NULL,
    training_times_last_year INTEGER NOT NULL,
    business_travel VARCHAR(30) NOT NULL,
    over_time VARCHAR(3) NOT NULL CHECK (over_time IN ('Yes', 'No')),
    attrition VARCHAR(3) NOT NULL CHECK (attrition IN ('Yes', 'No')),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Insert employee_work_history data
"""

for i in range(0, len(employee_work_history_df), 100):
    batch = employee_work_history_df.iloc[i:i+100]
    for _, row in batch.iterrows():
        sql_content += f"INSERT INTO employee_work_history VALUES ({row['work_history_id']}, {row['employee_id']}, {row['total_working_years']}, {row['years_at_company']}, {row['years_in_current_role']}, {row['years_since_last_promotion']}, {row['years_with_curr_manager']}, {row['num_companies_worked']}, {row['training_times_last_year']}, '{row['business_travel']}', '{row['over_time']}', '{row['attrition']}');\n"

sql_content += """
-- =====================================================
-- สร้าง INDEX เพื่อเพิ่มประสิทธิภาพการ Query
-- =====================================================
CREATE INDEX idx_employees_dept ON employees(department_id);
CREATE INDEX idx_employees_job ON employees(job_role_id);
CREATE INDEX idx_comp_emp ON employee_compensation(employee_id);
CREATE INDEX idx_sat_emp ON employee_satisfaction(employee_id);
CREATE INDEX idx_work_emp ON employee_work_history(employee_id);
CREATE INDEX idx_work_attrition ON employee_work_history(attrition);

-- =====================================================
-- สร้าง VIEWS สำหรับการ Query ที่ใช้บ่อย
-- =====================================================

-- View: ข้อมูลรวมพนักงานทั้งหมด
CREATE VIEW vw_employee_full_info AS
SELECT 
    e.employee_id,
    e.age,
    e.gender,
    e.marital_status,
    e.education,
    e.education_field,
    e.distance_from_home,
    d.department_name,
    jr.job_role_name,
    jr.job_level,
    ec.monthly_income,
    ec.percent_salary_hike,
    ec.stock_option_level,
    es.job_satisfaction,
    es.environment_satisfaction,
    es.work_life_balance,
    es.performance_rating,
    wh.years_at_company,
    wh.years_in_current_role,
    wh.over_time,
    wh.attrition
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN job_roles jr ON e.job_role_id = jr.job_role_id
JOIN employee_compensation ec ON e.employee_id = ec.employee_id
JOIN employee_satisfaction es ON e.employee_id = es.employee_id
JOIN employee_work_history wh ON e.employee_id = wh.employee_id;

-- View: สรุปข้อมูลการลาออกตามแผนก
CREATE VIEW vw_attrition_by_department AS
SELECT 
    d.department_name,
    COUNT(*) as total_employees,
    SUM(CASE WHEN wh.attrition = 'Yes' THEN 1 ELSE 0 END) as attrition_count,
    ROUND(SUM(CASE WHEN wh.attrition = 'Yes' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) as attrition_rate
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_work_history wh ON e.employee_id = wh.employee_id
GROUP BY d.department_name
ORDER BY attrition_rate DESC;

-- =====================================================
-- สร้าง SEQUENCES สำหรับ auto-increment
-- =====================================================
SELECT setval('departments_department_id_seq', (SELECT MAX(department_id) FROM departments));
SELECT setval('job_roles_job_role_id_seq', (SELECT MAX(job_role_id) FROM job_roles));
SELECT setval('employee_compensation_compensation_id_seq', (SELECT MAX(compensation_id) FROM employee_compensation));
SELECT setval('employee_satisfaction_satisfaction_id_seq', (SELECT MAX(satisfaction_id) FROM employee_satisfaction));
SELECT setval('employee_work_history_work_history_id_seq', (SELECT MAX(work_history_id) FROM employee_work_history));

-- =====================================================
-- เสร็จสิ้น!
-- =====================================================
SELECT 'Database setup completed successfully!' as status;
"""

# บันทึก SQL script
with open('hr_database_setup.sql', 'w', encoding='utf-8') as f:
    f.write(sql_content)

print("   ✓ สร้างไฟล์ hr_database_setup.sql เรียบร้อย")

print("\n" + "="*60)
print("✓ เสร็จสิ้นการประมวลผล!")
print("="*60)
print("\nไฟล์ที่สร้าง:")
print("  1. departments.csv")
print("  2. job_roles.csv")
print("  3. employees.csv")
print("  4. employee_compensation.csv")
print("  5. employee_satisfaction.csv")
print("  6. employee_work_history.csv")
print("  7. hr_database_setup.sql (สำหรับ PostgreSQL)")
print("\nสรุปตาราง:")
print(f"  - Departments: {len(departments_df)} แผนก")
print(f"  - Job Roles: {len(job_roles_df)} ตำแหน่ง")
print(f"  - Employees: {len(employees_df)} คน")
print(f"  - Attrition: {len(df[df['Attrition'] == 1])} คน ({len(df[df['Attrition'] == 1])/len(df)*100:.1f}%)")
print("\nวิธีใช้งาน:")
print("  1. รัน: psql -U postgres")
print("  2. สร้าง database: CREATE DATABASE hr_analytics;")
print("  3. เชื่อมต่อ: \\c hr_analytics")
print("  4. Import: \\i hr_database_setup.sql")
