--*************************************************************************--
-- Title: Module02 DW Destination Database
-- Desc:This file will drop and create a DW database for module 02's assignment. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- 08/09/23, Ramkumar Rajanbabu, Executed File
--*************************************************************************--

-- Create Database --
--*************************************************************************--
Use Master;
go
If Exists(Select name from master.dbo.sysdatabases Where Name = 'DWPubsLite')
Begin
	Use Master;
	Alter Database DWPubsLite Set Single_User With Rollback Immediate;
	Drop Database DWPubsLite;
End;
go

Create Database DWPubsLite; 
go

Use DWPubsLite;
go

-- Create Dimension Tables --
--*************************************************************************--
Select 
 [AuthorID] = au_id
,[AuthorName] = au_fname + ' ' + au_lname	
,[AuthorState] = state
Into DimAuthors
From pubs..authors;
go

Select
 [TitleID] = title_id
,[TitleName] = title
,[TitleType] = type
,[TitleListPrice] = price
Into DimTitles
From pubs..titles;
go


-- Create Fact Tables --
--*************************************************************************--
Select 
 [TitleID] = title_id
,[AuthorID] = au_id
Into FactTitleAuthors
From pubs..titleauthor; 
go

Select
 OrderNumber = ord_num
,OrderDate = ord_date
,TitleID = title_id
,OrderQty = qty
Into FactSales
From pubs..sales; 
go

-- Add Constraints --
--*************************************************************************--
Alter Table DimAuthors Add Constraint pkDimAuthors Primary Key (AuthorID);
Alter Table DimTitles Add Constraint pkDimTitles Primary Key (TitleID);
Alter Table FactTitleAuthors Add Constraint pkFactTitleAuthors Primary Key (TitleID, AuthorID);
Alter Table FactSales Add Constraint pkFactSales Primary Key (OrderNumber, OrderDate, TitleID);

Alter Table FactTitleAuthors 
  Add Constraint fkFactTitleAuthorsToDimAuthors 
  Foreign Key (AuthorID) References DimAuthors(AuthorID)
go
Alter Table FactTitleAuthors 
  Add Constraint fkFactTitleAuthorsToDimTitles
  Foreign Key (TitleID) References DimTitles(TitleID)
go

Alter Table FactSales 
  Add Constraint fkFactSalesToDimTitles
  Foreign Key (TitleID) References DimTitles(TitleID)
go

-- Review Design and Data --
--*************************************************************************--
Select  
  SourceObjectName = TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME + '.' + COLUMN_NAME
, DataType = DATA_TYPE + IIF(CHARACTER_MAXIMUM_LENGTH is Null, '' , '(' + Cast(CHARACTER_MAXIMUM_LENGTH as varchar(10)) + ')')
, Nullable = IS_NULLABLE
From INFORMATION_SCHEMA.COLUMNS
go

Select * 
From FactSales as fs
Join DimTitles as dt On dt.TitleID = fs.TitleID
Join FactTitleAuthors as fta On fta.TitleID = dt.TitleID
Join DimAuthors as da On da.AuthorID = fta.AuthorID;