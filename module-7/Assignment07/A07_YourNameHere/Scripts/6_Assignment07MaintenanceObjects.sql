--*************************************************************************--
-- Title: Assignment 07 - Maintenance Objects
-- Author: RRoot
-- Desc: This file creates several maintenance objects.
-- Change Log: When,Who,What
-- 2021-018-19,RRoot,Created File
--**************************************************************************--

Use TempDB;
go

-- Maintenance Logging
-- Drop Table MaintLog;
If NOT Exists(Select * From Sys.tables where Name = 'MaintLog')
  Create --Drop
  Table MaintLog
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
Exec pInsMaintLog @MaintAction = 'Test Action', @MaintLogMessage = 'Test Message';
Select * From vMaintLog;
go

-- Validation Logging -- 
-- Drop Table ValidationLog;
If NOT Exists(Select * From Sys.tables where Name = 'ValidationLog')
Create -- Drop
Table ValidationLog  
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
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

-- Test Validation Logging 
Declare @CurrentDT DateTime = GetDate()
Exec pInsValidationLog @CurrentDT ,'Test Object','Skipped', 'Test Message';
Select * From vValidationLog;