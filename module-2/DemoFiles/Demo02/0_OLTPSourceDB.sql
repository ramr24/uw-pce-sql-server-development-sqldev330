--*************************************************************************--
-- Title: Module02 OLTP Demo Database
-- Desc:This file will drop and create a database for module 02. 
-- Change Log: When,Who,What
-- 2030-01-01,RRoot,Created File
--*************************************************************************--
Use Master;
go
If Exists(Select Name From SysDatabases Where Name = 'OLTPSourceDB')
 Begin 
  Alter Database OLTPSourceDB set Single_user With Rollback Immediate;
  Drop Database OLTPSourceDB;
 End
Create Database OLTPSourceDB;
go

Use OLTPSourceDB;
go

Create Table Categories(
  "ID" integer Primary Key
 ,"Name" varchar(100)
);
go

Create Table Products(
  "ID" integer Primary Key
 ,"Name" varchar(100)
 ,"Price" money
);
go

Create Table CategoriesProducts(
  "CategoryID" integer references Categories("ID")
 ,"ProductID" integer references Products("ID")
 Primary Key("CategoryID","ProductID")
);
go

Create Table Inventories(
  "InventoryID" integer 
 ,"ProductID" integer references Products("ID")
 ,"Date" date
 ,"Count" int -- Measured Value
 Primary Key("InventoryID","ProductID")
);
go

Insert into Categories
("ID","Name")
Values
 (1,'Cat1')
,(2,'Cat2');
go

Insert into Products
("ID","Name","Price")
Values
 (1,'ProdA',9.99)
,(2,'ProdB',1.99)
,(3,'ProdC',1.99);
go

Insert into CategoriesProducts
("CategoryID","ProductID")
Values
 (1,1)
,(1,2)
,(1,3)
,(2,3);
go

Insert into Inventories
("InventoryID","ProductID","Date","Count")
Values
 (1,1,'20200101',33)
,(1,2,'20200101',20)
,(1,3,'20200101',18)
go

Select * 
From Categories as c
Join CategoriesProducts as cp
 on c.ID = cp.CategoryID
Join Products as p
 on cp.ProductID = p.ID
Join Inventories as i
 on p.ID = i.ProductID;
go
