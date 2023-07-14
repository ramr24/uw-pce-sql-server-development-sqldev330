--*************************************************************************--
-- Title: Module08 DW Destination Database
-- Desc:This file will drop and create a DW database for module 08's assignment. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- 2020-05-29,RRoot,Completed File
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

Create Table DimTitles
([TitleKey] int Identity Constraint pkDimTitles Primary Key
,[TitleID] nvarchar(6) Not Null
,[TitleName] nvarchar(100) Not Null
,[TitleType] nchar(12) Not Null
,[TitleListPrice] money Null
);
go

-- Create Fact Tables --
--*************************************************************************--
Create Table FactSales
([OrderNumber] varchar(20) Not Null
,[OrderDate] date Not Null
,[TitleKey] int Not Null
,[SalesQty] smallint Not Null
,[SalesPrice] money Not Null
Constraint pkFactSales Primary Key ([OrderNumber],[OrderDate],[TitleKey])
);
go

-- Add Constraints --
--*************************************************************************--

Alter Table FactSales
  Add Constraint fkSalesToDimTitles
  Foreign Key (TitleKey) References DimTitles(TitleKey);
go


-- Review Design and Data --
--*************************************************************************--
Select  
  SourceObjectName = TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME + '.' + COLUMN_NAME
, DataType = DATA_TYPE + IIF(CHARACTER_MAXIMUM_LENGTH is Null, '' , '(' + Cast(CHARACTER_MAXIMUM_LENGTH as varchar(10)) + ')')
, Nullable = IS_NULLABLE
From INFORMATION_SCHEMA.COLUMNS
go
