@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Fiori Projection - Employee Quota'
@Metadata.allowExtensions: true
define root view entity ZC_EmpQuota_123 as projection on ZI_EmpQuota_123
{
  key EmployeeId,
  EmployeeName,
  Department,
  TotalLeaveQuota,
  UsedLeaveDays,
  LeavePercentage,
  PercentageCriticality,

  _LeaveRequests : redirected to composition child ZC_LvReq_123
}
