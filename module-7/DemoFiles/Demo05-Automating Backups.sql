--*************************************************************************--
-- Title: Automating Backups 
-- Author: RRoot
-- Desc: This file demonstrates how you automate database backups with various options.
-- Change Log: When,Who,What
-- 2018-02-19,RRoot,Created File
--**************************************************************************--

-- [Setup Code] -- 
---------------------------------------------------------------------------------------------------------
/* Create the following folder for this demo
!! MD C:\BackupFiles
USE [Master];
*/
go
If Exists (SELECT name FROM sys.databases WHERE name = N'BackupDemoDB')
  Begin
    -- Remove any database backups that were tracked in the MSDB database!
    EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'BackupDemoDB'
    ALTER DATABASE [BackupDemoDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [BackupDemoDB];
  End
go
CREATE DATABASE [BackupDemoDB] ON PRIMARY -- File Group
 ( NAME = N'BackupDemoDB' -- logical name
 , FILENAME = N'C:\BackupFiles\BackupDemoDB.mdf' ) -- physical name
 LOG ON 
 ( NAME = N'BackupDemoDB_log' -- logical name
 , FILENAME = N'C:\BackupFiles\BackupDemoDB.ldf' ); -- physical name
go

-- This time we will create a Backup Device 
If Exists (Select * From model.sys.sysdevices Where Name = N'BackupDemoDBDevice')
 EXEC master.dbo.sp_dropdevice @logicalname = N'BackupDemoDBDevice'
go
Exec master.dbo.sp_AdDumpDevice
  @devtype = N'disk'
, @logicalname = N'BackupDemoDBDevice'
, @physicalname = N'C:\BackupFiles\BackupDemoDB.bak'
go

-- Let's create some starting data
USE [BackupDemoDB]
go
Create Table ProductList
 (ProductId int, ProductName nvarchar(100));
go
Insert into ProductList Values(1, 'ProdA');
Select * from ProductList; -- Check the data is there!
---------------------------------------------------------------------------------------------------------

-- [Mixed Backup Files] -- 
---------------------------------------------------------------------------------------------------------
-- One backup file can hold a mix of backup files (ex. both Full and Log )
Backup Database BackupDemoDB To BackupDemoDBDevice With Init;
Backup Log BackupDemoDB To Disk ='C:\BackupFiles\BackupDemoDB.bak';
Restore HeaderOnly From DISK = N'C:\BackupFiles\BackupDemoDB.bak';
go 
---------------------------------------------------------------------------------------------------------

-- [Common Backup Patterns] --
---------------------------------------------------------------------------------------------------------
-- There are common patterns to setting up a database backup system
/*
"Backing up and restoring data must be customized to a particular environment and must work 
with the available resources. Therefore, a reliable use of backup and restore for recovery 
requires a backup and restore strategy. A well-designed backup and restore strategy maximizes 
data availability and minimizes data loss, while considering your particular business requirements."
https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/back-up-and-restore-of-sql-server-databases
*/

-- COMMON PATTERN 1: Full backup each day on Test/Dev databases
-- Sunday
Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Sun-Full', Init;
-- Monday
Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Mon-Full';
-- Tuesday
Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Tue-Full';
-- Wednesday
Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Wed-Full';
-- Thursday
Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Thu-Full';
-- Friday
Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Fri-Full';
-- Saturday
Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Sat-Full';


-- The Next Sunday we have lots of backs that need to be saved.
Restore HeaderOnly From DISK = N'C:\BackupFiles\BackupDemoDB.bak';
go 
-- So, we make an archive of the file and start again

-- Move the existing archive file to a NETWORK share
-- https://support.microsoft.com/en-us/help/240268/copy-xcopy-and-move-overwrite-functionality-changes-in-windows
-- !! net use s: \\localhost\Demoshare -- Map to a share drive
-- !! MD S:\BackupDemoDB
-- !! Move "C:\BackupFiles\BackupDemoDB_FromLastWeek.bak" "s:\BackupDemoDB\BackupDemoDB_OnNetWorkShare.bak" 

-- Create a new archive file on the local folder
!! Copy "C:\BackupFiles\BackupDemoDB.bak" "C:\BackupFiles\BackupDemoDB_FromLastWeek.bak"

!! Dir "C:\BackupFiles"
go
 -- Now, overwrite the existing backups and start again!
Backup Database BackupDemoDB To BackupDemoDBDevice With Init;

-- COMMON PATTERN 2: Full backup each week with LOG BACKUP EACH DAY on small/mid sized databases
-- Sunday
Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Sun-Full', Init;
-- Monday
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Mon-Log';
-- Tuesday                                                    
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Tue-Log';
-- Wednesday                                                   
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Wed-Log';
-- Thursday                                                    
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Thu-Log';
-- Friday                                                      
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Fri-Log';
-- Saturday                                                    
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Sat-Log';
go

-- On the Next Sunday we make an archive of the file and start again
Restore HeaderOnly From DISK = N'C:\BackupFiles\BackupDemoDB.bak';

-- Create a new archive file on the local folder
!! Copy "C:\BackupFiles\BackupDemoDB.bak" "C:\BackupFiles\BackupDemoDB_FromLastWeek.bak"
!! Dir "C:\BackupFiles"
go
Backup Database BackupDemoDB To BackupDemoDBDevice With Init;

-- COMMON PATTERN 3: Full backup each day with LOG BACKUPS EVERY 6 HOURS on mid/large databases
-- Sunday
Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Sun-Log', Init;
-- Monday
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Mon-Log 0000'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Mon-Log 0600'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Mon-Log 1200'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Mon-Log 1800'
-- Tuesday                                                    
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Tue-Log 0000'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Tue-Log 0600'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Tue-Log 1200'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Tue-Log 1800'
-- Wednesday                                                   
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Wed-Log 0000'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Wed-Log 0600'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Wed-Log 1200'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Wed-Log 1800'
-- Thursday                                                    
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Thu-Log 0000'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Thu-Log 0600'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Thu-Log 1200'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Thu-Log 1800'
-- Friday                                                      
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Fri-Log 0000'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Fri-Log 0600'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Fri-Log 1200'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Fri-Log 1800'
-- Saturday                                                    
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Sat-Log 0000'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Sat-Log 0600'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Sat-Log 1200'
Backup Log BackupDemoDB To BackupDemoDBDevice With Name = 'Sat-Log 1800'

-- Sunday
-- On the Next Sunday we make an archive of the file and start again
Restore HeaderOnly From DISK = N'C:\BackupFiles\BackupDemoDB.bak';

-- Create a new archive file on the local folder
!! Copy "C:\BackupFiles\BackupDemoDB.bak" "C:\BackupFiles\BackupDemoDB_FromLastWeek.bak"
!! Dir "C:\BackupFiles"
Backup Database BackupDemoDB To BackupDemoDBDevice With Init;


-- [Creating a backup Stored Procedure] --
---------------------------------------------------------------------------------------------------------
Use [Master];
go
Create -- Drop
Proc pMaintBackupBackupDemoDB
--*************************************************************************--
-- Dev: RRoot
-- Desc: Performs database backups on the BackupDemo DB.
-- Change Log: When,Who,What
-- 2021-08-19,RRoot,Created Sproc
--**************************************************************************--
As 
Begin 
  If (DatePart(dw,GetDate()) = 1)-- Sunday
  Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Sun-Full', Init; -- Restart
  Else 
  If (DatePart(dw,GetDate()) = 2)-- Monday
  Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Mon-Full';
  Else 
  If (DatePart(dw,GetDate()) = 3)-- Tuesday
  Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Tue-Full';
  Else 
  If (DatePart(dw,GetDate()) = 4)-- Wednesday
  Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Wed-Full';
  Else 
  If (DatePart(dw,GetDate()) = 5)-- Thursday
  Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Thu-Full';
  Else 
  If (DatePart(dw,GetDate()) = 6)-- Friday
  Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Fri-Full';  
  Else 
  If (DatePart(dw,GetDate()) = 7)-- Saturday
  Backup Database BackupDemoDB To BackupDemoDBDevice With Name = 'Sat-Full';
End -- Proc

-- Step 2) Test the stored procedure
Exec pMaintBackupBackupDemoDB
Restore HeaderOnly From DISK = N'C:\BackupFiles\BackupDemoDB.bak';
go  
---------------------------------------------------------------------------------------------------------

-- [Automating with SQL Server Agent] --
---------------------------------------------------------------------------------------------------------
USE [msdb]
go
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'BackupDemoDBBackupJob', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId
go
EXEC msdb.dbo.sp_add_jobserver @job_name=N'BackupDemoDBBackupJob', @server_name = @@SERVERNAME
go
USE [msdb]
go
EXEC msdb.dbo.sp_add_jobstep @job_name=N'BackupDemoDBBackupJob', @step_name=N'Run pMaintBackupBackupDemoDB', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec pMaintBackupBackupDemoDB;', 
		@database_name=N'master', 
		@flags=0
go
USE [msdb]
go
EXEC msdb.dbo.sp_update_job @job_name=N'BackupDemoDBBackupJob', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
go
USE [msdb]
go
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'BackupDemoDBBackupJob', @name=N'Daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180221, 
		@active_end_date=99991231, 
		@active_start_time=1, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
go
---------------------------------------------------------------------------------------------------------



-- [Clean Up Code] -- 
---------------------------------------------------------------------------------------------------------
Use [Master];
Drop Procedure pMaintBackupBackupDemoDB;
go
Declare @JobID nvarchar(100)
Select @JobID = job_id From Msdb..sysjobs Where [Name] = N'BackupDemoDBBackupJob'
EXEC msdb.dbo.sp_delete_job @job_id = @JobID, @delete_unused_schedule = 1
go
If Exists (SELECT name FROM sys.databases WHERE name = N'BackupDemoDB')
  Begin
    -- Remove any database backups that were tracked in the MSDB database!
    EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'BackupDemoDB'
    ALTER DATABASE [BackupDemoDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [BackupDemoDB];
  End
go
If Exists (SELECT name FROM sys.databases WHERE name = N'BackupDemoReportsDB')
  Begin
    -- Remove any database backups that were tracked in the MSDB database!
    EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'BackupDemoReportsDB'
    ALTER DATABASE [BackupDemoReportsDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [BackupDemoReportsDB];
  End
go

!! Del C:\BackupFiles\*.bak