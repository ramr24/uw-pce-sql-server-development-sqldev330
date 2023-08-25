--*************************************************************************--
-- Title: Backup Basics
-- Author: RRoot
-- Desc: This file demonstrates how you can perform basic database backups.
-- Change Log: When,Who,What
-- 2021-018-19,RRoot,Created File
--**************************************************************************--

-- [Setup Code] -- 
---------------------------------------------------------------------------------------------------------
/* Create the following folder for this demo
!! MD C:\Backup Files
*/
USE [Master];
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

-- Let's create some starting data
USE [BackupDemoDB]
go
Create Table ProductList
 (ProductId int, ProductName nvarchar(100));
go
Insert into ProductList Values(1, 'ProdA');
Select * from ProductList; -- Check the data is there!
---------------------------------------------------------------------------------------------------------


-- [Performing a Full Backup] -- 
---------------------------------------------------------------------------------------------------------
-- Create a simple Full backup uses code like this:
Backup Database BackupDemoDB -- typically done daily, weekly
 To Disk ='C:\BackupFiles\BackupDemoDB_Full.bak' -- To Disk or Tape are the options
  With Init; -- Removes the current contents of the backup file before adding this backup
go

-- As you make database backups, you test those backups!
Use [Master]
go

-- Step 0) IF it is in use, Kick everyone off of the database before a restore
Alter Database [BackupDemoReadOnlyDB] Set Single_User with Rollback Immediate;
go

-- Step 1) Restore the database on the same or different server/database
Restore database [BackupDemoReadOnlyDB] 
 From Disk = N'C:\BackupFiles\BackupDemoDB_Full.bak' 
  With File = 1
     , Move N'BackupDemoDB' TO N'C:\BackupFiles\BackupDemoReadOnlyDB.mdf'
     , Move N'BackupDemoDB_log' TO N'C:\BackupFiles\BackupDemoReadOnlyDB.ldf'
     , Recovery -- Makes the DB open for use
     , Replace -- Replaces the DB as needed 
go

-- Step 2) Write some code to test the Restore worked
Select * From BackupDemoDB.dbo.ProductList;
Select * From BackupDemoReadOnlyDB.dbo.ProductList;
go
Create Proc RestoreTest
As 
Begin 
  -- Test Row Counts
  Declare @CurrentCount int
        , @RestoredCount int;

  Select @CurrentCount = count(*) From BackupDemoDB.dbo.ProductList;
  Select @RestoredCount = count(*) From BackupDemoReadOnlyDB.dbo.ProductList;

  If (@CurrentCount = @RestoredCount) 
    Select [Test] = 'Row Count Test: Passed';
  Else
    Select [Test] = 'Row Count Test: Failed';

  -- Review Data
  Declare @DifferenceCount int;
  With DataDifferenceCheck
  As (
  Select * From BackupDemoDB.dbo.ProductList
  Except
  Select * From BackupDemoReadOnlyDB.dbo.ProductList
  )
  Select @DifferenceCount = Count(*) From DataDifferenceCheck

  If (@DifferenceCount = 0) 
    Select [Test] = 'Row Count Test: Passed';
  Else
    Select [Test] = 'Row Count Test: Failed';
End
go
Execute RestoreTest;


-- As you make changes to the database...
Insert into BackupDemoDB.dbo.ProductList Values(2, 'ProdB');
Select * from BackupDemoDB.dbo.ProductList;
-- ...The Restore will no longer be valid
go
Execute RestoreTest;

-- So, you must continue to back it up
Backup Database BackupDemoDB -- typically done daily, weekly
 To Disk ='C:\BackupFiles\BackupDemoDB_Full.bak' -- To Disk or Tape are the options
  With Init; -- Removes the current contents of the backup file before adding this backup
go

-- And continue to restore it!
Restore database [BackupDemoReadOnlyDB] 
 From Disk = N'C:\BackupFiles\BackupDemoDB_Full.bak' 
  With File = 1
     , Move N'BackupDemoDB' TO N'C:\BackupFiles\BackupDemoReadOnlyDB.mdf'
     , Move N'BackupDemoDB_log' TO N'C:\BackupFiles\BackupDemoReadOnlyDB.ldf'
     , Recovery -- Makes the DB open for use
     , Replace -- Replaces the DB as needed 
go
-- And continue to check it too!
Execute RestoreTest;
go

'IMPORTANT: You should create Maintance Objects to perform mantanance tasks'
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
Exec pMaintInsLog 'Test Action', 'Test Message';
Select * From vMaintLog;

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
      Exec pInsMaintLog
	        @MaintAction = 'pInsValidationLog'
	       ,@MaintLogMessage = 'Performed data validation task';
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

-- Test Validation Logging 
Declare @CurrentDT DateTime = GetDate()
Exec pInsValidationLog @CurrentDT ,'Test Object','Skipped', 'Test Message';
Select * From vValidationLog;
---------------------------------------------------------------------------------------------------------


-- [Backing up the Log File] --
---------------------------------------------------------------------------------------------------------
-- You can capture DB changes by performing a Log backup instead of doing all full backups
-- This can be much faster! 

-- When you make changes to the database it records the change in the LOG file
Insert into BackupDemoDB.dbo.ProductList Values(3, 'ProdC');
Select * from BackupDemoDB.dbo.ProductList;

-- You can add a log file backup instead of another Full backup
-- but, you must have one Full backup to start with!
Backup LOG BackupDemoDB -- typically done daily or several times a day
 To Disk ='C:\BackupFiles\BackupDemoDB_Log.bak' -- To Disk or Tape are the options
  With Init; -- Removes the current contents of the backup file before adding this backup
go

-- Now you still continue to test those backup restores!
-- but the steps are a bit different!
USE [master]
go

-- Step 1)
Restore database [BackupDemoReadOnlyDB] 
 From Disk = N'C:\BackupFiles\BackupDemoDB_Full.bak' 
  With File = 1
     , Move N'BackupDemoDB' TO N'C:\BackupFiles\BackupDemoReadOnlyDB.mdf'
     , Move N'BackupDemoDB_log' TO N'C:\BackupFiles\BackupDemoReadOnlyDB.ldf'
     , NORecovery -- Makes the DB NOT open for use (So you can restore more changes!)
     , Replace -- Replaces the DB as needed 
go

-- Step 2)
Restore LOG [BackupDemoReadOnlyDB] 
 From Disk = N'C:\BackupFiles\BackupDemoDB_Log.bak' 
  With File = 1
    , Recovery -- Now the database can be used again!
go

-- Step 3) continue to check it, of course!
Execute RestoreTest;
go

-- Over the course of a day you could have many changes to the table 
Insert into BackupDemoDB.dbo.ProductList Values(4, 'ProdD');
Select * from BackupDemoDB.dbo.ProductList;
Insert into BackupDemoDB.dbo.ProductList Values(5, 'ProdE');
Select * from BackupDemoDB.dbo.ProductList;

-- So, you perform periodic log file backups during the day
Backup LOG BackupDemoDB -- typically done daily or several times a day
 To Disk ='C:\BackupFiles\BackupDemoDB_Log.bak'
  -- With Init; --< Do NOT Remove the current contents of the backup file
                --, just add another LOGICAL backup file to it!
go

-- And repeat the process as the day goes on...
Insert into BackupDemoDB.dbo.ProductList Values(6, 'ProdF');
Select * from BackupDemoDB.dbo.ProductList;
Backup LOG BackupDemoDB -- typically done daily or several times a day
 To Disk ='C:\BackupFiles\BackupDemoDB_Log.bak'
  -- With Init; --< Do NOT Remove the current contents of the backup file
                --, just add another LOGICAL backup file to it!
go

-- You can immediatly restore the testing DB or just do that once a day as needed
USE [master]
-- Step 1)
Restore database [BackupDemoReadOnlyDB] 
From Disk = N'C:\BackupFiles\BackupDemoDB_Full.bak' 
With File = 1
   , Move N'BackupDemoDB' TO N'C:\BackupFiles\BackupDemoReadOnlyDB.mdf'
   , Move N'BackupDemoDB_log' TO N'C:\BackupFiles\BackupDemoReadOnlyDB.ldf'
   , NORecovery -- Don't recover yet!
   , Replace -- Replaces the DB as needed 
go

-- Step 2)
Restore LOG [BackupDemoReadOnlyDB] 
 From Disk = N'C:\BackupFiles\BackupDemoDB_Log.bak' 
  With File = 1
   , NORecovery -- Don't recover yet!
go

-- Step 3)
Restore LOG [BackupDemoReadOnlyDB] 
 From Disk = N'C:\BackupFiles\BackupDemoDB_Log.bak' 
  With File = 2
   , NORecovery -- Don't recover yet!
go

-- Step 4)
Restore LOG [BackupDemoReadOnlyDB] 
 From Disk = N'C:\BackupFiles\BackupDemoDB_Log.bak' 
  With File = 3
   , Recovery -- Now the database will be open for use
              -- Only recover on the last restore
go
-- Step 5) And, finally check it!
Execute RestoreTest;
go
---------------------------------------------------------------------------------------------------------

-- [Getting the MetaData in a Backup File] --
---------------------------------------------------------------------------------------------------------
-- Each backup file has metadata as well as the backup data. 
-- You can see this metadata like this:

-- Get a list of logical backups in the file
Restore HeaderOnly From DISK = N'C:\BackupFiles\BackupDemoDB_Full.bak' 
Restore HeaderOnly From DISK = N'C:\BackupFiles\BackupDemoDB_Log.bak' 

-- Get details about a logical backup
Restore FileListOnly 
 From DISK = N'C:\BackupFiles\BackupDemoDB_Full.bak' 
  With File = 1
Restore FileListOnly 
 From DISK = N'C:\BackupFiles\BackupDemoDB_Log.bak' 
  With File = 1
Restore FileListOnly 
 From DISK = N'C:\BackupFiles\BackupDemoDB_Log.bak' 
  With File = 2
Restore FileListOnly 
 From DISK = N'C:\BackupFiles\BackupDemoDB_Log.bak' 
  With File = 3
go

-- Verify the Backup Files are good WITHOUT restoring them (Not recommend as only validation)
Restore VerifyOnly 
 From DISK = N'C:\BackupFiles\BackupDemoDB_Full.bak' 
  With File = 1
Restore VerifyOnly 
 From DISK = N'C:\BackupFiles\BackupDemoDB_Log.bak' 
  With File = 1
Restore VerifyOnly 
 From DISK = N'C:\BackupFiles\BackupDemoDB_Log.bak' 
  With File = 2
Restore VerifyOnly 
 From DISK = N'C:\BackupFiles\BackupDemoDB_Log.bak' 
  With File = 3

/*
'Verifies the backup but does not restore it, and checks to see that the backup
 set is complete and the entire backup is readable. 
 However, RESTORE VERIFYONLY does not attempt to verify the structure of the data 
 contained in the backup volumes. In Microsoft SQL Server, 
 RESTORE VERIFYONLY has been enhanced to do additional checking on the data to 
 increase the probability of detecting errors. The goal is to be as close to an 
 actual restore operation as practical. For more information, see the Remarks.
If the backup is valid, the SQL Server Database Engine returns a success message.
https://docs.microsoft.com/en-us/sql/t-sql/statements/restore-statements-verifyonly-transact-sql
*/