CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA:
      mt_quota_create TYPE TABLE OF zemp_quota_123,
      mt_quota_update TYPE TABLE OF zemp_quota_123,
      mt_quota_delete TYPE TABLE OF zemp_quota_123,
      mt_req_create   TYPE TABLE OF zlv_req_123,
      mt_req_update   TYPE TABLE OF zlv_req_123,
      mt_req_delete   TYPE TABLE OF zlv_req_123.
ENDCLASS.

CLASS lhc_EmployeeQuota DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION IMPORTING keys REQUEST requested_authorizations FOR EmployeeQuota RESULT result.
    METHODS create FOR MODIFY IMPORTING entities FOR CREATE EmployeeQuota.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE EmployeeQuota.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE EmployeeQuota.
    METHODS read FOR READ IMPORTING keys FOR READ EmployeeQuota RESULT result.
    METHODS lock FOR LOCK IMPORTING keys FOR LOCK EmployeeQuota.
    METHODS rba_Leaverequests FOR READ IMPORTING keys_rba FOR READ EmployeeQuota\_Leaverequests FULL result_requested RESULT result LINK association_links.
    METHODS cba_Leaverequests FOR MODIFY IMPORTING entities_cba FOR CREATE EmployeeQuota\_Leaverequests.
ENDCLASS.

CLASS lhc_EmployeeQuota IMPLEMENTATION.
  METHOD get_instance_authorizations. ENDMETHOD.
  METHOD lock. ENDMETHOD.
  METHOD rba_Leaverequests. ENDMETHOD.

  METHOD create.
    DATA: ls_quota  TYPE zemp_quota_123,
          lv_max_id TYPE zemp_quota_123-employee_id.

    " Auto-Numbering: Find the highest ID in the database
    SELECT MAX( employee_id ) FROM zemp_quota_123 INTO @lv_max_id.

    LOOP AT entities INTO DATA(ls_entity).
      " Auto-Numbering: Add 1 for the new employee
      lv_max_id = lv_max_id + 1.

      ls_quota-client            = sy-mandt.
      ls_quota-employee_id       = lv_max_id.
      ls_quota-employee_name     = ls_entity-EmployeeName.
      ls_quota-department        = ls_entity-Department.
      ls_quota-total_leave_quota = ls_entity-TotalLeaveQuota.
      ls_quota-used_leave_days   = ls_entity-UsedLeaveDays.

      APPEND ls_quota TO lcl_buffer=>mt_quota_create.

      INSERT VALUE #( %cid       = ls_entity-%cid
                      EmployeeId = ls_quota-employee_id ) INTO TABLE mapped-employeequota.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    DATA ls_quota TYPE zemp_quota_123.
    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM zemp_quota_123 WHERE employee_id = @ls_entity-EmployeeId INTO @ls_quota.
      IF sy-subrc = 0.
        IF ls_entity-%control-EmployeeName = if_abap_behv=>mk-on.
          ls_quota-employee_name = ls_entity-EmployeeName.
        ENDIF.
        IF ls_entity-%control-Department = if_abap_behv=>mk-on.
          ls_quota-department = ls_entity-Department.
        ENDIF.
        IF ls_entity-%control-TotalLeaveQuota = if_abap_behv=>mk-on.
          ls_quota-total_leave_quota = ls_entity-TotalLeaveQuota.
        ENDIF.

        APPEND ls_quota TO lcl_buffer=>mt_quota_update.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    DATA ls_quota TYPE zemp_quota_123.
    LOOP AT keys INTO DATA(ls_key).
      ls_quota-employee_id = ls_key-EmployeeId.
      APPEND ls_quota TO lcl_buffer=>mt_quota_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    SELECT * FROM zemp_quota_123 FOR ALL ENTRIES IN @keys
      WHERE employee_id = @keys-EmployeeId INTO TABLE @DATA(lt_quota).

    LOOP AT keys INTO DATA(ls_key).
      " 1. Check Create Buffer First
      READ TABLE lcl_buffer=>mt_quota_create INTO DATA(ls_create) WITH KEY employee_id = ls_key-EmployeeId.
      IF sy-subrc = 0.
        INSERT VALUE #( EmployeeId      = ls_create-employee_id
                        EmployeeName    = ls_create-employee_name
                        Department      = ls_create-department
                        TotalLeaveQuota = ls_create-total_leave_quota
                        UsedLeaveDays   = ls_create-used_leave_days ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      " 2. Check Update Buffer Second
      READ TABLE lcl_buffer=>mt_quota_update INTO DATA(ls_update) WITH KEY employee_id = ls_key-EmployeeId.
      IF sy-subrc = 0.
        INSERT VALUE #( EmployeeId      = ls_update-employee_id
                        EmployeeName    = ls_update-employee_name
                        Department      = ls_update-department
                        TotalLeaveQuota = ls_update-total_leave_quota
                        UsedLeaveDays   = ls_update-used_leave_days ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      " 3. Check Database Last
      READ TABLE lt_quota INTO DATA(ls_db) WITH KEY employee_id = ls_key-EmployeeId.
      IF sy-subrc = 0.
        INSERT VALUE #( EmployeeId      = ls_db-employee_id
                        EmployeeName    = ls_db-employee_name
                        Department      = ls_db-department
                        TotalLeaveQuota = ls_db-total_leave_quota
                        UsedLeaveDays   = ls_db-used_leave_days ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Leaverequests.
    DATA ls_req TYPE zlv_req_123.

    LOOP AT entities_cba INTO DATA(ls_cba).
      LOOP AT ls_cba-%target INTO DATA(ls_target).
        ls_req-client      = sy-mandt.
        ls_req-request_id  = cl_system_uuid=>create_uuid_x16_static( ).
        ls_req-employee_id = ls_cba-EmployeeId.
        ls_req-leave_type  = ls_target-LeaveType.
        ls_req-start_date  = ls_target-StartDate.
        ls_req-end_date    = ls_target-EndDate.
        ls_req-status      = 'P'.

        APPEND ls_req TO lcl_buffer=>mt_req_create.

        INSERT VALUE #( %cid      = ls_target-%cid
                        RequestId = ls_req-request_id ) INTO TABLE mapped-leaverequest.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_LeaveRequest DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION IMPORTING keys REQUEST requested_authorizations FOR LeaveRequest RESULT result.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE LeaveRequest.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE LeaveRequest.
    METHODS read FOR READ IMPORTING keys FOR READ LeaveRequest RESULT result.
    METHODS rba_Employeequota FOR READ IMPORTING keys_rba FOR READ LeaveRequest\_Employeequota FULL result_requested RESULT result LINK association_links.
    METHODS ApproveLeave FOR MODIFY IMPORTING keys FOR ACTION LeaveRequest~ApproveLeave RESULT result.
    METHODS RejectLeave FOR MODIFY IMPORTING keys FOR ACTION LeaveRequest~RejectLeave RESULT result.
ENDCLASS.

CLASS lhc_LeaveRequest IMPLEMENTATION.
  METHOD get_instance_authorizations. ENDMETHOD.
  METHOD rba_Employeequota. ENDMETHOD.

  METHOD update.
    DATA ls_req TYPE zlv_req_123.
    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM zlv_req_123 WHERE request_id = @ls_entity-RequestId INTO @ls_req.
      IF sy-subrc = 0.
        IF ls_entity-%control-LeaveType = if_abap_behv=>mk-on.
          ls_req-leave_type = ls_entity-LeaveType.
        ENDIF.
        IF ls_entity-%control-StartDate = if_abap_behv=>mk-on.
          ls_req-start_date = ls_entity-StartDate.
        ENDIF.
        IF ls_entity-%control-EndDate = if_abap_behv=>mk-on.
          ls_req-end_date = ls_entity-EndDate.
        ENDIF.

        APPEND ls_req TO lcl_buffer=>mt_req_update.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    DATA ls_req TYPE zlv_req_123.
    LOOP AT keys INTO DATA(ls_key).
      ls_req-request_id = ls_key-RequestId.
      APPEND ls_req TO lcl_buffer=>mt_req_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    SELECT * FROM zlv_req_123 FOR ALL ENTRIES IN @keys
      WHERE request_id = @keys-RequestId INTO TABLE @DATA(lt_req).

    LOOP AT keys INTO DATA(ls_key).
      " 1. Check Create Buffer First
      READ TABLE lcl_buffer=>mt_req_create INTO DATA(ls_create) WITH KEY request_id = ls_key-RequestId.
      IF sy-subrc = 0.
        INSERT VALUE #( RequestId  = ls_create-request_id
                        EmployeeId = ls_create-employee_id
                        LeaveType  = ls_create-leave_type
                        StartDate  = ls_create-start_date
                        EndDate    = ls_create-end_date
                        Status     = ls_create-status ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      " 2. Check Update Buffer Second
      READ TABLE lcl_buffer=>mt_req_update INTO DATA(ls_update) WITH KEY request_id = ls_key-RequestId.
      IF sy-subrc = 0.
        INSERT VALUE #( RequestId  = ls_update-request_id
                        EmployeeId = ls_update-employee_id
                        LeaveType  = ls_update-leave_type
                        StartDate  = ls_update-start_date
                        EndDate    = ls_update-end_date
                        Status     = ls_update-status ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      " 3. Check Database Last
      READ TABLE lt_req INTO DATA(ls_db) WITH KEY request_id = ls_key-RequestId.
      IF sy-subrc = 0.
        INSERT VALUE #( RequestId  = ls_db-request_id
                        EmployeeId = ls_db-employee_id
                        LeaveType  = ls_db-leave_type
                        StartDate  = ls_db-start_date
                        EndDate    = ls_db-end_date
                        Status     = ls_db-status ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD ApproveLeave.
    DATA: ls_request TYPE zlv_req_123,
          ls_quota   TYPE zemp_quota_123,
          lv_days    TYPE i.

    LOOP AT keys INTO DATA(ls_key).
      SELECT SINGLE * FROM zlv_req_123 WHERE request_id = @ls_key-RequestId INTO @ls_request.
      IF sy-subrc = 0 AND ls_request-status = 'P'.
        lv_days = ls_request-end_date - ls_request-start_date + 1.

        ls_request-status = 'A'.
        APPEND ls_request TO lcl_buffer=>mt_req_update.

        SELECT SINGLE * FROM zemp_quota_123 WHERE employee_id = @ls_request-employee_id INTO @ls_quota.
        IF sy-subrc = 0.
          ls_quota-used_leave_days = ls_quota-used_leave_days + lv_days.
          APPEND ls_quota TO lcl_buffer=>mt_quota_update.
        ENDIF.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF ZI_EmpQuota_123 IN LOCAL MODE ENTITY LeaveRequest ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_request).
    result = VALUE #( FOR req IN lt_request ( %tky = req-%tky %param = req ) ).
  ENDMETHOD.

  METHOD RejectLeave.
    DATA ls_request TYPE zlv_req_123.
    LOOP AT keys INTO DATA(ls_key).
      SELECT SINGLE * FROM zlv_req_123 WHERE request_id = @ls_key-RequestId INTO @ls_request.
      IF sy-subrc = 0 AND ls_request-status = 'P'.
        ls_request-status = 'R'.
        APPEND ls_request TO lcl_buffer=>mt_req_update.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF ZI_EmpQuota_123 IN LOCAL MODE ENTITY LeaveRequest ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_request).
    result = VALUE #( FOR req IN lt_request ( %tky = req-%tky %param = req ) ).
  ENDMETHOD.
ENDCLASS.

CLASS lsc_ZI_EMPQUOTA_123 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_ZI_EMPQUOTA_123 IMPLEMENTATION.
  METHOD finalize. ENDMETHOD.
  METHOD check_before_save. ENDMETHOD.

  METHOD save.
    IF lcl_buffer=>mt_quota_create IS NOT INITIAL.
      INSERT zemp_quota_123 FROM TABLE @lcl_buffer=>mt_quota_create ACCEPTING DUPLICATE KEYS.
    ENDIF.
    IF lcl_buffer=>mt_quota_update IS NOT INITIAL.
      UPDATE zemp_quota_123 FROM TABLE @lcl_buffer=>mt_quota_update.
    ENDIF.
    IF lcl_buffer=>mt_quota_delete IS NOT INITIAL.
      DELETE zemp_quota_123 FROM TABLE @lcl_buffer=>mt_quota_delete.
    ENDIF.

    IF lcl_buffer=>mt_req_create IS NOT INITIAL.
      INSERT zlv_req_123 FROM TABLE @lcl_buffer=>mt_req_create ACCEPTING DUPLICATE KEYS.
    ENDIF.
    IF lcl_buffer=>mt_req_update IS NOT INITIAL.
      UPDATE zlv_req_123 FROM TABLE @lcl_buffer=>mt_req_update.
    ENDIF.
    IF lcl_buffer=>mt_req_delete IS NOT INITIAL.
      DELETE zlv_req_123 FROM TABLE @lcl_buffer=>mt_req_delete.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR: lcl_buffer=>mt_quota_create,
           lcl_buffer=>mt_quota_update,
           lcl_buffer=>mt_quota_delete,
           lcl_buffer=>mt_req_create,
           lcl_buffer=>mt_req_update,
           lcl_buffer=>mt_req_delete.
  ENDMETHOD.

  METHOD cleanup_finalize.
    CLEAR: lcl_buffer=>mt_quota_create,
           lcl_buffer=>mt_quota_update,
           lcl_buffer=>mt_quota_delete,
           lcl_buffer=>mt_req_create,
           lcl_buffer=>mt_req_update,
           lcl_buffer=>mt_req_delete.
  ENDMETHOD.
ENDCLASS.
