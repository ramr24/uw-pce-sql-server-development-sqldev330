--*************************************************************************--
-- Title: Final Source Database
-- Desc:This file will drop and create a database for the Final assignment. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
--*************************************************************************--

Print 'NOTE: The Microsoft Pubs database must be installed before running this script'

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

Select au_id, au_lname, au_fname, phone, address, city, state, zip 
Into Authors
From Pubs.dbo.authors;
go

Select title_id, title, type, price 
Into Titles
From Pubs.dbo.titles;
go

Select au_id, title_id, au_ord = cast(au_ord as int)
Into TitleAuthors
From Pubs.dbo.titleauthor;
go

Select stor_id, stor_name, stor_address, city, state, zip
Into Stores
From Pubs.dbo.stores;

go
Select Distinct ord_num, ord_date, stor_id  -- NOTE the dates!
Into SalesHeaders
From Pubs.dbo.sales;
go

Select ord_num, t.title_id, qty, price 
Into SalesDetails
From Pubs.dbo.sales as s Join Pubs.dbo.titles as t
  On s.title_id = t.title_id;
go

-- Create the Constraints --
--*************************************************************************--
Alter Table Stores
  Add Constraint pkStores Primary Key (stor_id);
go
Alter Table SalesHeaders
  Add Constraint pkSalesHeaders Primary Key (ord_num);
go
Alter Table SalesDetails 
  Add Constraint pkSalesDetails Primary Key (ord_num, title_id);
go
Alter Table Titles 
  Add Constraint pkTitles Primary Key (title_id);
go
Alter Table TitleAuthors 
  Add Constraint pkTitleAuthors Primary Key (au_id, title_id);
go
Alter Table Authors 
  Add Constraint pkAuthors Primary Key (au_id);
go
Alter Table SalesHeaders
  Add Constraint fkSalesHeadersToStores
  Foreign Key (stor_id) References Stores(stor_id);
go
Alter Table SalesDetails 
  Add Constraint fkSalesDetailsToSales 
  Foreign Key (ord_num) References SalesHeaders(ord_num);
go
Alter Table SalesDetails 
  Add Constraint fkSalesDetailsToTitles
  Foreign Key (title_id) References Titles(title_id);   
go
Alter Table TitleAuthors 
  Add Constraint fkTitleAuthorsToTitles
  Foreign Key (title_id) References Titles(title_id);   
go

Alter Table TitleAuthors 
  Add Constraint fkTitleAuthorsToAuthors
  Foreign Key (au_id) References Authors(au_id);   
go

-- Review Design and Data --
--*************************************************************************--
Select  
  SourceObjectName = TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME + '.' + COLUMN_NAME
, DataType = DATA_TYPE + IIF(CHARACTER_MAXIMUM_LENGTH is Null, '' , '(' + Cast(CHARACTER_MAXIMUM_LENGTH as varchar(10)) + ')')
, Nullable = IS_NULLABLE
From INFORMATION_SCHEMA.COLUMNS
go

Select * From Authors;
Select * From TitleAuthors;
Select * From Titles;
Select * From Stores;
Select * From SalesHeaders;
Select * From SalesDetails;
go