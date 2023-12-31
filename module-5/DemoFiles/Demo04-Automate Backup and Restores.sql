--*************************************************************************--
-- Title: Automate Backups Demo
-- Author: RRoot
-- Desc: This file creates, restores, and tests a database backup.
-- Change Log: When,Who,What
-- 2018-02-07,RRoot,Created File
--**************************************************************************--

--[ Automate Backup and Restores ]--
USE [Master];
go
-- Step 1: Make a copy of the current database
BACKUP DATABASE [Northwind] 
TO DISK = N'C:\_BISolutions\Northwind.bak' 
WITH INIT;

-- Step 2: Restore the copy as a different database for reporting
RESTORE DATABASE [NorthwindReports] 
FROM DISK = N'C:\_BISolutions\Northwind.bak' 
WITH FILE = 1
  , MOVE N'Northwind' TO N'C:\_BISolutions\northwindReports.mdf'
  , MOVE N'Northwind_log' TO N'C:\_BISolutions\northwindReports.ldf'
  , RECOVERY -- Makes the DB open for use
  , REPLACE;-- Replaces the DB as needed 

-- Step 3: Set the reporting database to read-only
ALTER DATABASE [NorthwindReports] SET READ_ONLY WITH NO_WAIT;


-- Step 4: Test that the restore worked
Select * From Northwind.dbo.Products;
Select * From [NorthwindReports].dbo.Products;

-- Step 5: Create Table and Sproc to log automation processing
Use [TempDB];
go
Create -- Drop
Table AutomationProcessLog 
(ProcessID int Primary Key Identity
,ProcessDateTime Datetime
,ProcessObject varchar(100)
,ProcessStatus varchar(10) 
   Constraint ckProcessStatus Check (ProcessStatus in ('Success', 'Failed', 'Skipped'))
,ProcessMessage varchar(1000)
);
go
If Exists (SELECT name FROM sys.objects WHERE name = N'pInsAutomationProcessLog')
  Drop Proc pInsAutomationProcessLog;
go
Create Proc pInsAutomationProcessLog
(@ProcessDateTime Datetime
,@ProcessObject varchar(100)
,@ProcessStatus varchar(10)
,@ProcessMessage varchar(1000)
) As
  Begin
    Insert Into AutomationProcessLog
     (ProcessDateTime, ProcessObject, ProcessStatus, ProcessMessage)
    Values
    (@ProcessDateTime, @ProcessObject, @ProcessStatus, @ProcessMessage)
  End
go
Declare @CurrentDT DateTime = GetDate()
Exec pInsAutomationProcessLog @CurrentDT ,'Test Object','Skipped', 'Test Message';
Select * From AutomationProcessLog;

--Step 6: Create a Spoc to test the restored database
If Exists (SELECT name FROM sys.objects WHERE name = N'pTestRestore')
  Drop Proc pTestRestore;
go
Create Proc pTestRestore
As
  Begin
    Declare @CurrentCount int, @RestoredCount int; 
    Declare @CurrentDateTime DateTime = GetDate()
    -- Test Row Counts
    Select @CurrentCount = count(*) From Northwind.dbo.Products;
    Select @RestoredCount = count(*) From NorthwindReports.dbo.Products;
        If (@CurrentCount = @RestoredCount) 
          Exec pInsAutomationProcessLog 
                @ProcessDateTime = @CurrentDateTime
               ,@ProcessObject = 'pTestRestore'
               ,@ProcessStatus = 'Success'
               ,@ProcessMessage ='Row Count Test: Passed'
    Else
          Exec pInsAutomationProcessLog 
                @ProcessDateTime = @CurrentDateTime
               ,@ProcessObject = 'pTestRestore'
               ,@ProcessStatus = 'Failed'
               ,@ProcessMessage ='Row Count Test: Failed'
    -- Compare Data --
    Declare @DuplicateCount int
    Select  @DuplicateCount = Count(*) 
            From 
            (Select * From Northwind.dbo.Products 
             Except
             Select * From NorthwindReports.dbo.Products) as Results
    If @DuplicateCount = 0
         Exec pInsAutomationProcessLog 
                @ProcessDateTime = @CurrentDateTime
               ,@ProcessObject = 'pTestRestore'
               ,@ProcessStatus = 'Success'
               ,@ProcessMessage ='Duplicate Test: Passed'
    Else
          Exec pInsAutomationProcessLog 
                @ProcessDateTime = @CurrentDateTime
               ,@ProcessObject = 'pTestRestore'
               ,@ProcessStatus = 'Failed'
               ,@ProcessMessage ='Duplicate Test: Failed'

  End
go
Exec TempDB.dbo.pTestRestore;
go
Select * From AutomationProcessLog;