--**************** SQL Level 2 (SQL and XML) **************--
-- This file covers the basics of
--  using XML with SQL Server 
--**********************************************************--

CREATE DATABASE SQLandXML
Go
USE SQLandXML


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


'*** Some functions in SQL Server return XML data ***'
-----------------------------------------------------------------------------------------------------------------------
' Example: The EVENTDATA() Returns XML data'
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


'*** Importing XML data using OPENROWSET with Bulk option ***'
-----------------------------------------------------------------------------------------------------------------------
-- Try Importing both CORRECT and INCORRECT data into the table 
-- using the following command!
================================================================
'NOTE: To Run This Demo...
    1) Open Notepad and paste in the following XML
  
        <?xml version="1.0" encoding="utf-8"?>
        <Customer>
	        <CustID>1001</CustID>
	        <Name>Smith</Name>
	        <Phone>5551212</Phone>
        </Customer>

    2) Save this file on C:\ as CustomerData.xml
    3) Run the import demos below
    4) Modify the XML so that is no longer well formed and import code again'
================================================================

Create Table CharData
( CustomerId int IDENTITY, 
  CustomerData VarChar(max)) -- Characters
Go
INSERT INTO CharData (CustomerData)
  SELECT * FROM OPENROWSET( BULK 'C:\CustomerData.xml', SINGLE_CLOB ) as MyData
Go
SELECT * FROM CharData

Create Table UnicodeCharData
( CustomerId int IDENTITY, 
  CustomerData nVarChar(max)) -- Unicode Characters need the Unicode data
Go
'Note: This demo should fail (If required; you can use SSIS to export data to Unicode)'
INSERT INTO UnicodeCharData (CustomerData)  -- If the file is not Unicode the import fails
  SELECT * FROM OPENROWSET( BULK 'C:\CustomerData.xml', SINGLE_nCLOB ) as MyData
Go
SELECT * FROM UnicodeCharData


Create Table BinaryData
( CustomerId int IDENTITY, 
  CustomerData VarBinary(max)) -- Objects, Character, and Unicode Characters
Go
INSERT INTO BinaryData (CustomerData)
  SELECT * FROM OPENROWSET( BULK 'C:\CustomerData.xml', SINGLE_BLOB ) as MyData
Go
SELECT * FROM BinaryData


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

'******************** LAB ***********************'
-- Do the following:

-- 1) Practice 1 on Page 264
-- 1) Practice 2 on Page 266

-- DO NOT type all the XML out, just use to files
-- that come with the book.
'*************************************************'


'*** Using FOR XML with RAW option ***'
-----------------------------------------------------------------------------------------------------------------------

--  RAW mode queries return XML, including 
--  queries containing a join. For example, to generate an invoice containing 
--  order data such as the order date as well as the list of items ordered, the 
--  query would need to retrieve data from both the Orders and Order Details tables, 
--  as shown in the following example:
Use Northwind
SELECT Orders.OrderID, OrderDate, ProductID, UnitPrice, Quantity
FROM Orders JOIN [Order Details]
ON Orders.OrderID = [Order Details].OrderID
WHERE Orders.OrderID = 10248
FOR XML RAW


--  Column aliases can be used to change the names of the attributes returned or 
--  to provide a name for a calculated column. The following example 
--  shows how to use an alias to specify the names of the attributes returned: 
Use Northwind
SELECT OrderID  InvoiceNo, SUM(Quantity) as [Total_Items]
FROM [Order Details]
GROUP BY OrderID
FOR XML RAW

-- With the RAW option you can rename the word 'ROW' as follows:
Use Northwind
SELECT OrderID as [ID], SUM(Quantity)  as [Total_Items]
FROM [Order Details]
GROUP BY OrderID
FOR XML RAW ('InvoiceNo')    '<-- NEW in 2005 -- '

-- Unlike the previous version, you can now use RAW for both Elements 
-- and Attribute formats
Use Northwind
SELECT OrderID  as InvoiceNo, SUM(Quantity) as [Total_Items]
FROM [Order Details]
GROUP BY OrderID
FOR XML RAW ('InvoiceNo') , ELEMENTS    '<-- NEW in 2005 -- '

-- Unlike the previous version, you can now use RAW for both Elements 
-- and Attribute formats
Use Northwind
SELECT OrderID  as InvoiceNo, SUM(Quantity) as [Total_Items]
FROM [Order Details]
GROUP BY OrderID
FOR XML RAW ('InvoiceNo') , ELEMENTS, ROOT('OrderDetails')    '<-- NEW in 2005 -- '

-- RAW can also be used to create simple XML documents as follows:
SELECT 
      1001 as [CustID],
      'Smith' as [Name],
      '555-1212' as [CellPhone],
      '555-1212' as [HomePhone]
FOR XML RAW ('InvoiceNo'), ROOT('CustomerData')
Go
SELECT 
      1001 as [CustID],
      'Smith' as [Name],
      '555-1212' as [CellPhone],
      '555-1212' as [HomePhone]    
FOR XML RAW ('InvoiceNo'), ELEMENTS, ROOT('CustomerData')


'*** Using FOR XML with AUTO option  ***'
-----------------------------------------------------------------------------------------------------------------------
--  AUTO mode gives you a little more control over the XML returned. 
--  By default, each row in the result set is represented as an XML element 
--  named after the table it was selected from. For example, data could be retrieved 
--  from the Orders table using an AUTO mode query, as shown in this example: 

SELECT OrderID, CustomerID
FROM Orders
WHERE OrderID = 10248
FOR XML AUTO

--  In cases in which table names contain spaces, the resulting XML element names 
--  contain encoding characters. 
  <Order_x0020_Details OrderID="10248" ProductID="11" UnitPrice="14" Quantity="12"/>
--  For example, we could retrieve our invoice data 
--  from the Order Details table using the following AUTO mode query: 

SELECT OrderID, ProductID, UnitPrice, Quantity
FROM [Order Details]
WHERE OrderID = 10248
FOR XML AUTO

--  In AUTO mode queries, however, you can also rename the elements using table aliases, 
--  as shown in the following example: 

SELECT OrderID as "InvoiceNo", 
       ProductID, 
       UnitPrice Price, 
       Quantity
FROM [Order Details] AS "Item"
WHERE OrderID = 10248
FOR XML AUTO


--  Queries with joins in AUTO mode behave differently from RAW mode queries
--  containing joins. Each table in the join results in a nested XML element. 
--  For example, a query to generate an invoice from the Orders and Order Details 
--  tables could be written as an AUTO mode query, as shown here: 

SELECT Invoice.OrderID as "InvoiceNo", 
       OrderDate, 
       ProductID, 
       UnitPrice Price, 
       Quantity
FROM Orders as "Invoice" JOIN [Order Details] as "Item"
ON Invoice.OrderID = Item.OrderID
WHERE Invoice.OrderID = 10248
FOR XML RAW   '<--  Raw option '

SELECT Invoice.OrderID as InvoiceNo, 
       OrderDate, 
       ProductID, 
       UnitPrice Price, 
       Quantity
FROM Orders as "Invoice" JOIN [Order Details] as "Item"
ON Invoice.OrderID = Item.OrderID
WHERE Invoice.OrderID = 10248
FOR XML AUTO   '<--  Auto option '


'*** Working with Nulls  ***'
-----------------------------------------------------------------------------------------------------------------------
-- This next code shows two way you can handle NULL values in the data
SELECT 
      1001 as [CustID],
      'Smith' as [Name],
      Null as [CellPhone],
      '555-1212' as [HomePhone]  
FOR XML RAW ('InvoiceNo'), ELEMENTS, ROOT('CustomerData')
-- Note: Only works with RAW, since AUTO must query a Table! --

-- OR --

SELECT 
      1001 as [CustID],
      'Smith' as [Name],
      Null as [CellPhone],
      '555-1212' as [HomePhone]  
FOR XML RAW ('InvoiceNo'), ELEMENTS XSINIL, ROOT('CustomerData')

