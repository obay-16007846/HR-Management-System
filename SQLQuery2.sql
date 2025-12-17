USE HRMS;  
GO

-- Currency
INSERT INTO Currency (CurrencyCode, CurrencyName, ExchangeRate, CreatedDate, LastUpdated)
VALUES ('USD', 'US Dollar', 1.00, '2025-01-01', '2025-01-01'),
       ('EUR', 'Euro', 0.85, '2025-01-01', '2025-01-01');

-- Position
INSERT INTO Position (position_id, position_title, responsibilities, status)
VALUES (1, 'CEO', 'Overall leadership', 'Active'),
       (2, 'HR Manager', 'Manage HR operations', 'Active'),
       (3, 'IT Developer', 'Develop software', 'Active'),
       (4, 'Payroll Specialist', 'Handle payroll', 'Active'),
       (5, 'Line Manager', 'Manage team', 'Active'),
       (6, 'Intern', 'Support tasks', 'Active'),
       (7, 'Consultant', 'Provide expertise', 'Active');

-- PayGrade
INSERT INTO PayGrade (pay_grade_id, grade_name, min_salary, max_salary)
VALUES (1, 'Executive', 200000.00, 300000.00),
       (2, 'Manager', 100000.00, 150000.00),
       (3, 'Specialist', 60000.00, 90000.00),
       (4, 'Entry', 30000.00, 50000.00);

-- TaxForm
INSERT INTO TaxForm (tax_form_id, jurisdiction, validity_period, form_content)
VALUES (1, 'US Federal', 'Annual', 'W-4 Form'),
       (2, 'EU Standard', 'Annual', 'Tax Declaration');

-- SalaryType
INSERT INTO SalaryType (salary_type_id, type, payment_frequency, currency)
VALUES (1, 'Monthly', 'Monthly', 'USD'),
       (2, 'Hourly', 'Bi-Weekly', 'USD'),
       (3, 'Contract', 'Milestone', 'USD');

-- HourlySalaryType
INSERT INTO HourlySalaryType (salary_type_id, hourly_rate, max_monthly_hours)
VALUES (2, 25.00, 160);

-- MonthlySalaryType
INSERT INTO MonthlySalaryType (salary_type_id, tax_rule, contribution_scheme)
VALUES (1, 'Standard Deduction', '401k Matching');

-- ContractSalaryType
INSERT INTO ContractSalaryType (salary_type_id, contract_value, installment_details)
VALUES (3, 50000.00, '50% upfront, 50% completion');

-- Contract
INSERT INTO Contract (contract_id, type, start_date, end_date, current_state)
VALUES (1, 'FullTime', '2025-01-01', NULL, 'Active'),
       (2, 'PartTime', '2025-01-01', NULL, 'Active'),
       (3, 'Consultant', '2025-01-01', '2025-12-31', 'Active'),
       (4, 'Internship', '2025-01-01', '2025-06-30', 'Active'),
       (5, 'FullTime', '2025-01-01', NULL, 'Active');

-- FullTimeContract
INSERT INTO FullTimeContract (contract_id, leave_entitlement, insurance_eligibility, weekly_working_hours)
VALUES (1, 30, 'Comprehensive', 40),
       (5, 25, 'Basic', 40);

-- PartTimeContract
INSERT INTO PartTimeContract (contract_id, working_hours, hourly_rate)
VALUES (2, 20, 30.00);

-- ConsultantContract
INSERT INTO ConsultantContract (contract_id, project_scope, fees, payment_schedule)
VALUES (3, 'System Implementation', 10000.00, 'Monthly');

-- InternshipContract
INSERT INTO InternshipContract (contract_id, mentoring, evaluation, stipend_related)
VALUES (4, 'Senior Mentor', 'End of Term', 500.00);

-- Department (insert without head first, update later)
INSERT INTO Department (department_id, department_name, purpose, department_head_id)
VALUES (1, 'Executive', 'Leadership', NULL),
       (2, 'HR', 'Human Resources', NULL),
       (3, 'IT', 'Technology', NULL),
       (4, 'Finance', 'Financial Operations', NULL);

-- Employee (insert CEO first without manager, then others)
INSERT INTO Employee (employee_id, first_name, last_name, full_name, national_id, date_of_birth, country_of_birth, phone, email, address, emergency_contact_name, emergency_contact_phone, relationship, biography, profile_image, employment_progress, account_status, employment_status, hire_date, is_active, profile_completion, department_id, position_id, manager_id, contract_id, tax_form_id, salary_type_id, pay_grade_id)
VALUES (1, 'John', 'Doe', 'John Doe', '123456789', '1980-01-01', 'USA', '123-456-7890', 'ceo@example.com', '123 Main St', 'Jane Doe', '987-654-3210', 'Spouse', 'Experienced leader', 'profile1.jpg', 'Promoted to CEO', 'Active', 'FullTime', '2020-01-01', 1, 100, 1, 1, NULL, 1, 1, 1, 1),
       (2, 'Alice', 'Smith', 'Alice Smith', '987654321', '1990-02-02', 'USA', '234-567-8901', 'hr@example.com', '456 Elm St', 'Bob Smith', '876-543-2109', 'Parent', 'HR expert', 'profile2.jpg', 'Joined as Manager', 'Active', 'FullTime', '2022-01-01', 1, 100, 2, 2, 1, 5, 1, 1, 2),
       (3, 'Bob', 'Johnson', 'Bob Johnson', '112233445', '1995-03-03', 'USA', '345-678-9012', 'it@example.com', '789 Oak St', 'Carol Johnson', '765-432-1098', 'Sibling', 'Developer', 'profile3.jpg', 'Entry level', 'Active', 'PartTime', '2023-01-01', 1, 90, 3, 3, 1, 2, 1, 2, 3),
       (4, 'Charlie', 'Brown', 'Charlie Brown', '556677889', '2000-04-04', 'USA', '456-789-0123', 'payroll@example.com', '101 Pine St', 'David Brown', '654-321-0987', 'Friend', 'Payroll specialist', 'profile4.jpg', 'Specialist role', 'Active', 'FullTime', '2021-01-01', 1, 100, 4, 4, 2, 1, 1, 1, 3),
       (5, 'Dana', 'Lee', 'Dana Lee', '998877665', '1992-05-05', 'USA', '567-890-1234', 'manager@example.com', '202 Maple St', 'Evan Lee', '543-210-9876', 'Spouse', 'Line manager', 'profile5.jpg', 'Managerial role', 'Active', 'FullTime', '2022-01-01', 1, 100, 3, 5, 1, 1, 1, 1, 2),
       (6, 'Eve', 'Davis', 'Eve Davis', '334455667', '2002-06-06', 'USA', '678-901-2345', 'intern@example.com', '303 Birch St', 'Frank Davis', '432-109-8765', 'Parent', 'Intern', 'profile6.jpg', 'Internship', 'Active', 'Internship', '2025-01-01', 1, 80, 3, 6, 5, 4, 2, 3, 4),
       (7, 'Frank', 'Miller', 'Frank Miller', '778899001', '1985-07-07', 'USA', '789-012-3456', 'consult@example.com', '404 Cedar St', 'Grace Miller', '321-098-7654', 'Sibling', 'Consultant', 'profile7.jpg', 'Contract role', 'Active', 'Consultant', '2025-01-01', 1, 95, 3, 7, 1, 3, 1, 3, 3),
       (8, 'Grace', 'Wilson', 'Grace Wilson', '223344556', '1993-08-08', 'USA', '890-123-4567', 'dev2@example.com', '505 Spruce St', 'Henry Wilson', '210-987-6543', 'Friend', 'Developer', 'profile8.jpg', 'Mid-level', 'Active', 'FullTime', '2024-01-01', 1, 100, 3, 3, 5, 1, 1, 1, 3),
       (9, 'Henry', 'Taylor', 'Henry Taylor', '667788990', '1991-09-09', 'USA', '901-234-5678', 'hr2@example.com', '606 Aspen St', 'Ivy Taylor', '109-876-5432', 'Spouse', 'HR admin', 'profile9.jpg', 'Admin role', 'Active', 'FullTime', '2023-01-01', 1, 100, 2, 2, 2, 1, 1, 1, 2),
       (10, 'Ivy', 'Anderson', 'Ivy Anderson', '112233446', '1994-10-10', 'USA', '012-345-6789', 'finance@example.com', '707 Fir St', 'Jack Anderson', '098-765-4321', 'Parent', 'Finance specialist', 'profile10.jpg', 'Specialist', 'Active', 'PartTime', '2024-01-01', 1, 90, 4, 3, 1, 2, 1, 2, 3);

-- Update Department heads (now that employees exist)
UPDATE Department SET department_head_id = 1 WHERE department_id = 1;
UPDATE Department SET department_head_id = 2 WHERE department_id = 2;
UPDATE Department SET department_head_id = 5 WHERE department_id = 3;
UPDATE Department SET department_head_id = 4 WHERE department_id = 4;

-- HRAdministrator (for employee 2 and 9)
INSERT INTO HRAdministrator (employee_id, approval_level, record_access_scope, document_validation_rights)
VALUES (2, 'Organization-Wide', 'All Records', 'Approve All'),
       (9, 'Department-Level', 'HR Records', 'Verify Certifications');

-- SystemAdministrator (for employee 1)
INSERT INTO SystemAdministrator (employee_id, system_privilege_level, configurable_fields, audit_visibility_scope)
VALUES (1, 'Super Admin', 'All Fields', 'Full System Logs');

-- PayrollSpecialist (for employee 4)
INSERT INTO PayrollSpecialist (employee_id, assigned_region, processing_frequency, last_processed_period)
VALUES (4, 'North Region', 'Monthly', '2025-10-01');

-- LineManager (for employee 5)
INSERT INTO LineManager (employee_id, team_size, supervised_departments, approval_limit)
VALUES (5, 5, 'IT', 5000.00);

-- Skill
INSERT INTO Skill (skill_id, skill_name, description)
VALUES (1, 'SQL', 'Database management'),
       (2, 'Leadership', 'Team leading');

-- Employee_Skill
INSERT INTO Employee_Skill (employee_id, skill_id, proficiency_level)
VALUES (3, 1, 'Expert'),
       (5, 2, 'Advanced'),
       (8, 1, 'Intermediate');

-- Verification
INSERT INTO Verification (verification_id, verification_type, issuer, issue_date, expiry_period)
VALUES (1, 'Background Check', 'Agency', '2024-01-01', 12),
       (2, 'Certification', 'Institute', '2023-01-01', 24);

-- Employee_Verification
INSERT INTO Employee_Verification (employee_id, verification_id)
VALUES (3, 1),
       (7, 2);

-- Role
INSERT INTO Role (role_id, role_name, purpose)
VALUES (1, 'System Admin', 'Manage system'),
       (2, 'HR Admin', 'Manage HR'),
       (3, 'Payroll Officer', 'Handle payroll'),
       (4, 'Manager', 'Supervise team');

-- Employee_Role
INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
VALUES (1, 1, '2020-01-01'),
       (2, 2, '2022-01-01'),
       (4, 3, '2021-01-01'),
       (5, 4, '2022-01-01'),
       (9, 2, '2023-01-01');

-- RolePermission
INSERT INTO RolePermission (role_id, permission_name, allowed_action)
VALUES (1, 'Configure System', 'Full Access'),
       (2, 'Approve Leaves', 'Approve'),
       (3, 'Process Payroll', 'Execute'),
       (4, 'Assign Shifts', 'Assign');

-- Insurance
INSERT INTO Insurance (insurance_id, type, contribution_rate, coverage)
VALUES (1, 'Health', 5.00, 'Full Family'),
       (2, 'Life', 2.00, 'Employee Only');

-- Termination (for a sample expired contract)
INSERT INTO Termination (termination_id, date, reason, contract_id)
VALUES (1, '2025-12-31', 'Contract End', 3);

-- Reimbursement
INSERT INTO Reimbursement (reimbursement_id, type, claim_type, approval_date, current_status, employee_id)
VALUES (1, 'Travel', 'Expense', '2025-02-01', 'Approved', 3),
       (2, 'Medical', 'Claim', '2025-03-01', 'Pending', 6);

-- Mission
INSERT INTO Mission (mission_id, destination, start_date, end_date, status, employee_id, manager_id)
VALUES (1, 'Conference', '2025-04-01', '2025-04-05', 'Completed', 3, 5),
       (2, 'Training', '2025-05-01', '2025-05-03', 'Planned', 8, 5);

-- Leave
INSERT INTO Leave (leave_id, leave_type, leave_description)
VALUES (1, 'Vacation', 'Annual vacation'),
       (2, 'Sick', 'Medical leave'),
       (3, 'Probation', 'Probation period leave'),
       (4, 'Holiday', 'Public holiday');

-- VacationLeave
INSERT INTO VacationLeave (leave_id, carry_over_days, approving_manager)
VALUES (1, 5, 5);

-- SickLeave
INSERT INTO SickLeave (leave_id, medical_cert_required, physician_id)
VALUES (2, 1, 1);

-- ProbationLeave
INSERT INTO ProbationLeave (leave_id, eligibility_start_date, probation_period)
VALUES (3, '2025-01-01', 90);

-- HolidayLeave
INSERT INTO HolidayLeave (leave_id, holiday_name, official_recognition, regional_scope)
VALUES (4, 'New Year', 1, 'Global');

-- LeavePolicy
INSERT INTO LeavePolicy (policy_id, name, purpose, eligibility_rules, notice_period, special_leave_type, reset_on_new_year)
VALUES (1, 'Annual Leave', 'Rest', 'After 6 months', 14, 'Vacation', 1),
       (2, 'Sick Leave', 'Health', 'Immediate', 0, 'Sick', 0);

-- LeaveRequest
INSERT INTO LeaveRequest (request_id, employee_id, leave_id, justification, duration, approval_timing, status)
VALUES (1, 3, 1, 'Vacation', 5, 'Immediate', 'Approved'),
       (2, 6, 2, 'Illness', 3, 'Immediate', 'Approved'),
       (3, 8, 3, 'Probation', 1, 'Immediate', 'Pending');

-- LeaveEntitlement
INSERT INTO LeaveEntitlement (employee_id, leave_type_id, entitlement)
VALUES (3, 1, 20),
       (6, 2, 10),
       (8, 1, 15);

-- LeaveDocument
INSERT INTO LeaveDocument (document_id, leave_request_id, file_path, uploaded_at)
VALUES (1, 1, 'vacation_proof.pdf', '2025-03-01 10:00:00'),
       (2, 2, 'medical_cert.pdf', '2025-04-01 10:00:00');

-- ShiftSchedule
INSERT INTO ShiftSchedule (shift_id, name, type, start_time, end_time, break_duration, shift_date, status)
VALUES (1, 'Morning', 'Regular', '09:00:00', '17:00:00', 60, '2025-01-01', 'Active'),
       (2, 'Evening', 'Split', '13:00:00', '21:00:00', 30, '2025-01-01', 'Active'),
       (3, 'Custom', 'Flexible', '10:00:00', '18:00:00', 45, '2025-01-01', 'Active');

-- ShiftAssignment
INSERT INTO ShiftAssignment (assignment_id, employee_id, shift_id, start_date, end_date, status)
VALUES (1, 3, 1, '2025-01-01', '2025-12-31', 'Assigned'),
       (2, 8, 2, '2025-01-01', '2025-12-31', 'Assigned'),
       (3, 6, 3, '2025-01-01', '2025-06-30', 'Assigned');

-- Exception
INSERT INTO Exception (exception_id, name, category, date, status)
VALUES (1, 'Holiday', 'Public', '2025-12-25', 'Approved'),
       (2, 'Emergency', 'Personal', '2025-05-10', 'Approved');

-- Employee_Exception
INSERT INTO Employee_Exception (employee_id, exception_id)
VALUES (3, 1),
       (6, 2);

-- Attendance
INSERT INTO Attendance (attendance_id, employee_id, shift_id, entry_time, exit_time, duration, login_method, logout_method, exception_id)
VALUES (1, 3, 1, '2025-01-02 09:00:00', '2025-01-02 17:00:00', 480, 'Biometric', 'Biometric', NULL),
       (2, 8, 2, '2025-01-02 13:00:00', '2025-01-02 21:00:00', 480, 'App', 'App', NULL),
       (3, 6, 3, '2025-01-02 10:00:00', '2025-01-02 18:00:00', 480, 'Manual', 'Manual', 2);

-- AttendanceLog
INSERT INTO AttendanceLog (attendance_log_id, attendance_id, actor, timestamp, reason)
VALUES (1, 1, 3, '2025-01-02 09:00:00', 'Login'),
       (2, 1, 3, '2025-01-02 17:00:00', 'Logout');

-- AttendanceCorrectionRequest
INSERT INTO AttendanceCorrectionRequest (request_id, employee_id, date, correction_type, reason, status, recorded_by)
VALUES (1, 3, '2025-01-03', 'Time Adjustment', 'Late entry', 'Approved', 5);

-- Payroll
INSERT INTO Payroll (payroll_id, employee_id, taxes, period_start, period_end, base_amount, adjustments, contributions, actual_pay, net_salary, payment_date)
VALUES (1, 3, 500.00, '2025-01-01', '2025-01-31', 5000.00, 200.00, 300.00, 5500.00, 4700.00, '2025-02-01'),
       (2, 6, 100.00, '2025-01-01', '2025-01-31', 2000.00, 0.00, 50.00, 2000.00, 1850.00, '2025-02-01');

-- AllowanceDeduction
INSERT INTO AllowanceDeduction (ad_id, payroll_id, employee_id, type, amount, currency, duration, timezone)
VALUES (1, 1, 3, 'Allowance', 200.00, 'USD', 1, 'UTC'),
       (2, 1, 3, 'Deduction', -100.00, 'USD', 1, 'UTC');

-- PayrollPolicy
INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
VALUES (1, '2025-01-01', 'Overtime', 'Standard overtime'),
       (2, '2025-01-01', 'Lateness', 'Deduction for lateness');

-- OvertimePolicy
INSERT INTO OvertimePolicy (policy_id, weekday_rate_multiplier, weekend_rate_multiplier, max_hours_per_month)
VALUES (1, 1.5, 2.0, 20);

-- LatenessPolicy
INSERT INTO LatenessPolicy (policy_id, grace_period_mins, deduction_rate)
VALUES (2, 15, 0.1);

-- Additional Payroll Policies
INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
VALUES
(3, '2025-01-01', 'Bonus', 'Performance bonus rules'),
(4, '2025-01-01', 'Deduction', 'Absence deduction rules');

-- BonusPolicy
INSERT INTO BonusPolicy (policy_id, bonus_type, eligibility_criteria)
VALUES (3, 'Performance', 'Meet targets');

-- DeductionPolicy
INSERT INTO DeductionPolicy (policy_id, deduction_reason, calculation_mode)
VALUES (4, 'Absence', 'Per Day');

-- PayrollPolicy_ID
INSERT INTO PayrollPolicy_ID (payroll_id, policy_id)
VALUES (1, 1),
       (1, 2);

-- Payroll_Log
INSERT INTO Payroll_Log (payroll_log_id, payroll_id, actor, change_date, modification_type)
VALUES (1, 1, 4, '2025-02-01', 'Processed');

-- PayrollPeriod
INSERT INTO PayrollPeriod (payroll_period_id, payroll_id, start_date, end_date, status)
VALUES (1, 1, '2025-01-01', '2025-01-31', 'Closed');

-- Notification
INSERT INTO Notification (notification_id, message_content, timestamp, urgency, read_status, notification_type)
VALUES (1, 'Structure Change', '2025-01-15 10:00:00', 'High', 0, 'Alert'),
       (2, 'Leave Approved', '2025-03-01 12:00:00', 'Medium', 1, 'Info');

-- Employee_Notification
INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
VALUES (3, 1, 'Delivered', '2025-01-15 10:05:00'),
       (8, 2, 'Delivered', '2025-03-01 12:05:00');

-- EmployeeHierarchy
INSERT INTO EmployeeHierarchy (employee_id, manager_id, hierarchy_level)
VALUES (2, 1, 1),
       (3, 1, 1),
       (4, 1, 1),
       (5, 1, 1),
       (6, 5, 2),
       (7, 1, 1),
       (8, 5, 2),
       (9, 2, 2),
       (10, 1, 1);

-- Device
INSERT INTO Device (device_id, device_type, terminal_id, latitude, longitude, employee_id)
VALUES (1, 'Biometric', 'TERM001', 37.7749, -122.4194, 3),
       (2, 'Mobile', 'MOB001', 37.7749, -122.4194, 8);

-- AttendanceSource
INSERT INTO AttendanceSource (attendance_id, device_id, source_type, latitude, longitude, recorded_at)
VALUES (1, 1, 'Biometric', 37.7749, -122.4194, '2025-01-02 09:00:00'),
       (2, 2, 'App', 37.7749, -122.4194, '2025-01-02 13:00:00');

-- ShiftCycle
INSERT INTO ShiftCycle (cycle_id, cycle_name, description)
VALUES (1, 'Weekly', 'Standard weekly cycle'),
       (2, 'Monthly', 'Monthly rotation');

-- ShiftCycleAssignment
INSERT INTO ShiftCycleAssignment (cycle_id, shift_id, order_number)
VALUES (1, 1, 1),
       (1, 2, 2);

-- ApprovalWorkflow
INSERT INTO ApprovalWorkflow (workflow_id, workflow_type, threshold_amount, approver_role, created_by, status)
VALUES (1, 'Leave', 0.00, 'Manager', 2, 'Active'),
       (2, 'Reimbursement', 1000.00, 'Finance', 4, 'Active');

-- ApprovalWorkflowStep
INSERT INTO ApprovalWorkflowStep (workflow_id, step_number, role_id, action_required)
VALUES (1, 1, 4, 'Approve'),
       (2, 1, 3, 'Verify');

-- ManagerNotes
INSERT INTO ManagerNotes (note_id, employee_id, manager_id, note_content, created_at)
VALUES (1, 3, 5, 'Good performance', '2025-02-01 09:00:00'),
       (2, 6, 5, 'Needs training', '2025-03-01 09:00:00');

GO