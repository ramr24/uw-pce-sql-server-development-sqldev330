--*************************************************************************--
-- Title: Final DW Destination Database
-- Desc:This file will drop and create a DW database for module Final assignment. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
--*************************************************************************--

-- Create Database --
--*************************************************************************--
Use Master;
go
If Exists(Select name from master.dbo.sysdatabases Where Name = 'DWIndependentBookSellers')
Begin
	Use Master;
	Alter Database DWIndependentBookSellers Set Single_User With Rollback Immediate;
	Drop Database DWIndependentBookSellers;
End;
go

Create Database DWIndependentBookSellers; 
go

Use DWIndependentBookSellers;
go

-- Create Dimension Tables --
--*************************************************************************--
Create Table DimDates
([DateKey] int Constraint pkDimDates Primary Key
,[FullDate] date Not Null
,[USADateName] nvarchar(100) Not Null
,[MonthKey] int Not Null
,[MonthName] nvarchar(100) Not Null
,[QuarterKey] int Not Null
,[QuarterName] nvarchar(100) Not Null
,[YearKey] int Not Null
,[YearName] nvarchar(100) Not Null
); -- Note: this table will be filled in the ETL script
go

Create Table DimAuthors
([AuthorKey] int Identity Constraint pkDimAuthors Primary Key
,[AuthorID] nvarchar(11) Not Null
,[AuthorName] nvarchar(100) Not Null	
,[AuthorCity] nvarchar(100) Not Null	
,[AuthorState] nchar(2) Not Null	
);
go

Create Table DimTitles
([TitleKey] int Identity Constraint pkDimTitles Primary Key
,[TitleID] nvarchar(6) Not Null
,[TitleName] nvarchar(100) Not Null
,[TitleType] nvarchar(100) Not Null
,[TitleListPrice] decimal(18,4) Not Null -- Note: Filter out titles without a price in DW.
);
go

Create Table DimStores
([StoreKey] int Identity Constraint pkDimStores Primary Key
,[StoreID] nchar(4) Not Null
,[StoreName] nvarchar(100) Not Null
,[StoreCity] nvarchar(100) Not Null
,[StoreState] nchar(2) Not Null
);
go

-- Create Fact Tables --
--*************************************************************************--
Create Table FactTitleAuthors
([AuthorKey] int Not Null
,[TitleKey] int Not Null
,[AuthorOrder] int Not Null
Constraint pkFactTitleAuthors Primary Key ([AuthorKey],[TitleKey],[AuthorOrder])
);
go

Create Table FactSales
([OrderNumber] nvarchar(20) Not Null
,[OrderDateKey] int Not Null
,[StoreKey] int Not Null
,[TitleKey] int Not Null
,[SalesQty] int Not Null
,[SalesPrice] decimal(18,4) Not Null
Constraint pkFactSales Primary Key ([OrderNumber],[OrderDateKey],[StoreKey],[TitleKey])
);
go

-- Add Constraints --
--*************************************************************************--
Alter Table FactTitleAuthors
  Add Constraint fkFactTitleAuthorsToDimAuthors
  Foreign Key (AuthorKey) References DimAuthors(AuthorKey);
go

Alter Table FactTitleAuthors
  Add Constraint fkFactTitleAuthorsToDimTitles
  Foreign Key (TitleKey) References DimTitles(TitleKey);
go

Alter Table FactSales
  Add Constraint fkFactSalesToDimDates
  Foreign Key (OrderDateKey) References DimDates(DateKey);
go

Alter Table FactSales
  Add Constraint fkFactSalesToDimTitles
  Foreign Key (TitleKey) References DimTitles(TitleKey);
go

Alter Table FactSales
  Add Constraint fkFactSalesToDimStores
  Foreign Key (StoreKey) References DimStores(StoreKey);
go

-- Review Design and Data --
--*************************************************************************--
Select  
  SourceObjectName = TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME + '.' + COLUMN_NAME
, DataType = DATA_TYPE + IIF(CHARACTER_MAXIMUM_LENGTH is Null, '' , '(' + Cast(CHARACTER_MAXIMUM_LENGTH as varchar(10)) + ')')
, Nullable = IS_NULLABLE
From INFORMATION_SCHEMA.COLUMNS
go
