--*************************************************************************--
-- Title: Module08 Source Database
-- Desc:This file will drop and create a database for module 08's assignment. 
-- Change Log: When,Who,What
-- 2030-01-01,RRoot,Created File
--*************************************************************************--


-- Create the database --
--*************************************************************************--
Use Master;
go
If Exists(Select name from master.dbo.sysdatabases Where Name = 'IndependentBookSellers')
Begin
	Use Master;
	Alter Database IndependentBookSellers Set Single_User With Rollback Immediate;
	Drop Database IndependentBookSellers;
End;
go

Create Database IndependentBookSellers; 
go

Use IndependentBookSellers;
go

-- Create the tables --
--*************************************************************************--
Set NoCount On; -- Stops the (xx row(s) affected) messages
go

Select title_id, title, type, price 
Into Titles
From Pubs.dbo.titles;
go

Select Distinct ord_num, ord_date, stor_id
Into SalesHeader
From Pubs.dbo.sales;
go

Select ord_num, t.title_id, qty, price 
Into SalesDetails
From Pubs.dbo.sales as s Join Pubs.dbo.titles as t
  On s.title_id = t.title_id;
go

-- Create the Constraints --
--*************************************************************************--
Alter Table SalesHeader
  Add Constraint pkSalesHeader Primary Key (ord_num);
go
Alter Table SalesDetails 
  Add Constraint pkSalesDetails Primary Key (ord_num, title_id);
go
Alter Table Titles 
  Add Constraint pkTitles Primary Key (title_id);
go

Alter Table SalesDetails 
  Add Constraint fkSalesDetailsToSales 
  Foreign Key (ord_num) References SalesHeader(ord_num);
go
Alter Table SalesDetails 
  Add Constraint fkSalesDetailsToTitles
  Foreign Key (title_id) References Titles(title_id);   
go

-- Review Design and Data --
--*************************************************************************--
Select  
  SourceObjectName = TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME + '.' + COLUMN_NAME
, DataType = DATA_TYPE + IIF(CHARACTER_MAXIMUM_LENGTH is Null, '' , '(' + Cast(CHARACTER_MAXIMUM_LENGTH as varchar(10)) + ')')
, Nullable = IS_NULLABLE
From INFORMATION_SCHEMA.COLUMNS
go

Select * From Titles;
Select * From SalesHeader;
Select * From SalesDetails;
go