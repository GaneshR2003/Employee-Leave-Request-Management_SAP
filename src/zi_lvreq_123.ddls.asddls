@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Leave Request Child View'
define view entity ZI_LvReq_123 as select from zlv_req_123
association to parent ZI_EmpQuota_123 as _EmployeeQuota on $projection.EmployeeId = _EmployeeQuota.EmployeeId
{
  key request_id as RequestId,
  employee_id as EmployeeId,
  leave_type as LeaveType,
  start_date as StartDate,
  end_date as EndDate,
  status as Status,

  // Color logic for status indicators
  case status
    when 'A' then 3 // Green (Approved)
    when 'R' then 1 // Red (Rejected)
    when 'P' then 2 // Yellow (Pending)
    else 0          
  end as StatusCriticality,
  
  _EmployeeQuota
}
