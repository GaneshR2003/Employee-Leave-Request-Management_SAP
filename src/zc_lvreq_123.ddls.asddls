@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Fiori Projection - Leave Requests'
@Metadata.allowExtensions: true
define view entity ZC_LvReq_123 as projection on ZI_LvReq_123
{
  key RequestId,
  EmployeeId,
  LeaveType,
  StartDate,
  EndDate,
  Status,
  StatusCriticality,
  
  _EmployeeQuota : redirected to parent ZC_EmpQuota_123
}
