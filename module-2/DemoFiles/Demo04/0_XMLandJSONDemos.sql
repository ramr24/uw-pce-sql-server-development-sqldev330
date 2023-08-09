--*************************************************************************--
-- Title: Module02 - XML and JSON Demos 
-- Desc:This file shows how to use XML and JSON with SQL Server. 
-- Change Log: When,Who,What
-- 2030-01-01,RRoot,Created File
--*************************************************************************--

-- Standard table results
SELECT [CategoryID]
      ,[CategoryName]
      ,[ProductID]
      ,[ProductName]
      ,[ProductPrice]
      ,[InventoryID]
      ,[InventoryProductID]
      ,[InventoryDate]
      ,[InventoryCount]
  FROM [MyDataWarehouseDB].[dbo].[AllData]

-- XML results
SELECT [CategoryID]
      ,[CategoryName]
      ,[ProductID]
      ,[ProductName]
      ,[ProductPrice]
      ,[InventoryID]
      ,[InventoryProductID]
      ,[InventoryDate]
      ,[InventoryCount]
  FROM [MyDataWarehouseDB].[dbo].[AllData]
  For XML raw, root('Inventories');

-- JSON results
SELECT [CategoryID]
      ,[CategoryName]
      ,[ProductID]
      ,[ProductName]
      ,[ProductPrice]
      ,[InventoryID]
      ,[InventoryProductID]
      ,[InventoryDate]
      ,[InventoryCount]
  FROM [MyDataWarehouseDB].[dbo].[AllData]
  For JSON path, root('Inventories');


'*** XML Overview ***'
-----------------------------------------------------------------------------------------------------------------------

--  Relational databases represent entities using tables, but XML does this using documents. 
--  An instance of an entity in a relational database is represented by a row in a table, 
--  while in XML an instance of an entity is represented by an element in a document. 

Customers 
CustID 	  Name 	  Phone 
=========================
1001 	    Smith 	  5551212 
1002 	    Jones	    5554567 

--  To represent this table in XML, we could create an XML document about 
--  Customers containing two Customer elements. The columns could be 
--  represented in an attribute-centric fashion—the columns in a table are 
--  mapped to attributes in an XML document, as shown in the following example: 

<Customers>
    <Customer CustID='1001' Name='Smith' Phone='5551212'/>
    <Customer CustID='1002' Name='Jones' Phone='5554567'/>
</Customers>

--  We could also use an element-centric mapping. In this mapping, all columns 
--  are returned as Child elements of the element representing the table they 
--  belong to, as shown in the following example: 

<Customers>
    <Customer> 
        <CustID>1001</CustID>
        <Name>Smith</Name>
        <Phone>5551212</Phone>
     </Customer>
    <Customer> 
        <CustID>1002</CustID>
        <Name>Jones</Name>
        <Phone>5554567</Phone>
    </Customer>
</Customers>

--  Lastly, you could also use a mixed approach as shown in this example: 

<Customers>
    <Customer CustID='1001'>Smith
        <Phone>5551212</Phone>
    </Customer>
    <Customer CustID='1002'>Jones
        <Phone>5554567</Phone>
    </Customer>
</Customers>


--  Relational databases, as their name suggests, are designed to enable 
--  you to represent relationships between entities. For example, an order 
--  entity can contain one or more item entities, as shown in the following tables:

Orders
================================
OrderNo 	  Date 	            Customer 
1235 	        01/01/2001 	    1001 
1236 	        01/01/2001 	    1002 

Items 
=============================================
ItemNo 	  OrderNo 	  ProductID 	  Price 	    Quantity 
1 	            1235 	        1432 	          12.99 	    2 
2 	            1235 	        1678 	          11.49 	    1 
3 	            1236 	        1432 	          12.99  	  3 

--  The most common approach to representing this data in XML is to use a 
--  nested XML document, as shown here: 

<Orders>
     <Order OrderNo='1235' Date='01/01/2001' Customer='1001'>
 	        <Item ProductID='1432' Price='12.99' Quantity='2'/>
          <Item ProductID='1678' Price='11.49' Quantity='1'/>
     </Order>
     <Order OrderNo='1236' Date='01/01/2001' Customer='1002'>
          <Item ProductID='1432' Price='12.99' Quantity='3'/>
     </Order>
</Orders>



'*** Storing XML data in Text Columns ***'
-----------------------------------------------------------------------------------------------------------------------
--  When you want to store XML in the database you have two choices:
--  1) Stored as Character data
--  2) Stored as XML data

Begin Try Use Master; Drop Database SQLandXML; End Try Begin Catch End Catch
go

CREATE DATABASE SQLandXML
Go
USE SQLandXML


--  Let's look at character data first.
Create Table XMLTextCustomerImportData
( CustomerId int, CustomerData nVarchar(Max))

-- Now you just add text as normal
Insert Into XMLTextCustomerImportData 
Values ( 
1001, 
'<?xml version="1.0" ?>
<Customer>
<CustID>1001</CustID>
     <Name>Smith</Name>
     <Phone>5551212</Phone>
</Customer>'
)

-- However, there is no validation performed on this text data!
Insert Into XMLTextCustomerImportData 
Values ( 
1002, 
'<?xml version="1.0" ?>
<CustomerZZZ>
<CustID>1002</CustID>
     <Name>Smith</Name>
     <Phone>5551212</Phone>
</Customer>'
)

-- Now, some of the data is corrupt. You will need to pull the data out of the table and correct
-- it, either by hand or by using programing code, such as TSQL, VB.NET, C#, or PERL.
SELECT * FROM XMLTextCustomerImportData


'*** Storing XML data in XML Columns ***'
-----------------------------------------------------------------------------------------------------------------------
-- Next, let's look at storing the data as XML.
Create Table XMLObjectCustomerImportData
( CustomerId int, CustomerData XML)

-- Now you just add text as normal
Insert Into XMLObjectCustomerImportData 
Values ( 
1001, 
'<?xml version="1.0" ?>
<Customer>
<CustID>1001</CustID>
     <Name>Smith</Name>
     <Phone>5551212</Phone>
</Customer>'
)

-- This time, there is some simple "Well Formed" checks are performed!
Insert Into XMLObjectCustomerImportData 
Values ( 
1002, 
'<?xml version="1.0" ?>
<CustomerZZZ>
<CustID>1002</CustID>
     <Name>Smith</Name>
     <Phone>5551212</Phone>
</Customer>'
)

-- However, other typical XML "Well Formed" checks not preformed!
Insert Into XMLObjectCustomerImportData 
Values ( 
1002, 
'<?xml version="1.0" ?> <![CDATA[ Many parsers require this line ]]>
<Customer>
<CustID>1002</CustID>
     <Name>Smith</Name>
     <Phone>5551212</Phone>
</Customer>
<Customer> <!-- NOTE: a single root node is not enforced -->
<CustID>1002</CustID>
     <Name>Smith</Name>
     <Phone>5551212</Phone>
</Customer>
'
)
--  You can use TSQL to work directly with the data. 
--  However, some of the MetaData, such as the XML prolog, IS LOST. 
SELECT * FROM XMLObjectCustomerImportData


'*** Working with XML data in variables ***'
-----------------------------------------------------------------------------------------------------------------------
-- You can also load the data into an variable and work with it.
-- As just shown, Text data types, such as Varchar or Char, preserves 
--  the Formating and MetaData, while XML removes any Formating and MetaData tags 

-- 1) Declare variables
Declare @XmlData varchar(MAX)
Declare @XmlObject XML

-- 2) Fill variables
SELECT @XmlData = CustomerData
    FROM XMLTextCustomerImportData
    WHERE CustomerId = 1001
-- Note: the Formating and MetaData will be removed by the XML data type!
SET @XmlObject = @XmlData 

-- 3) Display data 
-- Character data --
SELECT @XmlData as "Character Data Type"
PRINT @XmlData 
-- XML object data --
SELECT @XmlObject  as "XML Data Type"
PRINT Cast(@XmlObject as nVarchar(MAX))


'*** You can enforce data Validatation with XML Schemas ***'
-----------------------------------------------------------------------------------------------------------------------
--  You can add a XML Schema to the database with the following code:
CREATE XML SCHEMA COLLECTION CustomerInfoSchema
as
'<?xml version="1.0" encoding="utf-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
	<xs:element name="Customer">
		<xs:complexType>
			<xs:sequence>
				<xs:element name="CustID" type="xs:unsignedInt" />
				<xs:element name="Name" type="xs:string" />
				<xs:element name="Phone" type="xs:unsignedInt" />
			</xs:sequence>
		</xs:complexType>
	</xs:element>
</xs:schema>'


-- You can get info about the XML Schema collections in the database using these 
-- commands.
SELECT * FROM sys.xml_schema_collections
SELECT NAME, * FROM sys.xml_schema_namespaces

-- To use the Schema you start by creating a TYPED xml variable. 
-- Good XML :-)
DECLARE @XMLDoc xml (CustomerInfoSchema)
SET @XMLDoc  = 
'<?xml version="1.0" ?>
<Customer>
<CustID>1001</CustID>
     <Name>Smith</Name>
     <Phone>5551212</Phone>
</Customer>'
PRINT Cast(@XMLDoc as nVarchar(MAX))


-- BAD XML :-(
DECLARE @XMLDoc xml (CustomerInfoSchema)
SET @XMLDoc  = 
'<?xml version="1.0" ?>
<CustomerZZZ>
<CustID>1001</CustID>
     <Name>Smith</Name>
     <Phone>5551212</Phone>
</CustomerZZZ>'
PRINT Cast(@XMLDoc as nVarchar(MAX))
-- BAD XML :-(
DECLARE @XMLDoc xml (CustomerInfoSchema)
SET @XMLDoc  = 
'<?xml version="1.0" ?>
<Customer>
<CustID>1001</CustID>
     <Phone>5551212</Phone> 
     <Name>Smith</Name>
</Customer>'
PRINT Cast(@XMLDoc as nVarchar(MAX))

-- More importantly, this also can be use to protect your XML columns -- 
Drop Table XMLObjectCustomerImportData
Go
Create Table XMLObjectCustomerImportData
( CustomerId int, CustomerData XML (CustomerInfoSchema))

-- Now you just add text as normal
-- Good XML :-)
Insert Into XMLObjectCustomerImportData 
Values ( 
1001, 
'<?xml version="1.0" ?>
<Customer>
<CustID>1001</CustID>
     <Name>Smith</Name>
     <Phone>5551212</Phone>
</Customer>'
)
-- Bad XML :-(
Insert Into XMLObjectCustomerImportData 
Values ( 
1002, 
'<?xml version="1.0" ?>
<CustomerZZZ>
<CustID>1001</CustID>
     <Name>Smith</Name>
     <Phone>5551212</Phone>
</CustomerZZZ>'
)
-- Try Importing both CORRECT and INCORRECT data into the table 
-- using the following command!
INSERT INTO XMLObjectCustomerImportData (CustomerId, CustomerData)
SELECT 1002, * 
FROM OPENROWSET( BULK 'C:\CustomerData.xml', SINGLE_BLOB ) as CustData
Go
SELECT * FROM XMLObjectCustomerImportData


-- :-) Validatation makes for Happy DBAs  :-) ----

========================================================
'NOTE: '
-- A Database Schema which is used as a Namespace for database object!
-- A XML Schemas are used to Validate XML data!  

--  This :
    CREATE SCHEMA Sales AUTHORIZATION DBO

-- Not the same as:
  CREATE XML SCHEMA COLLECTION CustomerInfoSchema
========================================================


'*** Some functions in SQL Server return XML data ***'
-----------------------------------------------------------------------------------------------------------------------

-- Example: The EVENTDATA() Returns XML data
USE SQLandXML
Go
CREATE TABLE TrackDBObjects
(Id int Identity Primary Key, ChangeInfo XML)
Go

-- Create a Trigger that tracks new DB Objects --
IF Exists( Select * from sys.Triggers where name = 'trgCreateObjectsTracker')
    DROP TRIGGER trgCreateObjectsTracker On Database
Go

CREATE TRIGGER trgCreateObjectsTracker
ON DATABASE
FOR CREATE_FUNCTION, 
      CREATE_PROCEDURE,
      CREATE_TABLE,
      CREATE_VIEW
AS
DECLARE @E XML
SET @E = EVENTDATA() -- Returns XML data
INSERT INTO TrackDBObjects(ChangeInfo)
SELECT @E
Go

-- Now Test it by adding objects to the database
--  Drop Function fTest
--  Drop Procedure pTest
CREATE FUNCTION fTest() 
RETURNS Int
AS
  Begin
    Return 10
  End
Go

CREATE PROCEDURE pTest
AS
  PRINT 'Test'
Go

-- Now check the results --
SELECT * FROM sys.All_objects WHERE name Like '_Test'
SELECT * FROM TrackDBObjects


'*** Working with JSON data ***'
-----------------------------------------------------------------------------------------------------------------------

'*** Storing XML data in Text Columns ***'
-----------------------------------------------------------------------------------------------------------------------
--  When you want to store XML in the database you have two choices:
--  1) Stored as Character data
--  2) Stored as XML data

Begin Try Use Master; Drop Database SQLandJSON; End Try Begin Catch End Catch
go

CREATE DATABASE SQLandJSON
go
USE SQLandJSON
go

--  Let's look at character data first.
Create Table JSONTextCustomerImportData
( CustomerId int, CustomerData nVarchar(Max))

/* Note: Considering using NVARCHAR(4000) instead of NVARCHAR(max) for XML and JSON documents for performance.*/


-- Now you just add text as normal
Insert Into JSONTextCustomerImportData 
(CustomerId, CustomerData)
Values 
(1, '{ "Customer": {"CustID": "1001","Name": "Smith","Phone": "5551212"} }');
go
Select * From JSONTextCustomerImportData;
go

-- However, there is no validation performed on this text data!
Insert Into JSONTextCustomerImportData 
(CustomerId, CustomerData)
Values 
(2, '{ Customer : "CustID":1002,"Name":"BadData","Phone":5550000} ');
go
Select * From JSONTextCustomerImportData;
go

-- Now, some of the data is corrupt. You will need to pull the data out of the table and correct
-- it, either by hand or by using programing code, such as TSQL, VB.NET, C#, or PERL.
Select *, JSONTest = IsJSON(CustomerData)
 From JSONTextCustomerImportData;
go

-- On way to get around this is using a Check Constraint
Delete From JSONTextCustomerImportData Where CustomerID = 2;
go
Alter Table JSONTextCustomerImportData
Add Constraint ckOnlyJSON Check (IsJSON(CustomerData) = 1);
go

Insert Into JSONTextCustomerImportData 
(CustomerId, CustomerData)
Values 
 (3, '{ "Customer": {"CustID": "1003","Name": "Goodman","Phone": "5556789"} }')
go
Insert Into JSONTextCustomerImportData 
(CustomerId, CustomerData)
Values 
(2, '{ Customer : "CustID":1002,"Name":"BadData","Phone":5550000} ');
;
go
Select * From JSONTextCustomerImportData;
go

'*** SQL Server does not have a JSON Column  ***'
-----------------------------------------------------------------------------------------------------------------------

'*** SQL Server does not have a JSON SCHEMA ***'
-----------------------------------------------------------------------------------------------------------------------

'*** SQL Server does not have JSON variables ***'
-----------------------------------------------------------------------------------------------------------------------

Select CustomerData From JSONTextCustomerImportData;
Select 
 CustomerID
,[ExternalCustomerID] = JSON_VALUE(CustomerData, '$.Customer.CustID')
,[CustomerName] = JSON_VALUE(CustomerData, '$.Customer.Name')
From JSONTextCustomerImportData;

go

/*
It's A POWERFUL ADVANTAGE THAT YOU CAN USE ANY T-SQL FUNCTION AND QUERY CLAUSE TO QUERY JSON DOCUMENTS. SQL Server and 
SQL Database don't introduce any constraints in the queries that you can use to analyze JSON documents. 
You can extract values from a JSON document with the JSON_VALUE function and use it in the query like any other value.

This ability to use rich T-SQL query syntax is the KEY DIFFERENCE BETWEEN SQL SERVER AND SQL DATABASE AND CLASSIC NOSQL DATABASES 
- in Transact-SQL you probably have any function that you need to process JSON data.
-- https://docs.microsoft.com/en-us/sql/relational-databases/json/store-json-documents-in-sql-tables?view=sql-server-ver15
*/