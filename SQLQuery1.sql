USE HRMS;
GO
CREATE TABLE Position (
    position_id INT PRIMARY KEY,
    position_title VARCHAR(100),
    responsibilities TEXT,
    status VARCHAR(50)
);

CREATE TABLE PayGrade (
    pay_grade_id INT PRIMARY KEY,
    grade_name VARCHAR(50),
    min_salary DECIMAL(10,2),
    max_salary DECIMAL(10,2)
);

CREATE TABLE TaxForm (
    tax_form_id INT PRIMARY KEY,
    jurisdiction VARCHAR(100),
    validity_period VARCHAR(50),
    form_content TEXT
);

CREATE TABLE Currency (
    CurrencyCode VARCHAR(10) PRIMARY KEY,
    CurrencyName VARCHAR(100),
    ExchangeRate DECIMAL(10,4),
    CreatedDate DATE,
    LastUpdated DATE
);

CREATE TABLE SalaryType (
    salary_type_id INT PRIMARY KEY,
    type VARCHAR(50),
    payment_frequency VARCHAR(50),
    currency VARCHAR(10)
);

CREATE TABLE HourlySalaryType (
    salary_type_id INT PRIMARY KEY,
    hourly_rate DECIMAL(10,2),
    max_monthly_hours INT
);

CREATE TABLE MonthlySalaryType (
    salary_type_id INT PRIMARY KEY,
    tax_rule VARCHAR(100),
    contribution_scheme VARCHAR(100)
);

CREATE TABLE ContractSalaryType (
    salary_type_id INT PRIMARY KEY,
    contract_value DECIMAL(10,2),
    installment_details TEXT
);

CREATE TABLE Contract (
    contract_id INT PRIMARY KEY,
    type VARCHAR(50),
    start_date DATE,
    end_date DATE,
    current_state VARCHAR(50)
);

CREATE TABLE FullTimeContract (
    contract_id INT PRIMARY KEY,
    leave_entitlement INT,
    insurance_eligibility VARCHAR(100),
    weekly_working_hours INT
);

CREATE TABLE PartTimeContract (
    contract_id INT PRIMARY KEY,
    working_hours INT,
    hourly_rate DECIMAL(10,2)
);

CREATE TABLE ConsultantContract (
    contract_id INT PRIMARY KEY,
    project_scope TEXT,
    fees DECIMAL(10,2),
    payment_schedule VARCHAR(100)
);

CREATE TABLE InternshipContract (
    contract_id INT PRIMARY KEY,
    mentoring VARCHAR(100),
    evaluation VARCHAR(100),
    stipend_related DECIMAL(10,2)
);

CREATE TABLE Department (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100),
    purpose TEXT,
    department_head_id INT
);

CREATE TABLE Employee (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200),
    national_id VARCHAR(50),
    date_of_birth DATE,
    country_of_birth VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address VARCHAR(200),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    relationship VARCHAR(50),
    biography TEXT,
    profile_image VARCHAR(255),
    employment_progress TEXT,
    account_status VARCHAR(50),
    employment_status VARCHAR(50),
    hire_date DATE,
    is_active BIT,
    profile_completion INT,
    department_id INT,
    position_id INT,
    manager_id INT,
    contract_id INT,
    tax_form_id INT,
    salary_type_id INT,
    pay_grade_id INT
);

CREATE TABLE HRAdministrator (
    employee_id INT PRIMARY KEY,
    approval_level VARCHAR(50),
    record_access_scope VARCHAR(100),
    document_validation_rights VARCHAR(100)
);

CREATE TABLE SystemAdministrator (
    employee_id INT PRIMARY KEY,
    system_privilege_level VARCHAR(50),
    configurable_fields TEXT,
    audit_visibility_scope VARCHAR(100)
);

CREATE TABLE PayrollSpecialist (
    employee_id INT PRIMARY KEY,
    assigned_region VARCHAR(100),
    processing_frequency VARCHAR(50),
    last_processed_period DATE
);

CREATE TABLE LineManager (
    employee_id INT PRIMARY KEY,
    team_size INT,
    supervised_departments VARCHAR(200),
    approval_limit DECIMAL(10,2)
);

CREATE TABLE Skill (
    skill_id INT PRIMARY KEY,
    skill_name VARCHAR(100),
    description TEXT
);

CREATE TABLE Employee_Skill (
    employee_id INT,
    skill_id INT,
    proficiency_level VARCHAR(50),
    PRIMARY KEY (employee_id, skill_id)
);

CREATE TABLE Verification (
    verification_id INT PRIMARY KEY,
    verification_type VARCHAR(50),
    issuer VARCHAR(100),
    issue_date DATE,
    expiry_period INT
);

CREATE TABLE Employee_Verification (
    employee_id INT,
    verification_id INT,
    PRIMARY KEY (employee_id, verification_id)
);

CREATE TABLE Role (
    role_id INT PRIMARY KEY,
    role_name VARCHAR(100),
    purpose TEXT
);

CREATE TABLE Employee_Role (
    employee_id INT,
    role_id INT,
    assigned_date DATE,
    PRIMARY KEY (employee_id, role_id)
);

CREATE TABLE RolePermission (
    role_id INT,
    permission_name VARCHAR(100),
    allowed_action VARCHAR(50),
    PRIMARY KEY (role_id, permission_name)
);

CREATE TABLE Insurance (
    insurance_id INT PRIMARY KEY,
    type VARCHAR(50),
    contribution_rate DECIMAL(5,2),
    coverage TEXT
);

CREATE TABLE Termination (
    termination_id INT PRIMARY KEY,
    date DATE,
    reason TEXT,
    contract_id INT
);

CREATE TABLE Reimbursement (
    reimbursement_id INT PRIMARY KEY,
    type VARCHAR(50),
    claim_type VARCHAR(50),
    approval_date DATE,
    current_status VARCHAR(50),
    employee_id INT
);

CREATE TABLE Mission (
    mission_id INT PRIMARY KEY,
    destination VARCHAR(100),
    start_date DATE,
    end_date DATE,
    status VARCHAR(50),
    employee_id INT,
    manager_id INT
);

CREATE TABLE Leave (
    leave_id INT PRIMARY KEY,
    leave_type VARCHAR(50),
    leave_description TEXT
);

CREATE TABLE VacationLeave (
    leave_id INT PRIMARY KEY,
    carry_over_days INT,
    approving_manager INT
);

CREATE TABLE SickLeave (
    leave_id INT PRIMARY KEY,
    medical_cert_required BIT,
    physician_id INT
);

CREATE TABLE ProbationLeave (
    leave_id INT PRIMARY KEY,
    eligibility_start_date DATE,
    probation_period INT
);

CREATE TABLE HolidayLeave (
    leave_id INT PRIMARY KEY,
    holiday_name VARCHAR(100),
    official_recognition BIT,
    regional_scope VARCHAR(100)
);

CREATE TABLE LeavePolicy (
    policy_id INT PRIMARY KEY,
    name VARCHAR(100),
    purpose TEXT,
    eligibility_rules TEXT,
    notice_period INT,
    special_leave_type VARCHAR(50),
    reset_on_new_year BIT
);

CREATE TABLE LeaveRequest (
    request_id INT PRIMARY KEY,
    employee_id INT,
    leave_id INT,
    justification TEXT,
    duration INT,
    approval_timing VARCHAR(50),
    status VARCHAR(50)
);

CREATE TABLE LeaveEntitlement (
    employee_id INT,
    leave_type_id INT,
    entitlement INT,
    PRIMARY KEY (employee_id, leave_type_id)
);

CREATE TABLE LeaveDocument (
    document_id INT PRIMARY KEY,
    leave_request_id INT,
    file_path VARCHAR(255),
    uploaded_at DATETIME
);

CREATE TABLE ShiftSchedule (
    shift_id INT PRIMARY KEY,
    name VARCHAR(50),
    type VARCHAR(50),
    start_time TIME,
    end_time TIME,
    break_duration INT,
    shift_date DATE,
    status VARCHAR(50)
);

CREATE TABLE ShiftAssignment (
    assignment_id INT PRIMARY KEY,
    employee_id INT,
    shift_id INT,
    start_date DATE,
    end_date DATE,
    status VARCHAR(50)
);

CREATE TABLE Exception (
    exception_id INT PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    date DATE,
    status VARCHAR(50)
);

CREATE TABLE Employee_Exception (
    employee_id INT,
    exception_id INT,
    PRIMARY KEY (employee_id, exception_id)
);

CREATE TABLE Attendance (
    attendance_id INT PRIMARY KEY,
    employee_id INT,
    shift_id INT,
    entry_time DATETIME,
    exit_time DATETIME,
    duration INT,
    login_method VARCHAR(50),
    logout_method VARCHAR(50),
    exception_id INT
);

CREATE TABLE AttendanceLog (
    attendance_log_id INT PRIMARY KEY,
    attendance_id INT,
    actor INT,
    timestamp DATETIME,
    reason TEXT
);

CREATE TABLE AttendanceCorrectionRequest (
    request_id INT PRIMARY KEY,
    employee_id INT,
    date DATE,
    correction_type VARCHAR(50),
    reason TEXT,
    status VARCHAR(50),
    recorded_by INT
);

CREATE TABLE Payroll (
    payroll_id INT PRIMARY KEY,
    employee_id INT,
    taxes DECIMAL(10,2),
    period_start DATE,
    period_end DATE,
    base_amount DECIMAL(10,2),
    adjustments DECIMAL(10,2),
    contributions DECIMAL(10,2),
    actual_pay DECIMAL(10,2),
    net_salary DECIMAL(10,2),
    payment_date DATE
);

CREATE TABLE AllowanceDeduction (
    ad_id INT PRIMARY KEY,
    payroll_id INT,
    employee_id INT,
    type VARCHAR(50),
    amount DECIMAL(10,2),
    currency VARCHAR(10),
    duration INT,
    timezone VARCHAR(50)
);

CREATE TABLE PayrollPolicy (
    policy_id INT PRIMARY KEY,
    effective_date DATE,
    type VARCHAR(50),
    description TEXT
);

CREATE TABLE OvertimePolicy (
    policy_id INT PRIMARY KEY,
    weekday_rate_multiplier DECIMAL(5,2),
    weekend_rate_multiplier DECIMAL(5,2),
    max_hours_per_month INT
);

CREATE TABLE LatenessPolicy (
    policy_id INT PRIMARY KEY,
    grace_period_mins INT,
    deduction_rate DECIMAL(5,2)
);

CREATE TABLE BonusPolicy (
    policy_id INT PRIMARY KEY,
    bonus_type VARCHAR(50),
    eligibility_criteria TEXT
);

CREATE TABLE DeductionPolicy (
    policy_id INT PRIMARY KEY,
    deduction_reason VARCHAR(100),
    calculation_mode VARCHAR(50)
);

CREATE TABLE PayrollPolicy_ID (
    payroll_id INT,
    policy_id INT,
    PRIMARY KEY (payroll_id, policy_id)
);

CREATE TABLE Payroll_Log (
    payroll_log_id INT PRIMARY KEY,
    payroll_id INT,
    actor INT,
    change_date DATE,
    modification_type VARCHAR(50)
);

CREATE TABLE PayrollPeriod (
    payroll_period_id INT PRIMARY KEY,
    payroll_id INT,
    start_date DATE,
    end_date DATE,
    status VARCHAR(50)
);

CREATE TABLE Notification (
    notification_id INT PRIMARY KEY,
    message_content TEXT,
    timestamp DATETIME,
    urgency VARCHAR(50),
    read_status BIT,
    notification_type VARCHAR(50)
);

CREATE TABLE Employee_Notification (
    employee_id INT,
    notification_id INT,
    delivery_status VARCHAR(50),
    delivered_at DATETIME,
    PRIMARY KEY (employee_id, notification_id)
);

CREATE TABLE EmployeeHierarchy (
    employee_id INT,
    manager_id INT,
    hierarchy_level INT,
    PRIMARY KEY (employee_id, manager_id)
);

CREATE TABLE Device (
    device_id INT PRIMARY KEY,
    device_type VARCHAR(50),
    terminal_id VARCHAR(50),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    employee_id INT
);

CREATE TABLE AttendanceSource (
    attendance_id INT,
    device_id INT,
    source_type VARCHAR(50),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    recorded_at DATETIME,
    PRIMARY KEY (attendance_id, device_id)
);

CREATE TABLE ShiftCycle (
    cycle_id INT PRIMARY KEY,
    cycle_name VARCHAR(100),
    description TEXT
);

CREATE TABLE ShiftCycleAssignment (
    cycle_id INT,
    shift_id INT,
    order_number INT,
    PRIMARY KEY (cycle_id, shift_id)
);

CREATE TABLE ApprovalWorkflow (
    workflow_id INT PRIMARY KEY,
    workflow_type VARCHAR(50),
    threshold_amount DECIMAL(10,2),
    approver_role VARCHAR(50),
    created_by INT,
    status VARCHAR(50)
);

CREATE TABLE ApprovalWorkflowStep (
    workflow_id INT,
    step_number INT,
    role_id INT,
    action_required VARCHAR(50),
    PRIMARY KEY (workflow_id, step_number)
);

CREATE TABLE ManagerNotes (
    note_id INT PRIMARY KEY,
    employee_id INT,
    manager_id INT,
    note_content TEXT,
    created_at DATETIME
);

-- Now add foreign key constraints

ALTER TABLE Employee ADD CONSTRAINT FK_Employee_Position FOREIGN KEY (position_id) REFERENCES Position(position_id);
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_PayGrade FOREIGN KEY (pay_grade_id) REFERENCES PayGrade(pay_grade_id);
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_TaxForm FOREIGN KEY (tax_form_id) REFERENCES TaxForm(tax_form_id);
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_Department FOREIGN KEY (department_id) REFERENCES Department(department_id);
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_Manager FOREIGN KEY (manager_id) REFERENCES Employee(employee_id);
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_SalaryType FOREIGN KEY (salary_type_id) REFERENCES SalaryType(salary_type_id);
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id);

ALTER TABLE HRAdministrator ADD CONSTRAINT FK_HRAdministrator_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);

ALTER TABLE SystemAdministrator ADD CONSTRAINT FK_SystemAdministrator_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);

ALTER TABLE PayrollSpecialist ADD CONSTRAINT FK_PayrollSpecialist_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);

ALTER TABLE LineManager ADD CONSTRAINT FK_LineManager_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);

ALTER TABLE Department ADD CONSTRAINT FK_Department_Employee FOREIGN KEY (department_head_id) REFERENCES Employee(employee_id);

ALTER TABLE Employee_Skill ADD CONSTRAINT FK_Employee_Skill_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE Employee_Skill ADD CONSTRAINT FK_Employee_Skill_Skill FOREIGN KEY (skill_id) REFERENCES Skill(skill_id);

ALTER TABLE Employee_Verification ADD CONSTRAINT FK_Employee_Verification_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE Employee_Verification ADD CONSTRAINT FK_Employee_Verification_Verification FOREIGN KEY (verification_id) REFERENCES Verification(verification_id);

ALTER TABLE Employee_Role ADD CONSTRAINT FK_Employee_Role_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE Employee_Role ADD CONSTRAINT FK_Employee_Role_Role FOREIGN KEY (role_id) REFERENCES Role(role_id);

ALTER TABLE RolePermission ADD CONSTRAINT FK_RolePermission_Role FOREIGN KEY (role_id) REFERENCES Role(role_id);

ALTER TABLE FullTimeContract ADD CONSTRAINT FK_FullTimeContract_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id);

ALTER TABLE PartTimeContract ADD CONSTRAINT FK_PartTimeContract_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id);

ALTER TABLE ConsultantContract ADD CONSTRAINT FK_ConsultantContract_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id);

ALTER TABLE InternshipContract ADD CONSTRAINT FK_InternshipContract_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id);

ALTER TABLE Termination ADD CONSTRAINT FK_Termination_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id);

ALTER TABLE Reimbursement ADD CONSTRAINT FK_Reimbursement_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);

ALTER TABLE Mission ADD CONSTRAINT FK_Mission_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE Mission ADD CONSTRAINT FK_Mission_Manager FOREIGN KEY (manager_id) REFERENCES Employee(employee_id);

-- For Leave subtypes, assuming they reference Leave
ALTER TABLE VacationLeave ADD CONSTRAINT FK_VacationLeave_Leave FOREIGN KEY (leave_id) REFERENCES Leave(leave_id);
ALTER TABLE SickLeave ADD CONSTRAINT FK_SickLeave_Leave FOREIGN KEY (leave_id) REFERENCES Leave(leave_id);
ALTER TABLE ProbationLeave ADD CONSTRAINT FK_ProbationLeave_Leave FOREIGN KEY (leave_id) REFERENCES Leave(leave_id);
ALTER TABLE HolidayLeave ADD CONSTRAINT FK_HolidayLeave_Leave FOREIGN KEY (leave_id) REFERENCES Leave(leave_id);

ALTER TABLE LeaveRequest ADD CONSTRAINT FK_LeaveRequest_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE LeaveRequest ADD CONSTRAINT FK_LeaveRequest_Leave FOREIGN KEY (leave_id) REFERENCES Leave(leave_id);

ALTER TABLE LeaveEntitlement ADD CONSTRAINT FK_LeaveEntitlement_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE LeaveEntitlement ADD CONSTRAINT FK_LeaveEntitlement_Leave FOREIGN KEY (leave_type_id) REFERENCES Leave(leave_id);

ALTER TABLE LeaveDocument ADD CONSTRAINT FK_LeaveDocument_LeaveRequest FOREIGN KEY (leave_request_id) REFERENCES LeaveRequest(request_id);

ALTER TABLE Attendance ADD CONSTRAINT FK_Attendance_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE Attendance ADD CONSTRAINT FK_Attendance_ShiftSchedule FOREIGN KEY (shift_id) REFERENCES ShiftSchedule(shift_id);
ALTER TABLE Attendance ADD CONSTRAINT FK_Attendance_Exception FOREIGN KEY (exception_id) REFERENCES Exception(exception_id);

ALTER TABLE AttendanceLog ADD CONSTRAINT FK_AttendanceLog_Attendance FOREIGN KEY (attendance_id) REFERENCES Attendance(attendance_id);

ALTER TABLE AttendanceCorrectionRequest ADD CONSTRAINT FK_AttendanceCorrectionRequest_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE AttendanceCorrectionRequest ADD CONSTRAINT FK_AttendanceCorrectionRequest_RecordedBy FOREIGN KEY (recorded_by) REFERENCES Employee(employee_id);

ALTER TABLE ShiftAssignment ADD CONSTRAINT FK_ShiftAssignment_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE ShiftAssignment ADD CONSTRAINT FK_ShiftAssignment_ShiftSchedule FOREIGN KEY (shift_id) REFERENCES ShiftSchedule(shift_id);

ALTER TABLE Employee_Exception ADD CONSTRAINT FK_Employee_Exception_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE Employee_Exception ADD CONSTRAINT FK_Employee_Exception_Exception FOREIGN KEY (exception_id) REFERENCES Exception(exception_id);

ALTER TABLE Payroll ADD CONSTRAINT FK_Payroll_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);

ALTER TABLE SalaryType ADD CONSTRAINT FK_SalaryType_Currency FOREIGN KEY (currency) REFERENCES Currency(CurrencyCode);

ALTER TABLE HourlySalaryType ADD CONSTRAINT FK_HourlySalaryType_SalaryType FOREIGN KEY (salary_type_id) REFERENCES SalaryType(salary_type_id);

ALTER TABLE MonthlySalaryType ADD CONSTRAINT FK_MonthlySalaryType_SalaryType FOREIGN KEY (salary_type_id) REFERENCES SalaryType(salary_type_id);

ALTER TABLE ContractSalaryType ADD CONSTRAINT FK_ContractSalaryType_SalaryType FOREIGN KEY (salary_type_id) REFERENCES SalaryType(salary_type_id);

ALTER TABLE AllowanceDeduction ADD CONSTRAINT FK_AllowanceDeduction_Payroll FOREIGN KEY (payroll_id) REFERENCES Payroll(payroll_id);
ALTER TABLE AllowanceDeduction ADD CONSTRAINT FK_AllowanceDeduction_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE AllowanceDeduction ADD CONSTRAINT FK_AllowanceDeduction_Currency FOREIGN KEY (currency) REFERENCES Currency(CurrencyCode);

ALTER TABLE OvertimePolicy ADD CONSTRAINT FK_OvertimePolicy_PayrollPolicy FOREIGN KEY (policy_id) REFERENCES PayrollPolicy(policy_id);

ALTER TABLE LatenessPolicy ADD CONSTRAINT FK_LatenessPolicy_PayrollPolicy FOREIGN KEY (policy_id) REFERENCES PayrollPolicy(policy_id);

ALTER TABLE BonusPolicy ADD CONSTRAINT FK_BonusPolicy_PayrollPolicy FOREIGN KEY (policy_id) REFERENCES PayrollPolicy(policy_id);

ALTER TABLE DeductionPolicy ADD CONSTRAINT FK_DeductionPolicy_PayrollPolicy FOREIGN KEY (policy_id) REFERENCES PayrollPolicy(policy_id);

ALTER TABLE PayrollPolicy_ID ADD CONSTRAINT FK_PayrollPolicy_ID_Payroll FOREIGN KEY (payroll_id) REFERENCES Payroll(payroll_id);
ALTER TABLE PayrollPolicy_ID ADD CONSTRAINT FK_PayrollPolicy_ID_Policy FOREIGN KEY (policy_id) REFERENCES PayrollPolicy(policy_id);

ALTER TABLE Payroll_Log ADD CONSTRAINT FK_Payroll_Log_Payroll FOREIGN KEY (payroll_id) REFERENCES Payroll(payroll_id);

ALTER TABLE PayrollPeriod ADD CONSTRAINT FK_PayrollPeriod_Payroll FOREIGN KEY (payroll_id) REFERENCES Payroll(payroll_id);

ALTER TABLE Employee_Notification ADD CONSTRAINT FK_Employee_Notification_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE Employee_Notification ADD CONSTRAINT FK_Employee_Notification_Notification FOREIGN KEY (notification_id) REFERENCES Notification(notification_id);

ALTER TABLE EmployeeHierarchy ADD CONSTRAINT FK_EmployeeHierarchy_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE EmployeeHierarchy ADD CONSTRAINT FK_EmployeeHierarchy_Manager FOREIGN KEY (manager_id) REFERENCES Employee(employee_id);

ALTER TABLE Device ADD CONSTRAINT FK_Device_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);

ALTER TABLE AttendanceSource ADD CONSTRAINT FK_AttendanceSource_Attendance FOREIGN KEY (attendance_id) REFERENCES Attendance(attendance_id);
ALTER TABLE AttendanceSource ADD CONSTRAINT FK_AttendanceSource_Device FOREIGN KEY (device_id) REFERENCES Device(device_id);

ALTER TABLE ShiftCycleAssignment ADD CONSTRAINT FK_ShiftCycleAssignment_ShiftCycle FOREIGN KEY (cycle_id) REFERENCES ShiftCycle(cycle_id);
ALTER TABLE ShiftCycleAssignment ADD CONSTRAINT FK_ShiftCycleAssignment_ShiftSchedule FOREIGN KEY (shift_id) REFERENCES ShiftSchedule(shift_id);

ALTER TABLE ApprovalWorkflowStep ADD CONSTRAINT FK_ApprovalWorkflowStep_ApprovalWorkflow FOREIGN KEY (workflow_id) REFERENCES ApprovalWorkflow(workflow_id);
ALTER TABLE ApprovalWorkflowStep ADD CONSTRAINT FK_ApprovalWorkflowStep_Role FOREIGN KEY (role_id) REFERENCES Role(role_id);

ALTER TABLE ManagerNotes ADD CONSTRAINT FK_ManagerNotes_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id);
ALTER TABLE ManagerNotes ADD CONSTRAINT FK_ManagerNotes_Manager FOREIGN KEY (manager_id) REFERENCES Employee(employee_id);