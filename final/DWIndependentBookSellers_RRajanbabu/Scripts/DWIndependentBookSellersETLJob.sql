--*************************************************************************--
-- Title: Final Create Job Script
-- Author: Ramkumar Rajanbabu
-- Desc: This file will create a SQL Server Agent Job for the final assignment.
-- Change Log: When,Who,What
-- 2020-02-07,RRoot,Created File
-- Todo: 09/11/23, Ramkumar Rajanbabu, Completed DWIndependentBookSellersETLJob
--**************************************************************************--

USE [msdb]
GO

BEGIN TRY
BEGIN TRANSACTION
DECLARE @ReturnCode INT = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DWIndependentBookSellersETL', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Package', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/FILE "\"C:\Users\User\Documents\github\uw-pce-sql-server-development-sqldev330\_SQL330\IndependentBookSellersETLpackage.dtsx\"" /CHECKPOINTING OFF /REPORTING E', 
		@database_name=N'master', 
		@flags=0, 
		@proxy_name=N'SQL330'

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1

EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run at 1AM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20230911, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=N'472d77ec-9c2f-4dcd-b6d1-c7f7515db359'

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'

COMMIT TRANSACTION

END TRY
BEGIN CATCH
	IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
END CATCH
GO