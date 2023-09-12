--*************************************************************************--
-- Title: Final Create Maintenance Job Script
-- Author: Ramkumar Rajanbabu
-- Desc: This file will create a SQL Server Agent Maintenance Job for the final assignment.
-- Change Log: When,Who,What
-- 2020-02-07,RRoot,Created File
-- Todo: 09/11/23, Ramkumar Rajanbabu, Completed DWIndependentBookSellersMaintJob
--**************************************************************************--

USE [msdb]
GO

BEGIN TRY
BEGIN TRANSACTION
DECLARE @ReturnCode INT = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DWIndependentBookSellersMaint', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pMaintIndexes', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Create or Alter Proc pMaintIndexes
--*************************************************************************--
-- Desc:This Sproc drops and creates FK column indexes. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 09/10/23, Ramkumar Rajanbabu, Completed pMaintIndexes
--*************************************************************************--
As
Begin
	DECLARE @RC INT = 1;
	BEGIN TRY
		BEGIN TRY DROP INDEX FactTitleAuthors.nciDimAuthorsFK END TRY BEGIN CATCH END CATCH
		CREATE NONCLUSTERED INDEX nciDimAuthorsFK ON FactTitleAuthors(AuthorKey);

		BEGIN TRY DROP INDEX FactTitleAuthors.nciDimTitlesFK END TRY BEGIN CATCH END CATCH
		CREATE NONCLUSTERED INDEX nciDimTitlesFK ON FactTitleAuthors(TitleKey);

		BEGIN TRY DROP INDEX FactSales.nciDimDatesFK END TRY BEGIN CATCH END CATCH
		CREATE NONCLUSTERED INDEX nciDimDatesFK ON FactSales(OrderDateKey);

		BEGIN TRY DROP INDEX FactSales.nciDimTitlesFK END TRY BEGIN CATCH END CATCH
		CREATE NONCLUSTERED INDEX nciDimTitlesFK ON FactSales(TitleKey);

		BEGIN TRY DROP INDEX FactSales.nciDimStoresFK END TRY BEGIN CATCH END CATCH
		CREATE NONCLUSTERED INDEX nciDimStoresFK ON FactSales(StoreKey);

		EXEC pInsMaintLog
			@MaintAction = ''pMaintIndexes'',
			@MaintLogMessage = ''Indexes Recreated'';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = ''pMaintIndexes'',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go', 
		@database_name=N'DWIndependentBookSellers', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pMaintDBBackup', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Create or Alter Proc pMaintDBBackup
--*************************************************************************--
-- Desc:This Sproc does a full backup of the database. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 09/10/23, Ramkumar Rajanbabu, Completed pMaintDBBackup
--*************************************************************************--
As
Begin
	DECLARE @RC INT = 1;
	BEGIN TRY
		BACKUP DATABASE [DWIndependentBookSellers]
			TO DISK = N''C:\Users\User\Documents\github\uw-pce-sql-server-development-sqldev330\_SQL330\DWIndependentBookSellers.bak''
			WITH INIT;

		EXEC pInsMaintLog
			@MaintAction = ''pMaintDBBackup'',
			@MaintLogMessage = ''Created DB Backup'';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = ''pMaintDBBackup'',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go', 
		@database_name=N'DWIndependentBookSellers', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pMaintRestore', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Create or Alter Proc pMaintRestore
--*************************************************************************--
-- Desc:This Sproc restores the database backup. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 09/10/23, Ramkumar Rajanbabu, Completed pMaintRestore
--*************************************************************************--
As
Begin
	DECLARE @RC INT = 1;
	BEGIN TRY
		RESTORE DATABASE DWIndependentBookSellersRestored
		FROM DISK = N''C:\Users\User\Documents\github\uw-pce-sql-server-development-sqldev330\_SQL330\DWIndependentBookSellers.bak''
		WITH FILE = 1,
			MOVE N''DWIndependentBookSellers'' TO N''C:\Users\User\Documents\github\uw-pce-sql-server-development-sqldev330\_SQL330\DWIndependentBookSellersRestored.mdf'',
			MOVE N''DWIndependentBookSellers_log'' TO N''C:\Users\User\Documents\github\uw-pce-sql-server-development-sqldev330\_SQL330\DWIndependentBookSellersRestored.ldf'',
			RECOVERY,
			REPLACE;
		ALTER DATABASE DWIndependentBookSellersRestored SET READ_ONLY WITH NO_WAIT;

		EXEC pInsMaintLog
			@MaintAction = ''pMaintRestore'',
			@MaintLogMessage = ''Restored DWIndependentBookSellers backup to DWIndependentBookSellersRestored'';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = ''pMaintRestore'',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go', 
		@database_name=N'DWIndependentBookSellers', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pMaintValidateDimDatesRestore', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Create or Alter Proc pMaintValidateDimDatesRestore
--*************************************************************************--
-- Desc:This Sproc validates DimDates in the restore database . 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As
Begin
  Declare @RC int = 0;
  Begin Try

    Declare @CurrentCount int, @RestoredCount int; 
    Declare @CurrentDateTime DateTime = GetDate()
    
    -- Test Row Counts DimDates
    Select @CurrentCount = count(*) From [DWIndependentBookSellers].[dbo].[DimDates];
    Select @RestoredCount = count(*) From DWIndependentBookSellersRestored.[dbo].[DimDates];
      If (@CurrentCount = @RestoredCount) 
        
          Exec pInsValidationLog
                @ValidationDateTime = @CurrentDateTime
               ,@ValidationObject = ''pMaintValidateDimDatesRestore''
               ,@ValidationStatus = ''Success''
               ,@ValidationMessage = ''DimDates Row Count Test''
      Else
          Exec pInsValidationLog 
                @ValidationDateTime = @CurrentDateTime
               ,@ValidationObject = ''pMaintValidateDimDatesRestore''
               ,@ValidationStatus = ''Failed''
               ,@ValidationMessage = ''DimDates Row Count Test''
    
    -- Compare Data --
    Declare @DuplicateCount int
    Select  @DuplicateCount = Count(*) 
            From 
            (Select * From [DWIndependentBookSellers].[dbo].[DimDates] 
             Except
             Select * From DWIndependentBookSellersRestored.[dbo].[DimDates]) as Results
    If @DuplicateCount = 0
         Exec pInsValidationLog 
                @ValidationDateTime = @CurrentDateTime
               ,@ValidationObject = ''pMaintValidateDimDatesRestore''
               ,@ValidationStatus = ''Success''
               ,@ValidationMessage = ''DimDates Duplicate Test''
    Else
          Exec pInsValidationLog 
                @ValidationDateTime = @CurrentDateTime
               ,@ValidationObject = ''pMaintValidateDimDatesRestore''
               ,@ValidationStatus = ''Failed''
               ,@ValidationMessage = ''DimDates Duplicate Test''

    Exec pInsMaintLog
	         @MaintAction = ''pMaintValidateDimDatesRestore''
	        ,@MaintLogMessage = ''DimDates Validated. Check Validation Log!'';
    Set @RC = 1;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	  Exec pInsMaintLog 
	          @MaintAction = ''pMaintValidateDimDatesRestore''
	         ,@MaintLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go', 
		@database_name=N'DWIndependentBookSellers', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pMaintValidateDimAuthorsRestore', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Create or Alter Proc pMaintValidateDimAuthorsRestore
--*************************************************************************--
-- Desc:This Sproc validates DimAuthors in the restore database . 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 09/10/23, Ramkumar Rajanbabu, Completed pMaintValidateDimAuthorsRestore
--*************************************************************************--
As
Begin
	DECLARE @RC INT = 0;
	BEGIN TRY
		DECLARE @CurrentCount INT, @RestoredCount INT;
		DECLARE @CurrentDateTime DateTime = GetDate()
		
		-- Test Row Counts DimDates
		SELECT @CurrentCount = COUNT(*) FROM [DWIndependentBookSellers].[dbo].[DimAuthors];
		SELECT @RestoredCount = COUNT(*) FROM [DWIndependentBookSellersRestored].[dbo].[DimAuthors];
			IF (@CurrentCount = @RestoredCount)
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimAuthorsRestore'',
					 @ValidationStatus = ''Success'',
					 @ValidationMessage = ''DimAuthors Row Count Test''
			ELSE
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimAuthorsRestore'',
					 @ValidationStatus = ''Failed'',
					 @ValidationMessage = ''DimAuthors Row Count Test''
		-- Compare Data
		DECLARE @DuplicateCount INT
		SELECT @DuplicateCount = Count(*)
			FROM
			(SELECT * FROM [DWIndependentBookSellers].[dbo].[DimAuthors]
             EXCEPT
             SELECT * FROM [DWIndependentBookSellersRestored].[dbo].[DimAuthors]) AS Results
		IF @DuplicateCount = 0
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimAuthorsRestore'',
					 @ValidationStatus = ''Success'',
					 @ValidationMessage = ''DimAuthors Duplicate Test''
		ELSE
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimAuthorsRestore'',
					 @ValidationStatus = ''Failed'',
					 @ValidationMessage = ''DimAuthors Duplicate Test''
		EXEC pInsMaintLog
			@MaintAction = ''pMaintValidateDimAuthorsRestore'',
			@MaintLogMessage = ''DimAuthors Validated. Check Validation Log!'';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = ''pMaintValidateDimAuthorsRestore'',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go', 
		@database_name=N'DWIndependentBookSellers', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pMaintValidateDimTitlesRestore', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Create or Alter Proc pMaintValidateDimTitlesRestore
--*************************************************************************--
-- Desc:This Sproc validates DimTitles in the restore database . 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 09/11/23, Ramkumar Rajanbabu, Completed pMaintValidateDimTitlesRestore
--*************************************************************************--
As
Begin
	DECLARE @RC INT = 0;
	BEGIN TRY
		DECLARE @CurrentCount INT, @RestoredCount INT;
		DECLARE @CurrentDateTime DateTime = GetDate()
		
		-- Test Row Counts DimDates
		SELECT @CurrentCount = COUNT(*) FROM [DWIndependentBookSellers].[dbo].[DimTitles];
		SELECT @RestoredCount = COUNT(*) FROM [DWIndependentBookSellersRestored].[dbo].[DimTitles];
			IF (@CurrentCount = @RestoredCount)
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimTitlesRestore'',
					 @ValidationStatus = ''Success'',
					 @ValidationMessage = ''DimTitles Row Count Test''
			ELSE
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimTitlesRestore'',
					 @ValidationStatus = ''Failed'',
					 @ValidationMessage = ''DimTitles Row Count Test''
		-- Compare Data
		DECLARE @DuplicateCount INT
		SELECT @DuplicateCount = Count(*)
			FROM
			(SELECT * FROM [DWIndependentBookSellers].[dbo].[DimTitles]
             EXCEPT
             SELECT * FROM [DWIndependentBookSellersRestored].[dbo].[DimTitles]) AS Results
		IF @DuplicateCount = 0
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimTitlesRestore'',
					 @ValidationStatus = ''Success'',
					 @ValidationMessage = ''DimTitles Duplicate Test''
		ELSE
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimTitlesRestore'',
					 @ValidationStatus = ''Failed'',
					 @ValidationMessage = ''DimTitles Duplicate Test''
		EXEC pInsMaintLog
			@MaintAction = ''pMaintValidateDimTitlesRestore'',
			@MaintLogMessage = ''DimTitles Validated. Check Validation Log!'';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = ''pMaintValidateDimTitlesRestore'',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go', 
		@database_name=N'DWIndependentBookSellers', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pMaintValidateDimStoresRestore', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Create or Alter Proc pMaintValidateDimStoresRestore
--*************************************************************************--
-- Desc:This Sproc validates DimStores in the restore database . 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 09/11/23, Ramkumar Rajanbabu, Completed pMaintValidateDimStoresRestore
--*************************************************************************--
As
Begin
	DECLARE @RC INT = 0;
	BEGIN TRY
		DECLARE @CurrentCount INT, @RestoredCount INT;
		DECLARE @CurrentDateTime DateTime = GetDate()
		
		-- Test Row Counts DimDates
		SELECT @CurrentCount = COUNT(*) FROM [DWIndependentBookSellers].[dbo].[DimStores];
		SELECT @RestoredCount = COUNT(*) FROM [DWIndependentBookSellersRestored].[dbo].[DimStores];
			IF (@CurrentCount = @RestoredCount)
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimStoresRestore'',
					 @ValidationStatus = ''Success'',
					 @ValidationMessage = ''DimStores Row Count Test''
			ELSE
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimStoresRestore'',
					 @ValidationStatus = ''Failed'',
					 @ValidationMessage = ''DimStores Row Count Test''
		-- Compare Data
		DECLARE @DuplicateCount INT
		SELECT @DuplicateCount = Count(*)
			FROM
			(SELECT * FROM [DWIndependentBookSellers].[dbo].[DimStores]
             EXCEPT
             SELECT * FROM [DWIndependentBookSellersRestored].[dbo].[DimStores]) AS Results
		IF @DuplicateCount = 0
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimStoresRestore'',
					 @ValidationStatus = ''Success'',
					 @ValidationMessage = ''DimStores Duplicate Test''
		ELSE
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateDimStoresRestore'',
					 @ValidationStatus = ''Failed'',
					 @ValidationMessage = ''DimStores Duplicate Test''
		EXEC pInsMaintLog
			@MaintAction = ''pMaintValidateDimStoresRestore'',
			@MaintLogMessage = ''DimStores Validated. Check Validation Log!'';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = ''pMaintValidateDimStoresRestore'',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go', 
		@database_name=N'DWIndependentBookSellers', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pMaintValidateFactTitleAuthorsRestore', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Create or Alter Proc pMaintValidateFactTitleAuthorsRestore
--*************************************************************************--
-- Desc:This Sproc validates FactTitleAuthors in the restore database . 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 09/11/23, Ramkumar Rajanbabu, Completed pMaintValidateFactTitleAuthorsRestore
--*************************************************************************--
As
Begin
	DECLARE @RC INT = 0;
	BEGIN TRY
		DECLARE @CurrentCount INT, @RestoredCount INT;
		DECLARE @CurrentDateTime DateTime = GetDate()
		
		-- Test Row Counts DimDates
		SELECT @CurrentCount = COUNT(*) FROM [DWIndependentBookSellers].[dbo].[FactTitleAuthors];
		SELECT @RestoredCount = COUNT(*) FROM [DWIndependentBookSellersRestored].[dbo].[FactTitleAuthors];
			IF (@CurrentCount = @RestoredCount)
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateFactTitleAuthorsRestore'',
					 @ValidationStatus = ''Success'',
					 @ValidationMessage = ''FactTitleAuthors Row Count Test''
			ELSE
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateFactTitleAuthorsRestore'',
					 @ValidationStatus = ''Failed'',
					 @ValidationMessage = ''FactTitleAuthors Row Count Test''
		-- Compare Data
		DECLARE @DuplicateCount INT
		SELECT @DuplicateCount = Count(*)
			FROM
			(SELECT * FROM [DWIndependentBookSellers].[dbo].[FactTitleAuthors]
             EXCEPT
             SELECT * FROM [DWIndependentBookSellersRestored].[dbo].[FactTitleAuthors]) AS Results
		IF @DuplicateCount = 0
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateFactTitleAuthorsRestore'',
					 @ValidationStatus = ''Success'',
					 @ValidationMessage = ''FactTitleAuthors Duplicate Test''
		ELSE
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateFactTitleAuthorsRestore'',
					 @ValidationStatus = ''Failed'',
					 @ValidationMessage = ''FactTitleAuthors Duplicate Test''
		EXEC pInsMaintLog
			@MaintAction = ''pMaintValidateFactTitleAuthorsRestore'',
			@MaintLogMessage = ''FactTitleAuthors Validated. Check Validation Log!'';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = ''pMaintValidateFactTitleAuthorsRestore'',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go', 
		@database_name=N'DWIndependentBookSellers', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'pMaintValidateFactSalesRestore', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Create or Alter Proc pMaintValidateFactSalesRestore
--*************************************************************************--
-- Desc:This Sproc validates FactSales in the restore database . 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 09/11/23, Ramkumar Rajanbabu, Completed pMaintValidateFactSalesRestore
--*************************************************************************--
As
Begin
	DECLARE @RC INT = 0;
	BEGIN TRY
		DECLARE @CurrentCount INT, @RestoredCount INT;
		DECLARE @CurrentDateTime DateTime = GetDate()
		
		-- Test Row Counts DimDates
		SELECT @CurrentCount = COUNT(*) FROM [DWIndependentBookSellers].[dbo].[FactSales];
		SELECT @RestoredCount = COUNT(*) FROM [DWIndependentBookSellersRestored].[dbo].[FactSales];
			IF (@CurrentCount = @RestoredCount)
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateFactSalesRestore'',
					 @ValidationStatus = ''Success'',
					 @ValidationMessage = ''FactSales Row Count Test''
			ELSE
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateFactSalesRestore'',
					 @ValidationStatus = ''Failed'',
					 @ValidationMessage = ''FactSales Row Count Test''
		-- Compare Data
		DECLARE @DuplicateCount INT
		SELECT @DuplicateCount = Count(*)
			FROM
			(SELECT * FROM [DWIndependentBookSellers].[dbo].[FactSales]
             EXCEPT
             SELECT * FROM [DWIndependentBookSellersRestored].[dbo].[FactSales]) AS Results
		IF @DuplicateCount = 0
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateFactSalesRestore'',
					 @ValidationStatus = ''Success'',
					 @ValidationMessage = ''FactSales Duplicate Test''
		ELSE
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = ''pMaintValidateFactSalesRestore'',
					 @ValidationStatus = ''Failed'',
					 @ValidationMessage = ''FactSales Duplicate Test''
		EXEC pInsMaintLog
			@MaintAction = ''pMaintValidateFactSalesRestore'',
			@MaintLogMessage = ''FactSales Validated. Check Validation Log!'';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = ''pMaintValidateFactSalesRestore'',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go', 
		@database_name=N'DWIndependentBookSellers', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1

EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run at 2AM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20230911, 
		@active_end_date=99991231, 
		@active_start_time=20000, 
		@active_end_time=235959, 
		@schedule_uid=N'37b4b070-5801-4393-b02c-c1db07bbde43'

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'

COMMIT TRANSACTION

END TRY
BEGIN CATCH
	IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
END CATCH
GO