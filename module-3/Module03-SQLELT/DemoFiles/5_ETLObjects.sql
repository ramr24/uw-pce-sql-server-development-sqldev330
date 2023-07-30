--*************************************************************************--
-- Title: Module03 DW ETL Process
-- Desc:This file will drop and create an ETL process for module 03's demo. 
-- Change Log: When,Who,What
-- 2020-02-01,RRoot,Created File
-- 2020-05-29,Completed File
--*************************************************************************--

Use DWIndependentBookSellers;
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

-- Select * FRom vETLMetadata;

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
    Begin Tran;
      Insert Into ETLMetadata
       (ETLAction,ETLMetadata)
      Values
       (@ETLAction,@ETLMetadata);
	  Commit Tran;
    Set @RC = 1; 
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback Tran;
    Print Error_Message(); -- NOTE THIS IS PRESENTATION CODE!
    Set @RC = -1;
  End Catch
  Return @RC;
End
go

-- TEST THE SPROC --
-- Call the stored procedure
DECLARE @Status int;
DECLARE @NewID int;
EXEC @Status = pETLInsMetadata
                 @ETLAction = 'Test Inserrt'
                ,@ETLMetadata = 'This is a Test';          
               
-- Present the results
SELECT @Status as [Return Code Value]
SELECT CASE @Status
  WHEN +1 THEN 'Insert was successful!'
  WHEN -1 THEN 'Insert failed!'
  END AS [Status];
SELECT * FROM ETLMetadata;
Go

--********************************************************************--
-- 1) Drop the Foreign Key CONSTRAINTS and Clear the tables
--********************************************************************--
go
Create Or Alter Proc pETLDropFks
--*************************************************************************--
-- Desc:This Sproc drops the DW foreign keys. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As 
Begin
  Declare @RC int = 0;
  Begin Try
    Alter Table FactTitleAuthors Drop Constraint fkSalesToDimAuthors;
    Alter Table FactTitleAuthors Drop Constraint fkSalesToTitles;
    Alter Table FactSales Drop Constraint fkSalesToDimDates;
    Alter Table FactSales Drop Constraint fkSalesToDimTitles;
    Alter Table FactSales Drop Constraint fkSalesToDimStores;
  
    Exec pETLInsMetadata
         @ETLAction = 'pETLDropFks'
        ,@ETLMetadata = 'Dropped Foreign Keys';

    Set @RC = 1;
   End Try
   Begin Catch
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
     Exec pETLInsMetadata 
          @ETLAction = 'pETLDropFks'
         ,@ETLMetadata = @ErrorMessage;
     Set @RC = -1;
   End Catch
   Return @RC;
End
go

Create Or Alter Proc pETLTruncateTables
--*************************************************************************--
-- Desc:This Sproc clears the data from all DW tables. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As 
Begin
  Declare @RC int = 1;
  Begin Try
	  Truncate Table FactTitleAuthors;
	  Truncate Table FactSales;		
	  Truncate Table DimDates;
	  Truncate Table DimAuthors;
	  Truncate Table DimTitles;
	  Truncate Table DimStores;
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

/****** [dbo].[DimDates] ******/
Go
Create or Alter Proc pETLDimDates
As 
Begin    
  Set NoCount On; -- This will remove the 1 row affected msg in the While loop;
  Declare @RC int = 0;
	Declare @Message varchar(1000) 
  Begin Try
 	  -- Create variables to hold the start and end date
	  Declare @StartDate datetime = '01/01/1990';
	  Declare @EndDate datetime = '12/31/1995'; 
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
  Set NoCount Off;
  Return @RC;
End
Go

-- Select Top(10) * From DimDates; Select * From vETLMetadata

/****** [dbo].[DimStores] ******/
Go
Create Or Alter View vETLDimStores
As
	Select 
	  [StoreId] = Cast( stor_id as nChar(4) )
	, [StoreName] = Cast( stor_name as nVarchar(50) )
	, [StoreCity] = Cast( city as nVarchar(50) )
	, [StoreState] = Cast( state as nVarchar(50) )
	From IndependentBookSellers.dbo.stores;
Go

Create Or Alter Proc pETLDimStores
--*************************************************************************--
-- Desc:This Sproc fills the DimStores table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As 
Begin
 Declare @RC int = 0;
 Declare @Message varchar(1000);
 Begin Try
   Begin Tran;
 	   Insert Into DimStores
	   (StoreID, StoreName, StoreCity, StoreState)
	   Select 
	     [StoreId]
	    ,[StoreName]
	    ,[StoreCity]
	    ,[StoreState]
	    From vETLDimStores;
	  Set @Message = 'Filled DimStores (' + Cast(@@RowCount as varchar(100)) + ' rows)';
    Commit Tran;
	  Exec pETLInsMetadata
	        @ETLAction = 'pETLDimStores'
	       ,@ETLMetadata = @Message;
    Set @RC = 1;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
	  Exec pETLInsMetadata 
	         @ETLAction = 'pETLDimStores'
	        ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
-- Select * From DimStores; Select * From vETLMetadata


/****** [dbo].[DimAuthors] ******/
Go
Create Or Alter View vETLDimAuthors
As
	Select 
	  [AuthorId] = Cast(au_id as nChar(11))
	, [AuthorName] = Cast((au_fname + ' ' + au_lname) as nVarchar(100))
	, [AuthorCity] = Cast(city as nVarchar(100))
	, [AuthorState] = Cast(state as nChar(2))
	From IndependentBookSellers.dbo.authors;
Go

Create Or Alter Proc pETLDimAuthors
--*************************************************************************--
-- Desc:This Sproc fills the DimAuthors table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As 
Begin
  Declare @RC int = 0;
  Declare @Message varchar(1000);
  Begin Try
    Begin Tran;
  	 Insert Into DimAuthors
 	   (AuthorID, AuthorName, AuthorCity, AuthorState)
 	   Select 
 	    AuthorID, AuthorName, AuthorCity, AuthorState
 	     From vETLDimAuthors;
    Set @Message = 'Filled DimAuthors (' + Cast(@@RowCount as varchar(100)) + ' rows)';
    Commit Tran; 
   Exec pETLInsMetadata
 	    @ETLAction = 'pETLDimAuthors'
 	   ,@ETLMetadata = @Message;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@Trancount > 0 Rollback Tran;
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
 	  Exec pETLInsMetadata 
 	    @ETLAction = 'pETLDimAuthors'
 	   ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
-- Select * From DimAuthors; Select * From vETLMetadata


/****** [dbo].[DimTitles] ******/
Go
Create Or Alter View vETLDimTitles
As
	Select 
	 [TitleID] = Cast(title_id as nvarchar(6))
	,[TitleName] = Cast(title as varchar(100))
	,[TitleType]=Case Cast(IsNull([type],'Unknown') as nvarchar(50) )
	 When 'business' Then 'Business'
	 When 'mod_cook' Then 'Modern Cooking'
	 When 'popular_comp' Then 'Popular Computing'
	 When 'psychology' Then 'Psychology'
	 When 'trad_cook' Then 'Traditional Cooking'
	 When 'UNDECIDED' Then 'Undecided'
	 End
	,[TitleListPrice] = price -- Should this be left as null?
	From IndependentBookSellers.dbo.Titles;
Go

Create Or Alter Proc pETLDimTitles
--*************************************************************************--
-- Desc:This Sproc fills the DimTitles table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As 
Begin
  Declare @RC int = 0;
 	Declare @Message varchar(1000);
  Begin Try
    Begin Tran;
  	  Insert Into DimTitles
 	    (TitleID, TitleName, TitleType, TitleListPrice)
 		Select 
 	     TitleID, TitleName, TitleType, TitleListPrice
 	    From vETLDimTitles; 
 	    Set @Message = 'Filled DimTitles (' + Cast(@@RowCount as varchar(100)) + ' rows)';
    Commit Tran;
 	    Exec pETLInsMetadata
 	         @ETLAction = 'pETLDimTitles'
 	        ,@ETLMetadata = @Message;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback Tran;
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
    Exec pETLInsMetadata 
         @ETLAction = 'pETLDimTitles'
        ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
-- Select * From DimTitles; Select * From vETLMetadata


/****** [dbo].[FactTitleAuthors] ******/
Go
Create Or Alter View vETLFactTitleAuthors
As
	Select  
	  [TitleKey] = DT.TitleKey
	, [title_id] -- Use this to check your work
	, [AuthorKey] = DA.AuthorKey 
	, [au_id] -- Use this to check your work
	, [AuthorOrder] = au_ord
	From IndependentBookSellers.dbo.TitleAuthors as TA
	JOIN DWIndependentBookSellers.dbo.DimTitles as DT
	  On TA.title_id = DT.TitleId
	JOIN DWIndependentBookSellers.dbo.DimAuthors as DA
	  On TA.Au_id = DA.AuthorId;
Go

Create Or Alter Proc pETLFactTitleAuthors
--*************************************************************************--
-- Desc:This Sproc fills the FactTitleAuthors table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As 
Begin 
  Declare @RC int = 0;
	Declare @Message varchar(1000);
  Begin Try
 	  Insert Into [dbo].[FactTitleAuthors]
	  (AuthorKey, TitleKey, AuthorOrder)
	  Select 
     AuthorKey, TitleKey, AuthorOrder
	  From vETLFactTitleAuthors;
	  Set @Message = 'Filled FactTitleAuthors (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	  Exec pETLInsMetadata
	    @ETLAction = 'pETLFactTitleAuthors'
	   ,@ETLMetadata = @Message;
  Set @RC = 1;
 End Try
 Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	  Exec pETLInsMetadata 
	    @ETLAction = 'pETLFactTitleAuthors'
	   ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
-- Select * From FactTitleAuthors; Select * From vETLMetadata


/****** [dbo].[FactSales] ******/
Go
Create Or Alter View vETLFactSales
As
	Select 
      OrderNumber = S.ord_num
	 ,OrderDateKey = DD.DateKey
	 ,OrderDate = S.ord_date
	 ,StoreKey = DS.StoreKey
	 ,StoreID = S.stor_id -- Use this to check your work
	 ,TitleKey = DT.TitleKey
	 ,TitleID = SD.title_id -- Use this to check your work
	 ,SalesQty = SD.qty
	 ,SalesPrice = SD.price
	From [IndependentBookSellers].dbo.SalesHeader as S
	Join [IndependentBookSellers].dbo.SalesDetails as SD
	  On S.ord_num = SD.ord_num
	Join DimDates as DD
	  On S.ord_date = DD.FullDate
	Join [DWIndependentBookSellers].dbo.DimTitles as DT
	  On SD.Title_id = DT.TitleId
	Join [DWIndependentBookSellers].dbo.DimStores as DS
	  On S.Stor_id = DS.StoreId;
Go

Create Or Alter Proc pETLFactSales
--*************************************************************************--
-- Desc:This Sproc fills the FactSales table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As 
Begin
  Declare @RC int = 0;
	Declare @Message varchar(1000);
  Begin Try
  	Insert Into [dbo].[FactSales]
 	  (OrderNumber, OrderDateKey, StoreKey, TitleKey, SalesQty, SalesPrice)
 	  Select 
     OrderNumber, OrderDateKey, StoreKey, TitleKey, SalesQty, SalesPrice
 	  From vETLFactSales;
 	
    Set @Message = 'Filled FactSales (' + Cast(@@RowCount as varchar(100)) + ' rows)';
 	  Exec pETLInsMetadata
 	    @ETLAction = 'pETLFactSales'
 	   ,@ETLMetadata = @Message;
  Set @RC = 1;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
 	  Exec pETLInsMetadata 
 	    @ETLAction = 'pETLFactSales'
 	   ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
-- Select * From FactSales; Select * From vETLMetadata



--*************************************************************************--
-- 3) Re-Create the Foreign Key CONSTRAINTS
--*************************************************************************--
Go
Create Or Alter Proc pETLReplaceFks
As 
Begin 
  Declare @RC int = 0;
  Begin Try
 	  Alter Table FactTitleAuthors
 	    Add Constraint fkSalesToDimAuthors
 	    Foreign Key (AuthorKey) References DimAuthors(AuthorKey);
 
 	  Alter Table FactTitleAuthors
 	    Add Constraint fkSalesToTitles
 	    Foreign Key (TitleKey) References DimTitles(TitleKey);
 
 	  Alter Table FactSales
 	    Add Constraint fkSalesToDimDates
 	    Foreign Key (OrderDateKey) References DimDates(DateKey);
 
 	  Alter Table FactSales
 	    Add Constraint fkSalesToDimTitles
 	    Foreign Key (TitleKey) References DimTitles(TitleKey);
 
 	  Alter Table FactSales
 	    Add Constraint fkSalesToDimStores
 	    Foreign Key (StoreKey) References DimStores(StoreKey);
 	  Exec pETLInsMetadata
 	    @ETLAction = 'pETLReplaceFks'
 	   ,@ETLMetadata = 'Replaced Foreign Keys';
    Set @RC = 1;  
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
 	  Exec pETLInsMetadata 
 	    @ETLAction = 'pETLReplaceFks'
 	   ,@ETLMetadata = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
--*************************************************************************--
-- 4. Review the results of this script
--*************************************************************************--
Exec pETLDropFks;
Exec pETLTruncateTables;
Exec pETLDimDates;
Exec pETLDimStores;
Exec pETLDimAuthors;
Exec pETLDimTitles;
Exec pETLFactTitleAuthors;
Exec pETLFactSales;
Exec pETLReplaceFks;
Select * From [vETLMetadata];
go

Select * From [DimDates];
Select * From [DimAuthors];
Select * From [DimStores];
Select * From [DimTitles];
Select * From [FactTitleAuthors];
Select * From [FactSales];
go