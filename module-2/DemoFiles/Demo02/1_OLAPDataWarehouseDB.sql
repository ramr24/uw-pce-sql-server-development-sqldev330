--*************************************************************************--
-- Title: Module02 OLAP Demo Database
-- Desc:This file will drop and create a database for module 02. 
-- Change Log: When,Who,What
-- 2030-01-01,RRoot,Created File
--*************************************************************************--
Use Master;
go
If Exists(Select Name From SysDatabases Where Name = 'OLAPDataWarehouseDB')
 Begin 
  Alter Database OLAPDataWarehouseDB set Single_user With Rollback Immediate;
  Drop Database OLAPDataWarehouseDB;
 End
Create Database OLAPDataWarehouseDB;
go
Use OLAPDataWarehouseDB;
go

Create Table DimCategories(
  "CategoryID" integer Primary Key
 ,"CategoryName" varchar(100)
);
go

Create Table DimProducts(
  "ProductID" integer Primary Key
 ,"ProductName" varchar(100)
 ,"ProductPrice" money
);
go

Create Table FactCategoriesProducts(
  "CategoryID" integer references DimCategories("CategoryID")
 ,"ProductID" integer references DimProducts("ProductID")
 Primary Key("CategoryID","ProductID")
);
go

Create Table FactInventories(
  "InventoryID" integer 
 ,"InventoryProductID" integer references DimProducts("ProductID")
 ,"InventoryDate" date
 ,"InventoryCount" int -- Measured Value
 Primary Key("InventoryID","InventoryProductID")
);
go

Insert into DimCategories
("CategoryID","CategoryName")
Select "ID","Name" From [OLTPSourceDB].[dbo].[Categories];
go

Insert into DimProducts
("ProductID","ProductName","ProductPrice")
Select "ID","Name","Price" From [OLTPSourceDB].[dbo].[Products];

go

Insert into FactCategoriesProducts
("CategoryID","ProductID")
Select "CategoryID","ProductID" 
 From [OLTPSourceDB].[dbo].[CategoriesProducts]; 
go

Insert into FactInventories
("InventoryID","InventoryProductID","InventoryDate","InventoryCount")
Select "InventoryID","ProductID","Date","Count" 
 From [OLTPSourceDB].[dbo].[Inventories]
go

Create View AllData
AS
Select 
 c.[CategoryID]
,[CategoryName]
,p.[ProductID]
,[ProductName]
,[ProductPrice]
,[InventoryID]
,[InventoryProductID]
,[InventoryDate]
,[InventoryCount]
From DimCategories as c
Join FactCategoriesProducts as cp
 on c.CategoryID = cp.CategoryID
Join DimProducts as p
 on cp.ProductID = p.ProductID
Join FactInventories as i
 on p.ProductID = i.InventoryProductID;
go

Select * From AllData;


Select CategoryName, Sum(InventoryCount) 
From AllData
Group By CategoryName;
