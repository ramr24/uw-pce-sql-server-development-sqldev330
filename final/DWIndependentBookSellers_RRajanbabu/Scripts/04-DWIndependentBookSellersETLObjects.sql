--*************************************************************************--
-- Title: Final DW ETL Process Objects
-- Desc:This file will drop and create an ETL process Objects for Final assignment. 
-- Change Log: When,Who,What
-- 2020-02-01,RRoot,Created File
-- Todo: 08/24/23, Ramkumar Rajanbabu, Completed pETLDropFks, pETLTruncateTables
--*************************************************************************--

Use DWIndependentBookSellers;
go

--********************************************************************--
-- 0) Create ETL metadata objects
--********************************************************************--
If NOT Exists(Select * From Sys.tables where Name = 'ETLLog')
  Create -- Drop
  Table ETLLog
  (ETLLogID int identity Primary Key
  ,ETLDateAndTime datetime Default GetDate()
  ,ETLAction varchar(100)
  ,ETLLogMessage varchar(2000)
  );
go

Create or Alter View vETLLog
As
 Select
  ETLLogID
 ,ETLDate = Format(ETLDateAndTime, 'D', 'en-us')
 ,ETLTime = Format(Cast(ETLDateAndTime as datetime2), 'HH:mm', 'en-us')
 ,ETLAction
 ,ETLLogMessage
 From ETLLog;
go


Create or Alter Proc pInsETLLog
 (@ETLAction varchar(100), @ETLLogMessage varchar(2000))
--*************************************************************************--
-- Desc:This Sproc creates an admin table for logging ETL metadata. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As
Begin
  Declare @RC int = 0;
  Begin Try
    Begin Tran;
    Insert Into ETLLog
     (ETLAction,ETLLogMessage)
    Values
     (@ETLAction,@ETLLogMessage)
    Commit Tran;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback Tran;
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
-- Todo: 08/24/23, Ramkumar Rajanbabu, Completed pETLDropFks
--*************************************************************************--
As 
Begin
	DECLARE @RC INT = 0;
	BEGIN TRY
		-- DROP CONSTRAINT
		ALTER TABLE FactTitleAuthors
			DROP CONSTRAINT fkFactTitleAuthorsToDimAuthors

		ALTER TABLE FactTitleAuthors
			DROP CONSTRAINT fkFactTitleAuthorsToDimTitles

		ALTER TABLE FactSales
			DROP CONSTRAINT fkFactSalesToDimDates

		ALTER TABLE FactSales
			DROP CONSTRAINT fkFactSalesToDimTitles

		ALTER TABLE FactSales
			DROP CONSTRAINT fkFactSalesToDimStores
	
		EXEC pInsETLLog
			@ETLAction = 'pETLDropFks',
			@ETLLogMessage = 'Dropped Foreign Keys';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsETLLog
				@ETLAction = 'pETLDropFks',
				@ETLLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go

Go
Create Or Alter Proc pETLTruncateTables
--*************************************************************************--
-- Desc:This Sproc clears the data from all DW tables. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 08/24/23, Ramkumar Rajanbabu, Completed pETLTruncateTables
--*************************************************************************--
As 
Begin
	DECLARE @RC INT = 0;
	BEGIN TRY
		-- TRUNCATE TABLE
		TRUNCATE TABLE FactSales;

		TRUNCATE TABLE FactTitleAuthors;

		TRUNCATE TABLE DimStores;

		TRUNCATE TABLE DimTitles;

		TRUNCATE TABLE DimAuthors;

		TRUNCATE TABLE DimDates;

		EXEC pInsETLLog
			@ETLAction = 'pETLTruncateTables',
			@ETLLogMessage = 'Truncated Tables';
		SET @RC = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(1000) = Error_Message()
			EXEC pInsETLLog
				@ETLAction = 'pETLTruncateTables',
				@ETLLogMessage = @ErrorMessage;
		SET @RC = -1;
	END CATCH
	RETURN @RC;
End
Go

--********************************************************************--
-- 2) FILL the Tables
--********************************************************************--

/****** [dbo].[DimDates] ******/
Go
Create or Alter Proc pETLDimDates
As 
Begin
  Declare @RC int = 1;
  Declare @Message varchar(1000) 
  Set NoCount On; -- This will remove the 1 row affected msg in the While loop;
  Begin Try
 	  -- Create variables to hold the start and end date
	  Declare @StartDate datetime = '01/01/1992';
	  Declare @EndDate datetime = '12/31/1994'; 
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
	  Exec pInsETLLog
	        @ETLAction = 'pETLDimDates'
	       ,@ETLLogMessage = @Message;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback Tran;
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
	  Exec pInsETLLog
	        @ETLAction = 'pETLDimDates'
	       ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Set NoCount Off;
  Return @RC;
End
Go
-- Select * From DimDates

/****** [dbo].[DimAuthors] ******/
Go
Create Or Alter View vETLDimAuthors
As
	Select 'ADD CODE HERE' as 'TODO'
	SELECT
		[AuthorID],
		[AuthorName],
		[AuthorCity],
		[AuthorState]
	FROM IndependentBookSellers.dbo.Authors;
Go

Create Or Alter Proc pETLDimAuthors
--*************************************************************************--
-- Desc:This Sproc fills the DimAuthors table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code 
--*************************************************************************--
As 
Begin 
	Select 'ADD CODE HERE' as 'TODO'
End
Go
-- Select * From DimAuthors

/****** [dbo].[DimTitles] ******/
Go
Create Or Alter View vETLDimTitles
As
	Select 'ADD CODE HERE' as 'TODO'
	SELECT
		[TitleID],
		[TitleName],
		[TitleType],
		[TitleListPrice]
	FROM IndependentBookSellers.dbo.Titles;
Go

Create Or Alter Proc pETLDimTitles
--*************************************************************************--
-- Desc:This Sproc fills the DimTitles table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code 
--*************************************************************************--
As 
Begin
	Select 'ADD CODE HERE' as 'TODO'
End
Go
-- Select * From DimTitles

/****** [dbo].[DimStores] ******/
Go
Create Or Alter View vETLDimStores
As
	Select 'ADD CODE HERE' as 'TODO'
	SELECT
		[StoreID],
		[StoreName],
		[StoreCity],
		[StoreState]
	FROM IndependentBookSellers.dbo.Stores;
Go

Create Or Alter Proc pETLDimStores
--*************************************************************************--
-- Desc:This Sproc fills the DimStores table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code 
--*************************************************************************--
As 
Begin
	Select 'ADD CODE HERE' as 'TODO' 
End
Go
-- Select * From DimStores



/****** [dbo].[FactTitleAuthors] ******/
Go
Create Or Alter View vETLFactTitleAuthors
As
	Select 'ADD CODE HERE' as 'TODO'

Go

Create Or Alter Proc pETLFactTitleAuthors
--*************************************************************************--
-- Desc:This Sproc fills the FactTitleAuthors table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code 
--*************************************************************************--
As 
Begin
	Select 'ADD CODE HERE' as 'TODO' 
End
Go
-- Select * From FactTitleAuthors;


/****** [dbo].[FactSales] ******/

Go
Create Or Alter View vETLFactSales
As
	Select 'ADD CODE HERE' as 'TODO'
Go

Create Or Alter Proc pETLFactSales
--*************************************************************************--
-- Desc:This Sproc fills the FactSales table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code 
--*************************************************************************--
As 
Begin 
	Select 'ADD CODE HERE' as 'TODO'
End
Go
-- Select * From FactSales;


--********************************************************************--
-- 3) Re-Create the Foreign Key CONSTRAINTS
--********************************************************************--
Go
Create Or Alter Proc pETLReplaceFks
--*************************************************************************--
-- Desc:This Sproc replaces the DW foreign keys. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Added code to replace FKs
--*************************************************************************--
As 
Begin
	Select 'ADD CODE HERE' as 'TODO'
End
Go
--********************************************************************--
-- Review the results of this script
--********************************************************************--
Exec pETLDropFks;
Exec pETLTruncateTables;
Exec pETLDimDates;
Exec pETLDimAuthors;
Exec pETLDimTitles;
Exec pETLDimStores;
Exec pETLFactTitleAuthors;
Exec pETLFactSales;
Exec pETLReplaceFks;
go

Select * From [ETLLog];
go
-- Check table data
Select * From [DimAuthors];
Select * From [DimTitles];
Select * From [DimStores];
Select * From [FactTitleAuthors];
Select * From [FactSales];
Select * From [DimDates];
Go