--*************************************************************************--
-- Title: Module08 DW ETL Process
-- Desc:This file will drop and create an ETL process for module 08's assignment. 
-- Change Log: When,Who,What
-- 2020-02-01,RRoot,Created File
-- 2020-05-29,Completed File
--*************************************************************************--

Use DWIndependentBookSellers;
go

--********************************************************************--
-- 0) Create ETL metadata objects
--********************************************************************--
If Exists(Select * From Sys.tables where Name = 'ETLMetadata')
  Drop Table ETLMetadata;
go

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
As
 Insert Into ETLMetadata
 (ETLAction,ETLMetadata)
 Values
 (@ETLAction,@ETLMetadata)
go


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
 Begin Try

	Alter Table FactSales
	  Drop Constraint fkSalesToDimTitles;

	Exec pETLInsMetadata
	  @ETLAction = 'pETLDropFks'
	 ,@ETLMetadata = 'Dropped Foreign Keys';
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	Exec pETLInsMetadata 
	  @ETLAction = 'pETLDropFks'
	 ,@ETLMetadata = @ErrorMessage;
  End Catch
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
 Begin Try
	Truncate Table FactSales;		
	Truncate Table DimTitles;
	Exec pETLInsMetadata
	  @ETLAction = 'pETLTruncateTables'
	 ,@ETLMetadata = 'Truncated Tables';
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	Exec pETLInsMetadata 
	  @ETLAction = 'pETLTruncateTables'
	 ,@ETLMetadata = @ErrorMessage;
  End Catch
End



--********************************************************************--
-- 2) FILL the Tables
--********************************************************************--

/****** [dbo].[DimTitles] ******/
Go
Create Or Alter View vETLDimTitles
As
	Select 
		[TitleId] = Cast( isNull( [title_id], -1 ) as nvarchar(6) )
	  , [TitleName] = Cast( isNull( [title], 'Unknown' ) as nvarchar(100) )
	  , [TitleType] = Cast( isNull( [type], 'Unknown' ) as nvarchar(50) )
	  , [TitleListPrice] = price
	From [IndependentBookSellers].[dbo].[Titles];
Go

Create Or Alter Proc pETLDimTitles
--*************************************************************************--
-- Desc:This Sproc fills the DimTitles table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As 
Begin 
 Begin Try
 	Insert Into DimTitles
	(TitleID, TitleName, TitleType, TitleListPrice)
	Select 
	 TitleID, TitleName, TitleType, TitleListPrice
	From vETLDimTitles;

	Declare @Message varchar(1000) 
	Set @Message = 'Filled DimTitles (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	Exec pETLInsMetadata
	  @ETLAction = 'pETLDimTitles'
	 ,@ETLMetadata = @Message;

 End Try
 Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	Exec pETLInsMetadata 
	  @ETLAction = 'pETLDimTitles'
	 ,@ETLMetadata = @ErrorMessage;
 End Catch
End
Go


/****** [dbo].[FactSales] ******/
Go
Create Or Alter View vETLFactSales
As
	Select 
      OrderNumber = S.ord_num
	 ,OrderDate = S.ord_date
	 ,TitleKey = DT.TitleKey
	 ,TitleID = SD.title_id -- Use this to check your work
	 ,SalesQty = SD.qty
	 ,SalesPrice = SD.price
	From [IndependentBookSellers].dbo.SalesHeader as S
	Join [IndependentBookSellers].dbo.SalesDetails as SD
	  On S.ord_num = SD.ord_num
	Join [DWIndependentBookSellers].dbo.DimTitles as DT
	  On SD.Title_id = DT.TitleId

Go

Create Or Alter Proc pETLFactSales
--*************************************************************************--
-- Desc:This Sproc fills the FactSales table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As 
Begin 
 Begin Try
 	Insert Into [dbo].[FactSales]
	(OrderNumber, OrderDate, TitleKey, SalesQty, SalesPrice)
	Select 
     OrderNumber, OrderDate, TitleKey, SalesQty, SalesPrice
	From vETLFactSales;
		
	Declare @Message varchar(1000) 
	Set @Message = 'Filled FactSales (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	Exec pETLInsMetadata
	  @ETLAction = 'pETLFactSales'
	 ,@ETLMetadata = @Message;
 End Try
 Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	Exec pETLInsMetadata 
	  @ETLAction = 'pETLFactSales'
	 ,@ETLMetadata = @ErrorMessage;
 End Catch
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
 Begin Try

	Alter Table FactSales
	  Add Constraint fkSalesToDimTitles
	  Foreign Key (TitleKey) References DimTitles(TitleKey);

	Exec pETLInsMetadata
	  @ETLAction = 'pETLReplaceFks'
	 ,@ETLMetadata = 'Replaced Foreign Keys';
 End Try
 Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	Exec pETLInsMetadata 
	  @ETLAction = 'pETLReplaceFks'
	 ,@ETLMetadata = @ErrorMessage;
 End Catch
End
go

--*************************************************************************--
-- 4. Review the results of this script
--*************************************************************************--
Exec pETLDropFks;
Exec pETLTruncateTables;
Exec pETLDimTitles;
Exec pETLFactSales;
Exec pETLReplaceFks;
go

Select * From [DimTitles];
Select * From [FactSales];
Select * From [vETLMetadata];
go