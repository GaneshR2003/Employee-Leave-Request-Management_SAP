@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Employee Quota Root View'
define root view entity ZI_EmpQuota_123 as select from zemp_quota_123
composition [0..*] of ZI_LvReq_123 as _LeaveRequests
{
  key employee_id as EmployeeId,
  employee_name as EmployeeName,
  department as Department,
  total_leave_quota as TotalLeaveQuota,
  used_leave_days as UsedLeaveDays,
  
  // System-calculated percentage
  cast( case when total_leave_quota > 0 
        then ( cast(used_leave_days as abap.dec(10,2)) / cast(total_leave_quota as abap.dec(10,2)) ) * 100 
        else 0 end as abap.dec(5,2) ) as LeavePercentage,

  // Color logic for the progress bar
  case 
    when total_leave_quota = 0 then 0
    when ( cast(used_leave_days as abap.dec(10,2)) / cast(total_leave_quota as abap.dec(10,2)) ) * 100 <= 50 then 3 // Green
    when ( cast(used_leave_days as abap.dec(10,2)) / cast(total_leave_quota as abap.dec(10,2)) ) * 100 <= 85 then 2 // Yellow
    else 1 // Red
  end as PercentageCriticality,
        
  _LeaveRequests
}
