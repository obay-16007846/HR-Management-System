# Comprehensive Human Resource Management System (HRMS)
### German International University of Applied Sciences  
### Informatics and Computer Science – Winter 2025  

---

## 1. Project Overview
This project implements a **comprehensive Human Resource Management System (HRMS)** by designing a complete relational database schema.  
The goal is to build a **centralized, intelligent platform** that automates and streamlines core HR functions across an organization.

The database supports and integrates:

- Employee profiling  
- Attendance tracking  
- Payroll computation  
- Leave administration  
- Shift scheduling  
- Contract management  

The platform ensures:

- **Consistency** in HR operations  
- **Transparency** in workflow handling  
- **Accuracy** in record-keeping  
- **Policy enforcement**  
- **Decision-making analytics**  

It supports multiple system user roles—**employees, managers, HR administrators, payroll specialists, and system administrators**—each with specific permissions and responsibilities.
## Entity-Relationship Diagram (ERD)

![HRMS ERD](./ERD/ERD.png)

---

## 2. System Requirements

The HRMS consists of several key entities.  
Each subsection below summarises one major entity exactly as described in the project documentation.

---

### 2.1 Employee
Represents every individual working in the organization.  
Includes:

- Personal data (full name, national ID, date of birth, country of birth)  
- Contact info (email, phone, emergency contact)  
- Employment attributes (department, position, manager, contract, salary type, tax form)  
- Additional fields like biography, profile image, employment progress, account status, hire date, activation status, and profile completeness  

Employees also extend into **subcategories** with specialized privileges:

#### • HR Administrator
- Approval level (Department-Level, Organization-Wide)  
- Record access scope (Employee Profiles, Payroll, Leave Requests)  
- Document validation rights  

#### • System Administrator
- System privilege level (Super Admin, Module Admin)  
- Configurable fields list  
- Audit visibility scope (System Logs, Payroll Audits, Activity Logs)

#### • Payroll Specialist
- Assigned region  
- Payroll processing frequency  
- Last processed period  

#### • Line Manager
- Team size  
- Supervised departments  
- Approval limit  

---

### 2.2 Role
Defines levels of access and system permissions.  
Employees may hold multiple roles simultaneously.

---

### 2.3 Department
Represents organizational functional units.  
Each employee belongs to one department.

---

### 2.4 Position
Represents job titles and responsibilities.  
Each employee is assigned exactly one position.

---

### 2.5 Contract
Defines employment terms between the organization and an employee.  
Describes:

- Contract type  
- Start and end dates  
- Current state  

Includes specialized subcontracts:

#### • Full-Time Contract  
Leave entitlement, insurance eligibility, weekly working hours.

#### • Part-Time Contract  
Hourly rate, monthly working limits.

#### • Consultant Contract  
Project scope, fees, payment schedules.

#### • Internship Contract  
Mentoring assignments, evaluation structure, stipend.

---

### 2.6 Skill
Describes employee skills.  
Supports many-to-many mapping between employees and skills.

---

### 2.7 Verification
Tracks certifications or credentials:  
Type, issuer, issue date, expiry period.

---

### 2.8 Attendance
Tracks daily presence and working hours:  
Entry & exit times, duration, login/logout method, status, and linked shift.

---

### 2.9 Shift Schedule
Defines organizational shifts:  
Name, type, start/end times, breaks, date, activation status.

---

### 2.10 Leave
Defines leave categories. Includes subtypes:

- **Vacation Leave** (carry-over rules, approving manager)  
- **Sick Leave** (medical certification requirements, physician ID)  
- **Probation Leave** (eligibility start, probation duration)  
- **Holiday Leave** (holiday name, recognition, regional scope)  

---

### 2.11 Leave Request
Represents employee-initiated leave applications.  
Includes justification, duration, status, approval timing.

---

### 2.12 Leave Policy
Defines rules for leave eligibility, purpose, required notice period, and special leave categories.

---

### 2.13 Payroll
Manages compensation calculations:  
Payroll period, base pay, taxes, contributions, adjustments, net salary.

---

### 2.14 Allowance and Deduction
Provides granular financial adjustments per payroll cycle.  
Tracks type, amount, duration, currency, timezone.

---

### 2.15 Salary Type
Defines how compensation is structured: Monthly, Hourly, or Contract-based.

Includes subtypes:

#### • Hourly Salary Type  
Hourly rate and maximum monthly hours.

#### • Monthly Salary Type  
Tax rules and contribution schemes.

#### • Contract Salary Type  
Project value and installment rules.

---

### 2.16 Payroll Policy
Defines rules impacting payroll, including subpolicies:

#### • Overtime Policy  
Rate multipliers, hour limits.

#### • Lateness Policy  
Grace periods, deduction rates.

#### • Bonus Policy  
Eligibility conditions and bonus types.

#### • Deduction Policy  
Deduction reasons and calculation modes.

---

### 2.17 Insurance
Defines insurance schemes: Coverage details, contribution rates, benefit categories.  
Linked to contracts.

---

### 2.18 Tax Form
Defines jurisdiction-specific tax compliance rules, form content, validity periods.

---

### 2.19 Notification
Sends alerts to employees: Content, timestamp, urgency, read status.

---

### 2.20 Mission
Represents off-site assignments or business trips:  
Destination, period, status, assigning manager.

---

### 2.21 Exception
Represents special non-working days or holidays.  
Includes exception name, category, date, and status.

---

### 2.22 Reimbursement
Records employee expense claims:  
Claim type, value, status, approval data, linked employee.

---

### 2.23 Termination
Represents closure of employment:  
Reason, termination date, linked contract.

---

### 2.24 Payroll Log
Tracks payroll modifications:  
Actor, change date, modification type.

---

### 2.25 Attendance Log
Captures updates or corrections to attendance records:  
Actor, timestamp, reason for modification.

---

## 3. Project Structure (Repository Layout)
```
HRMS-Database-Project/
│
├── ERD/
│ ├── project.erdplus
│ └── project db.erdplus
│
├── SQL/
│ ├── SQLQuery1_CREATION.sql
│ ├── SQLQuery2_INSERTION.sql
│ └── SQLQuery3_PROCEDURE.sql
│
├── README.md
└── .gitignore
```


