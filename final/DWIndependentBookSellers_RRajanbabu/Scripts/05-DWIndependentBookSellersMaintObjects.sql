--*************************************************************************--
-- Title: Final database Maintenance objects
-- Author: RRoot
-- Desc: This file creates several Final DB Maintenance objects
-- Change Log: When,Who,What
-- 2020-02-07,RRoot,Created File
-- Todo: 09/10/23, Ramkumar Rajanbabu, Completed pMaintIndexes, pMaintDBBackup, pMaintRestore,
-- pMaintValidateDimAuthorsRestore
-- Todo: 09/11/23, Ramkumar Rajanbabu, Completed pMaintValidateDimTitlesRestore, pMaintValidateDimStoresRestore, 
-- pMaintValidateFactTitleAuthorsRestore, 
-- Incomplete pMaintValidateFactSalesRestore
--**************************************************************************--
Use DWIndependentBookSellers;
go

--********************************************************************--
-- 0) Create Logging objects
--********************************************************************--

-- Maintenance Logging
-- Drop Table MaintLog;
If NOT Exists(Select * From Sys.tables where Name = 'MaintLog')
  Create Table MaintLog
  (MaintLogID int identity Primary Key
  ,MaintDateAndTime datetime Default GetDate()
  ,MaintAction varchar(100)
  ,MaintLogMessage varchar(2000)
  );
go

Create or Alter View vMaintLog
As
 Select
  MaintLogID
 ,MaintDate = Format(MaintDateAndTime, 'D', 'en-us')
 ,MaintTime = Format(Cast(MaintDateAndTime as datetime2), 'HH:mm', 'en-us')
 ,MaintAction
 ,MaintLogMessage
 From MaintLog;
go

Create or Alter Proc pInsMaintLog
 (@MaintAction varchar(100), @MaintLogMessage varchar(2000))
--*************************************************************************--
-- Desc:This Sproc creates an admin table for Maintenance Logging. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As
Begin
  Declare @RC int = 0;
  Begin Try
    Begin Tran;
    Insert Into MaintLog
     (MaintAction,MaintLogMessage)
    Values
     (@MaintAction,@MaintLogMessage);
    Commit Tran;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback Tran;
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
    Set @ErrorMessage = 'Insert to Maintlog failed' + @ErrorMessage;
    Print @ErrorMessage
    Raiserror(@ErrorMessage, 15, 1);
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

-- Test Maint Logging 
--Exec pInsMaintLog 'Test Action', 'Test Message';
--Select * From vMaintLog;


-- Validation Logging -- 
-- Drop Table ValidationLog;
If NOT Exists(Select * From Sys.tables where Name = 'ValidationLog')
Create Table ValidationLog  
(ValidationID int Primary Key Identity
,ValidationDateTime Datetime
,ValidationObject varchar(100)
,ValidationStatus varchar(10) 
   Constraint ckValidationStatus Check (ValidationStatus in ('Success', 'Failed', 'Skipped'))
,ValidationMessage varchar(1000)
);
go

Create or Alter View vValidationLog 
As 
  Select 
   ValidationID 
  ,ValidationDateTime 
  ,ValidationObject
  ,ValidationStatus
  ,ValidationMessage
  From ValidationLog;
go

Create or Alter Proc pInsValidationLog
(@ValidationDateTime Datetime
,@ValidationObject varchar(100)
,@ValidationStatus varchar(10)
,@ValidationMessage varchar(1000)
) 
--*************************************************************************--
-- Desc:This Sproc creates an admin table for data validation Logging. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As
  Begin
    Declare @RC int = 0;
    Begin Try
      Begin Tran
        Insert Into ValidationLog
         (ValidationDateTime, ValidationObject, ValidationStatus, ValidationMessage)
        Values
        (@ValidationDateTime, @ValidationObject, @ValidationStatus, @ValidationMessage)
      Commit Tran;
      Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback Tran;
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
    Exec pInsMaintLog 
	     @MaintAction = 'pInsValidationLog'
	    ,@MaintLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

/*-- Test Validation Logging 
  Declare @CurrentDT DateTime = GetDate()
  Exec pInsValidationLog @CurrentDT ,'Test Object','Skipped', 'Test Message';
  Select * From vValidationLog;
*/

--********************************************************************--
-- 0) Create Maintenance objects
--********************************************************************--

go
Create or Alter Proc pMaintIndexes
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
			@MaintAction = 'pMaintIndexes',
			@MaintLogMessage = 'Indexes Recreated';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = 'pMaintIndexes',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go
-- Exec pMaintIndexes; Select * From vMaintLog

go
Create or Alter Proc pMaintDBBackup
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
			TO DISK = N'C:\Users\User\Documents\github\uw-pce-sql-server-development-sqldev330\_SQL330\DWIndependentBookSellers.bak'
			WITH INIT;

		EXEC pInsMaintLog
			@MaintAction = 'pMaintDBBackup',
			@MaintLogMessage = 'Created DB Backup';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = 'pMaintDBBackup',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go

-- Exec pMaintDBBackup; Select * From vMaintLog

go
Create or Alter Proc pMaintRestore
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
		FROM DISK = N'C:\Users\User\Documents\github\uw-pce-sql-server-development-sqldev330\_SQL330\DWIndependentBookSellers.bak'
		WITH FILE = 1,
			MOVE N'DWIndependentBookSellers' TO N'C:\Users\User\Documents\github\uw-pce-sql-server-development-sqldev330\_SQL330\DWIndependentBookSellersRestored.mdf',
			MOVE N'DWIndependentBookSellers_log' TO N'C:\Users\User\Documents\github\uw-pce-sql-server-development-sqldev330\_SQL330\DWIndependentBookSellersRestored.ldf',
			RECOVERY,
			REPLACE;
		ALTER DATABASE DWIndependentBookSellersRestored SET READ_ONLY WITH NO_WAIT;

		EXEC pInsMaintLog
			@MaintAction = 'pMaintRestore',
			@MaintLogMessage = 'Restored DWIndependentBookSellers backup to DWIndependentBookSellersRestored';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = 'pMaintRestore',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go
-- Exec pMaintRestore; Select * From vMaintLog

Go
Create or Alter Proc pMaintValidateDimDatesRestore
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
               ,@ValidationObject = 'pMaintValidateDimDatesRestore'
               ,@ValidationStatus = 'Success'
               ,@ValidationMessage = 'DimDates Row Count Test'
      Else
          Exec pInsValidationLog 
                @ValidationDateTime = @CurrentDateTime
               ,@ValidationObject = 'pMaintValidateDimDatesRestore'
               ,@ValidationStatus = 'Failed'
               ,@ValidationMessage = 'DimDates Row Count Test'
    
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
               ,@ValidationObject = 'pMaintValidateDimDatesRestore'
               ,@ValidationStatus = 'Success'
               ,@ValidationMessage = 'DimDates Duplicate Test'
    Else
          Exec pInsValidationLog 
                @ValidationDateTime = @CurrentDateTime
               ,@ValidationObject = 'pMaintValidateDimDatesRestore'
               ,@ValidationStatus = 'Failed'
               ,@ValidationMessage = 'DimDates Duplicate Test'

    Exec pInsMaintLog
	         @MaintAction = 'pMaintValidateDimDatesRestore'
	        ,@MaintLogMessage = 'DimDates Validated. Check Validation Log!';
    Set @RC = 1;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	  Exec pInsMaintLog 
	          @MaintAction = 'pMaintValidateDimDatesRestore'
	         ,@MaintLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
-- Exec pMaintValidateDimDatesRestore; Select * From vMaintLog; Select * From vValidationLog

Go
Create or Alter Proc pMaintValidateDimAuthorsRestore
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
					 @ValidationObject = 'pMaintValidateDimAuthorsRestore',
					 @ValidationStatus = 'Success',
					 @ValidationMessage = 'DimAuthors Row Count Test'
			ELSE
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = 'pMaintValidateDimAuthorsRestore',
					 @ValidationStatus = 'Failed',
					 @ValidationMessage = 'DimAuthors Row Count Test'
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
					 @ValidationObject = 'pMaintValidateDimAuthorsRestore',
					 @ValidationStatus = 'Success',
					 @ValidationMessage = 'DimAuthors Duplicate Test'
		ELSE
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = 'pMaintValidateDimAuthorsRestore',
					 @ValidationStatus = 'Failed',
					 @ValidationMessage = 'DimAuthors Duplicate Test'
		EXEC pInsMaintLog
			@MaintAction = 'pMaintValidateDimAuthorsRestore',
			@MaintLogMessage = 'DimAuthors Validated. Check Validation Log!';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = 'pMaintValidateDimAuthorsRestore',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go

-- Exec pMaintValidateDimAuthorsRestore; Select * From vMaintLog; Select * From vValidationLog

Go
Create or Alter Proc pMaintValidateDimTitlesRestore
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
					 @ValidationObject = 'pMaintValidateDimTitlesRestore',
					 @ValidationStatus = 'Success',
					 @ValidationMessage = 'DimTitles Row Count Test'
			ELSE
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = 'pMaintValidateDimTitlesRestore',
					 @ValidationStatus = 'Failed',
					 @ValidationMessage = 'DimTitles Row Count Test'
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
					 @ValidationObject = 'pMaintValidateDimTitlesRestore',
					 @ValidationStatus = 'Success',
					 @ValidationMessage = 'DimTitles Duplicate Test'
		ELSE
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = 'pMaintValidateDimTitlesRestore',
					 @ValidationStatus = 'Failed',
					 @ValidationMessage = 'DimTitles Duplicate Test'
		EXEC pInsMaintLog
			@MaintAction = 'pMaintValidateDimTitlesRestore',
			@MaintLogMessage = 'DimTitles Validated. Check Validation Log!';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = 'pMaintValidateDimTitlesRestore',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go

-- Exec pMaintValidateDimTitlesRestore; Select * From vMaintLog; Select * From vValidationLog

Create or Alter Proc pMaintValidateDimStoresRestore
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
					 @ValidationObject = 'pMaintValidateDimStoresRestore',
					 @ValidationStatus = 'Success',
					 @ValidationMessage = 'DimStores Row Count Test'
			ELSE
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = 'pMaintValidateDimStoresRestore',
					 @ValidationStatus = 'Failed',
					 @ValidationMessage = 'DimStores Row Count Test'
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
					 @ValidationObject = 'pMaintValidateDimStoresRestore',
					 @ValidationStatus = 'Success',
					 @ValidationMessage = 'DimStores Duplicate Test'
		ELSE
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = 'pMaintValidateDimStoresRestore',
					 @ValidationStatus = 'Failed',
					 @ValidationMessage = 'DimStores Duplicate Test'
		EXEC pInsMaintLog
			@MaintAction = 'pMaintValidateDimStoresRestore',
			@MaintLogMessage = 'DimStores Validated. Check Validation Log!';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = 'pMaintValidateDimStoresRestore',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go
-- Exec pMaintValidateDimStoresRestore; Select * From vMaintLog; Select * From vValidationLog

Create or Alter Proc pMaintValidateFactTitleAuthorsRestore
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
					 @ValidationObject = 'pMaintValidateFactTitleAuthorsRestore',
					 @ValidationStatus = 'Success',
					 @ValidationMessage = 'FactTitleAuthors Row Count Test'
			ELSE
				EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = 'pMaintValidateFactTitleAuthorsRestore',
					 @ValidationStatus = 'Failed',
					 @ValidationMessage = 'FactTitleAuthors Row Count Test'
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
					 @ValidationObject = 'pMaintValidateFactTitleAuthorsRestore',
					 @ValidationStatus = 'Success',
					 @ValidationMessage = 'FactTitleAuthors Duplicate Test'
		ELSE
			EXEC pInsValidationLog
					 @ValidationDateTime = @CurrentDateTime,
					 @ValidationObject = 'pMaintValidateFactTitleAuthorsRestore',
					 @ValidationStatus = 'Failed',
					 @ValidationMessage = 'FactTitleAuthors Duplicate Test'
		EXEC pInsMaintLog
			@MaintAction = 'pMaintValidateFactTitleAuthorsRestore',
			@MaintLogMessage = 'FactTitleAuthors Validated. Check Validation Log!';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsMaintLog
				@MaintAction = 'pMaintValidateFactTitleAuthorsRestore',
				@MaintLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go

-- Exec pMaintValidateFactTitleAuthorsRestore; Select * From vMaintLog; Select * From vValidationLog

Create or Alter Proc pMaintValidateFactSalesRestore
--*************************************************************************--
-- Desc:This Sproc validates Dim Authors in the restore database . 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code 
--*************************************************************************--
As
Begin
	Select 'ADD CODE HERE' as 'TODO'
End
Go
-- Exec pMaintValidateFactSalesRestore; Select * From vMaintLog; Select * From vValidationLog

-- Testing Code --
-------------------------------------------------
/*
-- Clear tables before test
Truncate Table MaintLog;
Select * From vMaintLog;
Truncate Table ValidationLog;
Select * From vValidationLog;

-- Test Maint
Set NoCount On
Exec [pMaintIndexes]
Exec [pMaintDBBackup]
Exec [pMaintRestore]
Exec [pMaintValidateDimDatesRestore]
Exec [pMaintValidateDimAuthorsRestore]
Exec [pMaintValidateDimTitlesRestore]
Exec [pMaintValidateDimStoresRestore]
Exec [pMaintValidateFactTitleAuthorsRestore]
Exec [pMaintValidateFactSalesRestore]
go

Select * From vMaintLog;
Select * From vValidationLog;

-- Test Validation
-- Force a failure
Update [dbo].[DimTitles] Set [TitleName] = 'ZZZZThe Busy Executive''s Database Guide' Where [TitleId] = 'BU1032';
Select * From [DWIndependentBookSellers].[dbo].[DimTitles]
Select * From [DWIndependentBookSellersRestored].[dbo].[DimTitles]

Exec [dbo].[pMaintValidateDimTitlesRestore];
Select * From vValidationLog Where ValidationObject = 'pMaintValidateDimTitlesRestore'


-- Reset to original value
Update [dbo].[DimTitles] Set [TitleName] = 'The Busy Executive''s Database Guide' Where [TitleId] = 'BU1032';
go

*/

