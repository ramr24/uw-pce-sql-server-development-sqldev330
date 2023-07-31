--*************************************************************************--
-- Title: Module03 DW ETL Process
-- Desc:This file will drop and create an ETL process for module 03's assignment. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- Todo: 07/30/23, Ramkumar Rajanbabu, Started Assignment 3
--*************************************************************************--

Use DWEmployeeProjects;
go

--********************************************************************--
-- 0) Create ETL metadata objects
--********************************************************************--
If NOT Exists(Select * From Sys.tables where Name = 'ETLMetadata')
  Create Table ETLMetadata
  (ETLMetadataID int identity Primary Key
  ,ETLDateAndTime datetime Default GetDate()
  ,ETLAction varchar(100)
  ,ETLMetadata varchar(2000)
  );
go

Create or Alter View vETLMetadata
As
 Select
  ETLMetadataID
 ,ETLDate = Format(ETLDateAndTime, 'D', 'en-us')
 ,ETLTime = Format(Cast(ETLDateAndTime as datetime2), 'HH:mm', 'en-us')
 ,ETLAction
 ,ETLMetadata
 From ETLMetadata;
go


Create or Alter Proc pETLInsMetadata
 (@ETLAction varchar(100), @ETLMetadata varchar(2000))
--*************************************************************************--
-- Desc:This Sproc create a admin table for logging ETL metadata. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As
Begin
  Declare @RC int = 0;
  Begin Try
    Insert Into ETLMetadata
     (ETLAction,ETLMetadata)
    Values
     (@ETLAction,@ETLMetadata)
    Set @RC = 1;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
    Exec pETLInsMetadata 
	     @ETLAction = 'pETLDropFks'
	    ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

--********************************************************************--
-- 1) Drop the Foreign Key CONSTRAINTS and Clear the tables
--********************************************************************--
Go
Create Or Alter Proc pETLDropFks
--*************************************************************************--
-- Desc:This Sproc drops the DW foreign keys. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 07/30/23, Ramkumar Rajanbabu, Added code to drop more FKs
--*************************************************************************--
As 
Begin
  Declare @RC int = 0;
  Begin Try
	  Select 'Todo: Drop FK for DimEmployees';
	  -- DROP CONSTRAINT
	  ALTER TABLE FactEmployeeProjectHours 
		DROP CONSTRAINT FK_FactEmployeeProjectHours_DimEmployees

	  Select 'Todo: Drop FK for DimProjects';
	  -- DROP CONSTRAINT
	  ALTER TABLE FactEmployeeProjectHours 
	    DROP CONSTRAINT FK_FactEmployeeProjectHours_DimProjects

	  ALTER TABLE FactEmployeeProjectHours 
	    DROP CONSTRAINT FK_FactEmployeeProjectHours_DimDates;

	  Exec pETLInsMetadata
	        @ETLAction = 'pETLDropFks'
	       ,@ETLMetadata = 'Dropped Foreign Keys';
    Set @RC = 1;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	  Exec pETLInsMetadata 
	        @ETLAction = 'pETLDropFks'
	       ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

Create Or Alter Proc pETLTruncateTables
--*************************************************************************--
-- Desc:This Sproc clears the data from all DW tables. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code to clear all table data
--*************************************************************************--
As 
Begin 
  Declare @RC int = 0;
  Begin Try
	  Truncate Table FactEmployeeProjectHours;
    Truncate Table DimDates;	
   
	  Select 'Todo: Clear DimEmployees';
	  -- TRUNCATE TABLE

	  Select 'Todo: Clear DimProjects';
	  -- TRUNCATE TABLE

	  Exec pETLInsMetadata
	        @ETLAction = 'pETLTruncateTables'
	       ,@ETLMetadata = 'Truncated Tables';
    Set @RC = 1;
  End Try
  Begin Catch
   Declare @ErrorMessage nvarchar(1000) = Error_Message()
	 Exec pETLInsMetadata 
	      @ETLAction = 'pETLTruncateTables'
	     ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

--********************************************************************--
-- 2) FILL the Tables
--********************************************************************--

/****** [dbo].[DimEmployees] ******/
Go
Create Or Alter View vETLDimEmployees
As
	Select
	  [EmployeeID] = ID
     ,[EmployeeName] = Cast((FName +  ' ' + LName) as varchar(100))
	From EmployeeProjects.dbo.Employees;
Go

Create Or Alter Proc pETLDimEmployees
--*************************************************************************--
-- Desc:This Sproc fills the DimEmployees table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code to fills the DimEmployees table. 
--*************************************************************************--
As 
Begin
  Declare @RC int = 0;
	Declare @Message varchar(1000);
 Begin Try
	Begin Tran;

	  Select 'Todo: Add INSERT-SELECT Code to DimEmployees sproc'

	  Set @Message = 'Filled DimEmployees (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	  Commit Tran;
	  Exec pETLInsMetadata
 	         @ETLAction = 'pETLDimEmployees'
 	        ,@ETLMetadata = @Message;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback;
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
    Exec pETLInsMetadata 
         @ETLAction = 'pETLDimEmployees'
        ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
-- Select * From DimEmployees

/****** [dbo].[DimProjects] ******/
Go
Create Or Alter View vETLDimProjects
As
	-- Select 'Todo: Add Select Code to View' as [c1]
	Select 
	  [ProjectID] = ID
	 ,[ProjectName] = Cast([Name] as varchar(100))
	From  EmployeeProjects.dbo.Projects;
Go

Create Or Alter Proc pETLDimProjects
--*************************************************************************--
-- Desc:This Sproc fills the DimProjects table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code to fills the DimProjects table. 
--*************************************************************************--
As 
Begin
  Declare @RC int = 0;
	Declare @Message varchar(1000);
  Begin Try
	  Select 'Todo: Complete DimProjects sproc (TRANSACTION)'	  
	  Select 'Todo: Complete DimProjects sproc (INSERT-SELECT)'
	  Select 'Todo: Complete DimProjects sproc (LOGGING)'    
    Set @RC = 1;
  End Try
  Begin Catch
	  Select 'Todo: Complete DimProjects sproc (TRANSACTION)'	
	  Select 'Todo: Complete DimProjects sproc (LOGGING)'     
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
-- Select * From DimProjects

/****** [dbo].[DimDates] ******/
Go
Create or Alter Proc pETLDimDates
As 
Begin
  Declare @RC int = 0;	
  Declare @Message varchar(1000)
  Set NoCount On; -- This will remove the 1 row affected msg in the While loop;
  Begin Try
 	  -- Create variables to hold the start and end date
	  Declare @StartDate datetime = '01/01/2020';
	  Declare @EndDate datetime = '12/31/2020'; 
	  Declare @DateInProcess datetime;
    Declare @TotalRows int = 0;

	  -- Use a while loop to add dates to the table
	  Set @DateInProcess = @StartDate;

	  While @DateInProcess <= @EndDate
	    Begin
	      -- Add a row into the date dimensiOn table for this date
	     Begin Tran;
	       Insert Into DimDates 
	       ( [DateKey], [FullDate], [USADateName], [MonthKey], [MonthName], [QuarterKey], [QuarterName], [YearKey], [YearName] )
	       Values ( 
	   	     Cast(Convert(nvarchar(50), @DateInProcess , 112) as int) -- [DateKey]
	        ,@DateInProcess -- [FullDate]
	        ,DateName( weekday, @DateInProcess ) + ', ' + Convert(nvarchar(50), @DateInProcess , 110) -- [USADateName]  
	        ,Left(Cast(Convert(nvarchar(50), @DateInProcess , 112) as int), 6) -- [MonthKey]   
	        ,DateName( MONTH, @DateInProcess ) + ', ' + Cast( Year(@DateInProcess ) as nVarchar(50) ) -- [MonthName]
	        , Cast(Cast(YEAR(@DateInProcess) as nvarchar(50))  + '0' + DateName( QUARTER,  @DateInProcess) as int) -- [QuarterKey]
	        ,'Q' + DateName( QUARTER, @DateInProcess ) + ', ' + Cast( Year(@DateInProcess) as nVarchar(50) ) -- [QuarterName] 
	        ,Year( @DateInProcess ) -- [YearKey]
	        ,Cast( Year(@DateInProcess ) as nVarchar(50) ) -- [YearName] 
	        ); 
	       -- Add a day and loop again
	       Set @DateInProcess = DateAdd(d, 1, @DateInProcess);
	     Commit Tran;
      Set @TotalRows += 1;
	  End -- While
   
	  -- 2e) Add additional lookup values to DimDates
	  Begin Tran;
	  Insert Into DimDates 
	    ( [DateKey]
	    , [FullDate]
	    , [USADateName]
	    , [MonthKey]
	    , [MonthName]
	    , [QuarterKey]
	    , [QuarterName]
	    , [YearKey]
	    , [YearName] )
	    Select 
	  	[DateKey] = -1
	    , [FullDate] = '19000101'
	    , [DateName] = Cast('Unknown Day' as nVarchar(50) )
	    , [MonthKey] = -1
	    , [MonthName] = Cast('Unknown Month' as nVarchar(50) )
	    , [QuarterKey] =  -1
	    , [QuarterName] = Cast('Unknown Quarter' as nVarchar(50) )
	    , [YearKey] = -1
	    , [YearName] = Cast('Unknown Year' as nVarchar(50) )
	    Union
	    Select 
	  	[DateKey] = -2
	    , [FullDate] = '19000102'
	    , [DateName] = Cast('Corrupt Day' as nVarchar(50) )
	    , [MonthKey] = -2
	    , [MonthName] = Cast('Corrupt Month' as nVarchar(50) )
	    , [QuarterKey] =  -2
	    , [QuarterName] = Cast('Corrupt Quarter' as nVarchar(50) )
	    , [YearKey] = -2
	    , [YearName] = Cast('Corrupt Year' as nVarchar(50) );
	   Commit Tran;
    Set @TotalRows += 2;
   
	  Set @Message = 'Filled DimDates (' + Cast(@TotalRows as varchar(100)) + ' rows)';
	  Exec pETLInsMetadata
	    @ETLAction = 'pETLDimDates'
	   ,@ETLMetadata = @Message;
    Set @RC = 1;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
	  Exec pETLInsMetadata 
	    @ETLAction = 'pETLDimDates'
	   ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

-- Select * From DimDates

/****** [dbo].[FactOrders] ******/
Go

go
Create Or Alter View vETLFactEmployeeProjectHours
As
	Select 'Todo: Complete the Select Code'	as [Todo],
	   [EmployeeProjectHoursID] = EmployeeProjectHoursID
	  ,EmployeeKey = 1 -- Todo: Fix this using a join
	  ,ProjectKey = 1 -- Todo Fix this using a join
	  ,DateKey =  dd.DateKey
	  ,HoursWorked = Hrs
	From EmployeeProjects.dbo.EmployeeProjectHours as eph
	 Join DimDates as dd
	  On Cast(Convert(nvarchar(50), eph.[Date], 112) as int) = dd.DateKey

Go
Create Or Alter Proc pETLFactEmployeeProjectHours
--*************************************************************************--
-- Desc:This Sproc fills the FactEmployeeProjectHours table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code to fills the FactEmployeeProjectHours table. 
--*************************************************************************--
As 
Begin
  Declare @RC int = 0;
  Declare @Message varchar(1000);
  Begin Try

	  Begin Tran;
	  Insert Into FactEmployeeProjectHours
	  (EmployeeProjectHoursID, EmployeeKey, ProjectKey, DateKey, HoursWorked)
	  Select 
	   EmployeeProjectHoursID,EmployeeKey,ProjectKey,DateKey,HoursWorked
	  From vETLFactEmployeeProjectHours;
   	Set @Message = 'Filled FactEmployeeProjectHours (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	  Commit Tran;
	  Exec pETLInsMetadata
 	       @ETLAction = 'pELTFactEmployeeProjectHours'
 	      ,@ETLMetadata = @Message;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback;
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
    Exec pETLInsMetadata 
         @ETLAction = 'pELTFactEmployeeProjectHours'
        ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

--********************************************************************--
-- 3) Re-Create the Foreign Key CONSTRAINTS
--********************************************************************--
Go
Create Or Alter Proc pETLReplaceFks
--*************************************************************************--
-- Desc:This Sproc replaces the DW foreign keys. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Added code to replace more FKs
--*************************************************************************--
As 
Begin
  Declare @RC int = 0;
  Begin Try
    Alter Table FactEmployeeProjectHours 
      Add Constraint FK_FactEmployeeProjectHours_DimDates
        Foreign Key(DateKey) References DimDates(DateKey);

 	 Select 'Todo: Add FK_FactEmployeeProjectHours_DimProjects'
	    
	 Select 'Todo: Add FK_FactEmployeeProjectHours_DimEmployees'

	 Exec pETLInsMetadata
	      @ETLAction = 'pETLReplaceFks'
	     ,@ETLMetadata = 'Replaced Foreign Keys';
   Set @RC = 1;   
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	  Exec pETLInsMetadata 
	         @ETLAction = 'pETLReplaceFks'
	        ,@ETLMetadata = @ErrorMessage;
   Set @RC = -1;
  End Catch
  Return @RC;
End
Go
--********************************************************************--
-- Review the results of this script
--********************************************************************--
Exec pETLDropFks;
Exec pETLTruncateTables;
Exec pETLDimEmployees;
Exec pETLDimProjects;
Exec pETLDimDates;
Exec pETLFactEmployeeProjectHours;
Exec pETLReplaceFks;
Select * From [ETLMetadata];
Go
-- Check table data
Select * From [dbo].[DimEmployees];
Select * From [dbo].[DimProjects];
Select * From [DimDates];
Select * From [FactEmployeeProjectHours];
Go