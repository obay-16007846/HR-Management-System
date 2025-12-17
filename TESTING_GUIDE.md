# HRMS Milestone 3 - Comprehensive Testing Guide

This guide provides step-by-step instructions to test every feature listed in the evaluation PDF.

## Prerequisites
- Application running on `localhost:5115` (or your configured port)
- Database populated with test data
- Multiple test accounts ready:
  - System Admin account
  - HR Admin account
  - Line Manager account
  - Regular Employee account

---

## GENERAL COMPONENT

### 1. Self Registration Backend
**Test Steps:**
1. Navigate to `/Account/Register`
2. Fill in the registration form:
   - First Name: "Test"
   - Last Name: "Admin"
   - Email: "testadmin@test.com" (use unique email)
   - Phone: "1234567890"
   - National ID: "123456789" (this becomes password)
   - Department: Select any department
   - Role: Select "System Admin", "HR Admin", or "Line Manager"
3. Submit the form
4. **Expected:** Account created successfully, redirected to LoginSuccess page
5. **Backend Check:** Verify in database that employee record exists with correct role assignment

### 2. Self Registration Frontend
**Test Steps:**
1. Navigate to `/Account/Register`
2. Verify form fields are displayed correctly
3. Test form validation:
   - Submit empty form → Should show error messages
   - Submit with invalid email → Should show error
   - Submit with missing required fields → Should show specific errors
4. **Expected:** Form validation works, error messages display properly

### 3. Self Registration Integration
**Test Steps:**
1. Complete self-registration (as above)
2. After registration, verify you are automatically logged in
3. Check that you can access pages appropriate to your role
4. Logout and login again with the same credentials
5. **Expected:** Registration → Auto-login → Role-based access works → Manual login works

### 4. Admin-Created Accounts Backend
**Test Steps:**
1. Login as System Admin
2. Navigate to `/Admin/CreateEmployee` or `/HR/CreateEmployee`
3. Fill form:
   - First Name, Last Name, Email, Phone
   - Department ID
   - Role (System Admin can create any role)
4. Submit
5. **Expected:** Employee created, check database for new record
6. **Test HR Admin:** Login as HR Admin, try creating System Admin → Should be forbidden

### 5. Admin-Created Accounts Frontend
**Test Steps:**
1. Login as System Admin
2. Navigate to create employee page
3. Verify form displays correctly
4. Test validation (empty fields, invalid inputs)
5. **Expected:** Form works, validation messages appear

### 6. Admin-Created Accounts Integration
**Test Steps:**
1. Admin creates employee account
2. New employee receives email (if implemented) or notification
3. New employee logs in with email and national ID
4. First-time login flow works (if implemented)
5. **Expected:** Creation → Notification → First login → Profile completion

### 7. Login System Credential Validation Backend
**Test Steps:**
1. Navigate to `/Account/Login`
2. Test invalid credentials:
   - Wrong email → Should return error
   - Wrong password (national ID) → Should return error
   - Empty fields → Should return error
3. Test valid credentials → Should login successfully
4. **Backend Check:** Verify SQL query validates email and national_id correctly

### 8. Login System Credential Validation Frontend
**Test Steps:**
1. Navigate to `/Account/Login`
2. Test form validation:
   - Submit empty → Error messages
   - Invalid email format → Error message
   - Test error message display
3. **Expected:** Frontend validation works before backend call

### 9. Login System Credential Validation Integration
**Test Steps:**
1. Enter valid credentials
2. Verify login redirects correctly
3. Verify session/cookie is set
4. Verify user can access protected pages
5. Logout and verify session cleared
6. **Expected:** Login → Session → Access → Logout → No access

### 10. Role-Based Access Backend
**Test Steps:**
1. Login as System Admin → Access `/Admin/AssignRole` → Should work
2. Login as HR Admin → Access `/Admin/AssignRole` → Should return 403 Forbidden
3. Login as Employee → Access `/HR/IncompleteProfiles` → Should return 403
4. **Backend Check:** Verify `[Authorize(Roles = "...")]` attributes work correctly

### 11. Role-Based Access Frontend
**Test Steps:**
1. Login as different roles
2. Check navigation menu shows/hides based on role
3. Verify buttons/links only appear for authorized roles
4. **Expected:** UI adapts to user role

### 12. Role-Based Access Integration
**Test Steps:**
1. Login as System Admin → Verify can access all admin pages
2. Login as HR Admin → Verify can access HR pages but not System Admin pages
3. Login as Manager → Verify can access manager pages only
4. Login as Employee → Verify can access employee pages only
5. Try accessing unauthorized URLs directly → Should redirect to AccessDenied
6. **Expected:** Complete role-based access control works end-to-end

### 13. Profile Editing Backend
**Test Steps:**
1. Login as any user
2. Navigate to `/Employee/EditMyProfile`
3. Update profile fields (phone, address, emergency contacts, etc.)
4. Submit
5. **Backend Check:** Verify database updated correctly

### 14. Profile Editing Frontend
**Test Steps:**
1. Navigate to edit profile page
2. Verify form pre-populated with current data
3. Make changes and submit
4. Verify success message appears
5. **Expected:** Form works, data displays correctly

### 15. Profile Editing Integration
**Test Steps:**
1. Edit profile → Save
2. View profile → Verify changes reflected
3. Logout and login → Verify changes persist
4. **Expected:** Edit → Save → View → Persist

### 16. Profile Picture Bonus Backend
**Test Steps:**
1. Navigate to profile edit page
2. Upload an image file
3. Submit
4. **Backend Check:** Verify file saved in wwwroot/uploads and path stored in database

### 17. Profile Picture Bonus Frontend
**Test Steps:**
1. Navigate to profile edit
2. Verify file upload input appears
3. Select image and upload
4. Verify image displays after upload
5. **Expected:** Upload works, image displays

### 18. Profile Picture Bonus Integration
**Test Steps:**
1. Upload profile picture
2. View profile → Picture displays
3. View from different pages → Picture displays
4. **Expected:** Upload → Display → Persist across pages

---

## COMPONENT 1 - EMPLOYEE PROFILES & CONTRACTS MANAGEMENT

### 19. Admin Viewing Employee Profile Backend
**Test Steps:**
1. Login as System Admin or HR Admin
2. Navigate to `/Employee/Index` or search for employee
3. Click on employee → View profile
4. **Backend Check:** Verify query retrieves all employee data correctly

### 20. Admin Viewing Employee Profile Frontend
**Test Steps:**
1. Login as Admin
2. View employee profile page
3. Verify all fields display correctly (name, email, department, etc.)
4. **Expected:** Profile displays all information clearly

### 21. Admin Viewing Employee Profile Integration
**Test Steps:**
1. Admin searches for employee
2. Clicks employee name
3. Views full profile
4. Can navigate back to list
5. **Expected:** Search → View → Navigate works seamlessly

### 22. Manager Viewing Team Backend
**Test Steps:**
1. Login as Line Manager
2. Navigate to team view page (check navigation menu)
3. **Backend Check:** Verify query filters employees by manager_id

### 23. Manager Viewing Team Frontend
**Test Steps:**
1. Login as Manager
2. View team page
3. Verify only team members displayed
4. **Expected:** Team list shows correctly

### 24. Manager Viewing Team Integration
**Test Steps:**
1. Manager views team
2. Clicks team member → Views profile
3. Can navigate between team members
4. **Expected:** Team view → Individual profiles → Navigation works

### 25. Emergency Contacts Update Backend
**Test Steps:**
1. Login as Employee
2. Navigate to `/Employee/EditMyProfile`
3. Update emergency contact fields (name, phone, relationship)
4. Submit
5. **Backend Check:** Verify emergency contact data updated in database

### 26. Emergency Contacts Update Frontend
**Test Steps:**
1. Navigate to edit profile
2. Find emergency contact section
3. Update fields
4. Submit and verify success message
5. **Expected:** Form works, validation works

### 27. Emergency Contacts Update Integration
**Test Steps:**
1. Update emergency contacts
2. View profile → Verify contacts updated
3. Logout/login → Verify persists
4. **Expected:** Update → View → Persist

### 28. System Role Assignment Backend
**Test Steps:**
1. Login as System Admin
2. Navigate to `/Admin/AssignRole?id={employeeId}`
3. Add role to employee (e.g., assign "HR Admin" role)
4. **Backend Check:** Verify Employee_Role table updated

### 29. System Role Assignment Frontend
**Test Steps:**
1. Navigate to assign role page
2. Verify current roles displayed
3. Add new role → Verify appears in list
4. Remove role → Verify removed from list
5. **Expected:** UI updates correctly

### 30. System Role Assignment Integration
**Test Steps:**
1. System Admin assigns role to employee
2. Employee logs out and logs back in
3. Verify employee now has access to new role's pages
4. **Expected:** Assignment → Login → New access works

### 31. Manage Profile Completeness Backend
**Test Steps:**
1. Login as HR Admin
2. Navigate to `/HR/IncompleteProfiles`
3. View list of incomplete profiles
4. Click "Complete Profile" for an employee
5. Update profile fields to increase completeness
6. **Backend Check:** Verify profile_completion percentage updated

### 32. Manage Profile Completeness Frontend
**Test Steps:**
1. Navigate to incomplete profiles page
2. Verify list displays correctly
3. Click employee → Edit profile
4. Fill missing fields
5. **Expected:** List → Edit → Update works

### 33. Manage Profile Completeness Integration
**Test Steps:**
1. HR Admin views incomplete profiles
2. Edits employee profile
3. Completes missing information
4. Views profile again → Completeness increased
5. **Expected:** List → Edit → Complete → Verify

### 34. Department Employee View Backend
**Test Steps:**
1. Login as Admin/Manager
2. Navigate to department view or employee list filtered by department
3. **Backend Check:** Verify query filters by department_id correctly

### 35. Department Employee View Frontend
**Test Steps:**
1. View department employees page
2. Verify employees grouped by department
3. **Expected:** Display organized by department

### 36. Department Employee View Integration
**Test Steps:**
1. Select department from dropdown/list
2. View employees in that department
3. Click employee → View profile
4. **Expected:** Filter → View → Navigate works

### 37. Contract Creation Backend
**Test Steps:**
1. Login as HR Admin
2. Navigate to `/HR/CreateContract`
3. Fill form:
   - Employee ID
   - Contract Type (Full-time, Part-time, etc.)
   - Start Date
   - End Date
4. Submit
5. **Backend Check:** Verify contract created in database, linked to employee

### 38. Contract Creation Frontend
**Test Steps:**
1. Navigate to create contract page
2. Verify form displays correctly
3. Fill and submit
4. Verify success message
5. **Expected:** Form works, validation works

### 39. Contract Creation Integration
**Test Steps:**
1. HR Admin creates contract
2. Employee receives notification (check notifications)
3. Employee views contract at `/Employee/MyContract`
4. **Expected:** Create → Notify → View works

### 40. Contract Renewal Backend
**Test Steps:**
1. Login as HR Admin
2. Navigate to `/HR/ExpiringContracts`
3. Click "Renew" on an expiring contract
4. Update dates and submit
5. **Backend Check:** Verify old contract expired, new contract created

### 41. Contract Renewal Frontend
**Test Steps:**
1. Navigate to renew contract page
2. Verify form pre-populated with current contract data
3. Update dates
4. Submit
5. **Expected:** Form works, data pre-filled

### 42. Contract Renewal Integration
**Test Steps:**
1. HR Admin renews contract
2. Employee receives notification
3. Employee views updated contract
4. Old contract shows as expired
5. **Expected:** Renew → Notify → View → Status updated

### 43. Contract Expiry Tracking Backend
**Test Steps:**
1. Login as HR Admin
2. Navigate to `/HR/ExpiringContracts`
3. **Backend Check:** Verify query retrieves contracts expiring within 30 days AND expired contracts

### 44. Contract Expiry Tracking Frontend
**Test Steps:**
1. View expiring contracts page
2. Verify list shows:
   - Active contracts expiring soon (warning badge)
   - Expired contracts (danger badge)
3. **Expected:** List displays correctly with status indicators

### 45. Contract Expiry Tracking Integration
**Test Steps:**
1. View expiring contracts
2. Filter/sort by expiry date
3. Click renew → Renew contract
4. Return to list → Verify updated
5. **Expected:** View → Filter → Renew → Update works

### 46. Send Contract Update Notification Backend
**Test Steps:**
1. Create or renew a contract
2. **Backend Check:** Verify notification created in database with correct employee_id and message

### 47. Send Contract Update Notification Frontend
**Test Steps:**
1. Create/renew contract
2. Check employee's notification page
3. Verify notification appears
4. **Expected:** Notification displays correctly

### 48. Send Contract Update Notification Integration
**Test Steps:**
1. HR Admin creates contract
2. Employee logs in
3. Employee sees notification badge/indicator
4. Employee clicks notifications → Sees contract notification
5. **Expected:** Create → Notify → Display → View works

---

## COMPONENT 2 - ATTENDANCE & SHIFT MANAGEMENT

### 49. Shift Type Creation Backend
**Test Steps:**
1. Login as System Admin
2. Navigate to `/Shift/CreateShiftType`
3. Fill form:
   - Name: "Morning Shift"
   - Type: "Normal"
   - Start Time: 09:00
   - End Time: 17:00
   - Break Duration: 60
4. Submit
5. **Backend Check:** Verify shift created in ShiftSchedule table

### 50. Shift Type Creation Frontend
**Test Steps:**
1. Navigate to create shift type page
2. Verify form displays correctly
3. Test validation (empty fields, invalid times)
4. Submit and verify success
5. **Expected:** Form works, validation works

### 51. Shift Type Creation Integration
**Test Steps:**
1. Create shift type
2. Navigate to `/Shift/ListShiftTypes`
3. Verify new shift appears in list
4. **Expected:** Create → List → Display works

### 52. Configure Split Shifts Backend
**Test Steps:**
1. Login as HR Admin
2. Navigate to `/Shift/ConfigureSplitShift`
3. Fill form:
   - Shift Name: "Split Morning-Evening"
   - First Start: 08:00
   - First End: 12:00
   - Second Start: 14:00
   - Second End: 18:00
   - Break Duration: 120
4. Submit
5. **Backend Check:** Verify split shift created with type='Split'

### 53. Configure Split Shifts Frontend
**Test Steps:**
1. Navigate to configure split shift page
2. Verify form has fields for both periods
3. Fill and submit
4. Verify success message
5. **Expected:** Form works, both periods configurable

### 54. Configure Split Shifts Integration
**Test Steps:**
1. HR Admin configures split shift
2. Redirects to shift types list
3. Verify split shift appears
4. Assign split shift to employee
5. **Expected:** Configure → List → Assign works

### 55. Department-Based Shift Assignment Backend
**Test Steps:**
1. Login as System Admin or Manager
2. Navigate to `/Shift/AssignShiftToDepartment`
3. Select department and shift
4. Set start and end dates
5. Submit
6. **Backend Check:** Verify all employees in department assigned shift

### 56. Department-Based Shift Assignment Frontend
**Test Steps:**
1. Navigate to assign shift to department page
2. Verify dropdowns for department and shift
3. Select and submit
4. Verify success message
5. **Expected:** Form works, selections work

### 57. Department-Based Shift Assignment Integration
**Test Steps:**
1. Assign shift to department
2. Employees in department log in
3. Employees view "My Shifts" → Verify shift assigned
4. **Expected:** Assign → Employee view → Display works

### 58. Individual Shift Assignment Backend
**Test Steps:**
1. Login as System Admin or Manager
2. Navigate to `/Shift/AssignShiftToEmployee`
3. Select employee and shift
4. Set dates
5. Submit
6. **Backend Check:** Verify employee_shift assignment created

### 59. Individual Shift Assignment Frontend
**Test Steps:**
1. Navigate to assign shift to employee page
2. Verify employee selection and shift selection
3. Fill dates and submit
4. **Expected:** Form works, employee receives notification

### 60. Individual Shift Assignment Integration
**Test Steps:**
1. Assign shift to employee
2. Employee receives notification
3. Employee views "My Shifts" → Shift appears
4. **Expected:** Assign → Notify → View works

### 61. Attendance Tracking Backend
**Test Steps:**
1. Login as Employee
2. Navigate to attendance page (check navigation)
3. Record attendance (check-in)
4. **Backend Check:** Verify attendance record created with timestamp

### 62. Attendance Tracking Frontend
**Test Steps:**
1. Navigate to attendance page
2. Verify check-in button displays
3. Click check-in → Verify success message
4. Verify check-out button appears
5. **Expected:** UI updates correctly

### 63. Attendance Tracking Integration
**Test Steps:**
1. Employee checks in
2. View attendance history → Record appears
3. Check out → Record updated
4. **Expected:** Check-in → Record → Check-out → Update works

### 64. Attendance Correction Backend
**Test Steps:**
1. Login as Employee
2. Navigate to attendance correction/submit request page
3. Submit correction request with reason
4. **Backend Check:** Verify correction request created

### 65. Attendance Correction Frontend
**Test Steps:**
1. Navigate to correction request page
2. Fill form (date, reason, etc.)
3. Submit
4. Verify success message
5. **Expected:** Form works, request submitted

### 66. Attendance Correction Integration
**Test Steps:**
1. Employee submits correction request
2. Manager/Admin reviews request
3. Request approved/rejected
4. Employee sees updated attendance
5. **Expected:** Submit → Review → Approve → Update works

### 67. Grace Period Backend
**Test Steps:**
1. Check attendance logic for grace period
2. Employee checks in 5 minutes late
3. **Backend Check:** Verify grace period applied, no penalty recorded

### 68. Grace Period Frontend
**Test Steps:**
1. Employee checks in slightly late
2. Verify no error/warning shown if within grace period
3. **Expected:** Grace period handled transparently

### 69. Grace Period Integration
**Test Steps:**
1. Employee checks in within grace period
2. Attendance recorded as on-time
3. No penalties applied
4. **Expected:** Grace period works end-to-end

### 70. Offline Attendance Backend
**Test Steps:**
1. Simulate offline scenario (disable network)
2. Record attendance offline
3. Reconnect network
4. **Backend Check:** Verify attendance synced when online

### 71. Offline Attendance Frontend
**Test Steps:**
1. Test offline indicator appears
2. Record attendance while offline
3. Verify "pending sync" indicator
4. **Expected:** Offline mode works, sync indicator shows

### 72. Offline Attendance Integration
**Test Steps:**
1. Go offline
2. Record attendance
3. Go online
4. Verify automatic sync
5. Verify attendance appears in history
6. **Expected:** Offline → Record → Online → Sync works

### 73. Team Attendance Summary Backend
**Test Steps:**
1. Login as Manager
2. Navigate to team attendance summary page
3. **Backend Check:** Verify query filters by manager_id, aggregates attendance data

### 74. Team Attendance Summary Frontend
**Test Steps:**
1. View team attendance summary
2. Verify summary statistics displayed (present, absent, late, etc.)
3. **Expected:** Summary displays correctly

### 75. Team Attendance Summary Integration
**Test Steps:**
1. Manager views team summary
2. Clicks on team member → Views individual attendance
3. Can filter by date range
4. **Expected:** Summary → Detail → Filter works

---

## COMPONENT 3 - LEAVE MANAGEMENT

### 76. Leave Request Submission Backend
**Test Steps:**
1. Login as Employee
2. Navigate to `/Leave/SubmitRequest`
3. Fill form:
   - Leave Type: Select from dropdown
   - Start Date
   - End Date
   - Justification
   - Attachment (optional)
4. Submit
5. **Backend Check:** Verify leave request created with status "Pending"

### 77. Leave Request Submission Frontend
**Test Steps:**
1. Navigate to submit leave request page
2. Verify form displays correctly
3. Test validation (start date after end date → error)
4. Submit with attachment
5. **Expected:** Form works, file upload works

### 78. Leave Request Submission Integration
**Test Steps:**
1. Submit leave request
2. Redirected to leave history
3. Request appears in history with "Pending" status
4. Manager receives notification
5. **Expected:** Submit → History → Notify works

### 79. Leave History and Remaining Balance Backend
**Test Steps:**
1. Login as Employee
2. Navigate to `/Leave/MyLeaveHistory`
3. **Backend Check:** Verify query retrieves employee's leave requests

### 80. Leave History and Remaining Balance Frontend
**Test Steps:**
1. View leave history page
2. Verify list displays:
   - Past requests with status
   - Pending requests
   - Approved/Rejected requests
3. Navigate to `/Leave/MyLeaveBalance`
4. Verify balance displayed correctly
5. **Expected:** History and balance display correctly

### 81. Leave History and Remaining Balance Integration
**Test Steps:**
1. View leave history
2. Click on request → View details
3. View leave balance → Verify calculations correct
4. Submit new request → Balance updates
5. **Expected:** History → Detail → Balance → Update works

### 82. Manager View Leave Request Backend
**Test Steps:**
1. Login as Manager
2. Navigate to pending leave requests page (check navigation)
3. **Backend Check:** Verify query filters by manager_id, status='Pending'

### 83. Manager View Leave Request Frontend
**Test Steps:**
1. View pending requests page
2. Verify list shows team members' requests
3. Click request → View details
4. **Expected:** List and detail view work

### 84. Manager View Leave Request Integration
**Test Steps:**
1. Manager views pending requests
2. Clicks request → Views details and attachment
3. Can approve or reject
4. **Expected:** View → Detail → Action works

### 85. Approve/Reject Leave Request Backend
**Test Steps:**
1. Manager views pending request
2. Clicks "Approve" or "Reject"
3. If reject, provide reason
4. **Backend Check:** Verify request status updated, notification created

### 86. Approve/Reject Leave Request Frontend
**Test Steps:**
1. Manager views request
2. Clicks approve/reject button
3. If reject, reason dialog appears
4. Submit
5. Verify success message
6. **Expected:** Buttons work, dialogs work

### 87. Approve/Reject Leave Request Integration
**Test Steps:**
1. Manager approves request
2. Employee receives notification
3. Employee views history → Status changed to "Approved"
4. Leave balance updated
5. **Expected:** Approve → Notify → Update → Balance works

### 88. Flag Irregular Leave Pattern Backend
**Test Steps:**
1. Manager views leave requests
2. System detects irregular pattern (e.g., frequent Mondays/Fridays)
3. **Backend Check:** Verify flag/alert created

### 89. Flag Irregular Leave Pattern Frontend
**Test Steps:**
1. View leave requests with irregular pattern
2. Verify warning/flag indicator appears
3. **Expected:** Visual indicator shows

### 90. Flag Irregular Leave Pattern Integration
**Test Steps:**
1. Employee submits multiple suspicious requests
2. Manager views requests → Flag appears
3. Manager can investigate pattern
4. **Expected:** Detection → Flag → Review works

### 91-93. Grace Period (Leave) - Similar to Attendance grace period testing

### 94. Configure Leave Types Backend
**Test Steps:**
1. Login as HR Admin
2. Navigate to leave configuration page (check navigation)
3. Add new leave type (e.g., "Maternity Leave")
4. **Backend Check:** Verify leave type created in Leave table

### 95. Configure Leave Types Frontend
**Test Steps:**
1. Navigate to configure leave types page
2. Verify form displays
3. Add leave type
4. Verify appears in dropdown when submitting request
5. **Expected:** Create → Display → Use works

### 96. Configure Leave Types Integration
**Test Steps:**
1. HR Admin creates leave type
2. Employee submits request using new type
3. Request processes correctly
4. **Expected:** Configure → Use → Process works

### 97-99. Configure Policies - Similar testing for leave policies

### 100-102. Configure Eligibility Rules - Similar testing

### 103-105. Edit Leave Entitlements - Test HR Admin can adjust employee leave balances

### 106-108. Override/Edit Leave Decision - Test HR Admin can override manager decisions

### 109-111. Add Special Type Leave - Test adding maternity, sick, etc. leave types

### 112-114. Sync Leave with Attendance Record - Test approved leave automatically updates attendance

---

## COMPONENT 4 - MISSION & TASK MANAGEMENT

### 115. View Assigned Mission Backend
**Test Steps:**
1. Login as Employee
2. Navigate to `/Mission/MyMissions`
3. **Backend Check:** Verify query filters by employee_id

### 116. View Assigned Mission Frontend
**Test Steps:**
1. View my missions page
2. Verify list displays assigned missions
3. Click mission → View details
4. **Expected:** List and detail view work

### 117. View Assigned Mission Integration
**Test Steps:**
1. Employee views missions
2. Clicks mission → Views full details
3. Can navigate back to list
4. **Expected:** View → Detail → Navigate works

### 118. Approve/Reject Mission Request Backend
**Test Steps:**
1. Login as Manager
2. Navigate to `/Mission/PendingRequests`
3. View pending mission requests
4. Click "Approve" or "Reject"
5. **Backend Check:** Verify mission status updated

### 119. Approve/Reject Mission Request Frontend
**Test Steps:**
1. Manager views pending requests
2. Clicks approve/reject
3. If reject, provides reason
4. **Expected:** Buttons work, status updates

### 120. Approve/Reject Mission Request Integration
**Test Steps:**
1. Manager approves mission
2. Employee receives notification
3. Employee views missions → Status updated
4. **Expected:** Approve → Notify → Update works

### 121. Assign Mission to Employee Backend
**Test Steps:**
1. Login as HR Admin
2. Navigate to `/Mission/AssignMission`
3. Fill form:
   - Employee
   - Manager
   - Destination
   - Start Date
   - End Date
   - Description
4. Submit
5. **Backend Check:** Verify mission created, linked to employee and manager

### 122. Assign Mission to Employee Frontend
**Test Steps:**
1. Navigate to assign mission page
2. Verify form displays correctly
3. Fill and submit
4. **Expected:** Form works, validation works

### 123. Assign Mission to Employee Integration
**Test Steps:**
1. HR Admin assigns mission
2. Employee receives notification
3. Employee views missions → Mission appears
4. Manager can approve/reject if needed
5. **Expected:** Assign → Notify → View → Approve works

---

## COMPONENT 5 - NOTIFICATIONS, ANALYTICS & HIERARCHY

### 124. Receive Notification Backend
**Test Steps:**
1. Trigger notification (e.g., contract created, leave approved)
2. **Backend Check:** Verify notification created in Employee_Notification table

### 125. Receive Notification Frontend
**Test Steps:**
1. Login as user
2. Check notification badge/indicator appears
3. Click notifications → View list
4. **Expected:** Badge shows, list displays

### 126. Receive Notification Integration
**Test Steps:**
1. Action triggers notification
2. User sees badge indicator
3. User clicks → Views notification
4. Notification marked as read
5. **Expected:** Trigger → Display → View → Read works

### 127-129. Send Customized Notification - Test Manager can send custom notifications to team

### 130-132. View Notification - Test all users can view their notifications

### 133. Generate Department-Wise Statistics Backend
**Test Steps:**
1. Login as HR Admin
2. Navigate to `/Analytics/DepartmentStatistics`
3. **Backend Check:** Verify query aggregates employee data by department

### 134. Generate Department-Wise Statistics Frontend
**Test Steps:**
1. View department statistics page
2. Verify statistics displayed (employee count, etc.)
3. **Expected:** Statistics display correctly

### 135. Generate Department-Wise Statistics Integration
**Test Steps:**
1. View statistics
2. Click department → View details
3. Export/print statistics (if implemented)
4. **Expected:** View → Detail → Export works

### 136-138. Generate Compliance Reports - Test HR Admin can generate compliance reports

### 139. View Organization Hierarchy Backend
**Test Steps:**
1. Login as System Admin
2. Navigate to `/Hierarchy/ViewHierarchy`
3. **Backend Check:** Verify query retrieves organizational structure

### 140. View Organization Hierarchy Frontend
**Test Steps:**
1. View hierarchy page
2. Verify tree/structure displays correctly
3. Can expand/collapse departments
4. **Expected:** Visual hierarchy displays correctly

### 141. View Organization Hierarchy Integration
**Test Steps:**
1. View hierarchy
2. Click department → View employees
3. Click manager → View team
4. Navigate through structure
5. **Expected:** View → Navigate → Detail works

### 142. Assign Employee to New Department Backend
**Test Steps:**
1. Login as System Admin
2. Navigate to `/Hierarchy/ReassignEmployee/{id}`
3. Select new department and/or manager
4. Submit
5. **Backend Check:** Verify employee's department_id and/or manager_id updated

### 143. Assign Employee to New Department Frontend
**Test Steps:**
1. Navigate to reassign page
2. Verify dropdowns for department and manager
3. Select and submit
4. **Expected:** Form works, selections work

### 144. Assign Employee to New Department Integration
**Test Steps:**
1. System Admin reassigns employee
2. Employee receives notification
3. Employee's profile shows new department
4. Hierarchy view updates
5. **Expected:** Reassign → Notify → Update → View works

### 145-147. View Departments, Manager and Teams - Test visual navigation through organization

---

## TESTING CHECKLIST SUMMARY

For each feature, verify:
- ✅ **Backend**: Database operations work correctly
- ✅ **Frontend**: UI displays and functions correctly
- ✅ **Integration**: End-to-end flow works seamlessly
- ✅ **Error Handling**: Invalid inputs handled gracefully
- ✅ **Authorization**: Only authorized users can access
- ✅ **Notifications**: Appropriate notifications sent
- ✅ **Navigation**: Can navigate between related pages
- ✅ **Data Persistence**: Changes persist after logout/login

---

## COMMON ISSUES TO CHECK

1. **Wrong Redirections**: After actions, verify redirects go to correct pages
2. **Missing Error Messages**: Invalid inputs should show clear error messages
3. **Authorization Issues**: Test unauthorized access returns 403/AccessDenied
4. **Data Consistency**: Verify related data updates correctly (e.g., contract → notification)
5. **UI Responsiveness**: Forms should be responsive and user-friendly
6. **Integration**: Components should work together (e.g., leave → attendance sync)

---

Good luck with your evaluation! 🚀

