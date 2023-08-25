USE [msdb]
GO

BEGIN TRY
  IF Exists (Select * from SysJobs Where Name = 'DWIndependentBookSellersETL')
    Begin 
      Exec sp_delete_job @job_name = DWIndependentBookSellersETL
    End

  /****** Object:  Job [DWIndependentBookSellersETL]    Script Date: 8/21/2021 3:46:14 PM ******/
  BEGIN TRANSACTION
  DECLARE @ReturnCode INT
  SELECT @ReturnCode = 0
  /****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 8/21/2021 3:46:14 PM ******/
  IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
  BEGIN
  EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

  END

  DECLARE @jobId BINARY(16)
  EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DWIndependentBookSellersETL', 
		  @enabled=1, 
		  @notify_level_eventlog=0, 
		  @notify_level_email=0, 
		  @notify_level_netsend=0, 
		  @notify_level_page=0, 
		  @delete_level=0, 
		  @description=N'Performs ETL tasks for DWIndependentBookSellers', 
		  @category_name=N'[Uncategorized (Local)]', 
		  @owner_login_name=N'sa', @job_id = @jobId OUTPUT
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
  /****** Object:  Step [Run DWIndependentBookSellersETLpackage.dtsx]    Script Date: 8/21/2021 3:46:14 PM ******/
  EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run DWIndependentBookSellersETLpackage.dtsx', 
		  @step_id=1, 
		  @cmdexec_success_code=0, 
		  @on_success_action=1, 
		  @on_success_step_id=0, 
		  @on_fail_action=2, 
		  @on_fail_step_id=0, 
		  @retry_attempts=0, 
		  @retry_interval=0, 
		  @os_run_priority=0, @subsystem=N'SSIS', 
		  @command=N'/FILE "\"C:\_SQL330\DWIndependentBookSellersETLpackage.dtsx\"" /CHECKPOINTING OFF /REPORTING E', 
		  @database_name=N'master', 
		  @flags=0, 
		  @proxy_name=N'SSIS Proxy'
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
  EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
  EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EachNight', 
		  @enabled=1, 
		  @freq_type=4, 
		  @freq_interval=1, 
		  @freq_subday_type=1, 
		  @freq_subday_interval=0, 
		  @freq_relative_interval=0, 
		  @freq_recurrence_factor=0, 
		  @active_start_date=20210821, 
		  @active_end_date=99991231, 
		  @active_start_time=10000, 
		  @active_end_time=235959, 
		  @schedule_uid=N'9640d2e5-225c-454e-b242-0fc720a95597'
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
  EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
  COMMIT TRANSACTION
  GOTO EndSave
  QuitWithRollback:
      IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
  EndSave:

END TRY
BEGIN CATCH
  IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
  Print Error_Message()
END CATCH

GO


