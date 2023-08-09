--*************************************************************************--
-- Title: Module02 Products Demo Database
-- Desc:This file will drop and create a database for module 02
-- , then extract XML and JSON data
-- Change Log: When,Who,What
-- 2030-01-01,RRoot,Created File
--*************************************************************************--
Begin Try Drop Database MyDataDB End Try Begin Catch End Catch;
go
Create Database MyDataDB;
go
use MyDataDB;
go
Create Table Products(
  "Name" varchar(100)
 ,"Price" Money
 ,"Category" varchar(100) 
);
go
Insert into Products
("Name","Price","Category")
Values
 ('ProdA',9.99,'Cat1')
,('ProdB',1.99,'Cat1')
,('ProdC',1.99,'Cat1,Cat2');

Select Name, Price, Category From Products 
