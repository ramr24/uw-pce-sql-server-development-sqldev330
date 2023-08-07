--*************************************************************************--
-- Title: SQL Level 3 - Module 04  
-- Author: RRoot
-- Desc: This file demonstrates how to use Command based tools for ETL processing
-- Change Log: When,Who,What
-- 2021-01-26,RRoot,Created File
--**************************************************************************--
Use TempDB;
go

---------------------------------------------------

'*** Importing data to tables with SELECT INTO ***'
-----------------------------------------------------------------------------------------------------------------------
SELECT ProductName, UnitPrice AS Price, (UnitPrice * 0.1) AS Tax 
  INTO NEWPriceTable 
  FROM Northwind.dbo.Products; 
Go
SELECT * FROM NewPriceTable; 


-- You can also use SELECT INTO to create "TEMP" tables as shown here:
-- (Note that Temp Tables with a single # can only be used by one connection.)
-- Drop Table #PriceTable;
SELECT ProductName, UnitPrice AS Price, (UnitPrice * 0.1) AS Tax 
  INTO #PriceTable 
  FROM Northwind.dbo.Products; 
Go
SELECT * FROM #PriceTable; 


-- However, Temp Tables with a double ## can only be used by many connections.
-- Drop Table ##PriceTable;
SELECT ProductName, UnitPrice AS Price, (UnitPrice * 0.1) AS Tax 
  INTO ##PriceTable 
  FROM Northwind.dbo.Products; 
Go
SELECT * FROM ##PriceTable -- TEST THIS IN A DIFFERENT QUERY WINDOW!

-- Often, Standard tables are created for reports or exporting data
-- using the SELECT INTO option.
-- Drop Table OrdersReport;
SELECT DISTINCT CompanyName, Convert(Date, OrderDate) AS OrderDate
  INTO OrdersReport  -- New Demo table
  FROM Northwind.dbo.Orders INNER JOIN Northwind.dbo.Customers 
  ON Northwind.dbo.Orders.CustomerID = Northwind.dbo.Customers.CustomerID 

-- Notice that since we did not include a # sign since this was a regular table
SELECT Count(*) FROM OrdersReport
SELECT * FROM OrdersReport

-- SELECT INTO can be used to create an empty table as well
-- This is sometimes done to allow imports into a table
DROP TABLE OrdersReport
Go
SELECT DISTINCT CompanyName, OrderDate 
  INTO OrdersReport -- New Demo table
  FROM Northwind.dbo.Orders INNER JOIN Northwind.dbo.Customers 
  ON Northwind.dbo.Orders.CustomerID = Northwind.dbo.Customers.CustomerID 
  WHERE 5 = 4; -- NOTE: THIS WILL NEVER BE TRUE and so create an empty table!!!
Go
SELECT Count(*) FROM OrdersReport;
SELECT * FROM OrdersReport;
Go


'*** Importing data to tables with INSERT INTO ***'
-----------------------------------------------------------------------------------------------------------------------
-- INSERT INTO seems similar in some ways, 
-- but the table must already exsist before you can Insert data!
INSERT
  INTO OrdersReport  -- EXISTING Demo table
  SELECT DISTINCT CompanyName, OrderDate
  FROM Northwind.dbo.Orders INNER JOIN Northwind.dbo.Customers 
  ON Northwind.dbo.Orders.CustomerID = Northwind.dbo.Customers.CustomerID ;

-- See how there is now twice the data we had before?
SELECT Count(*) FROM OrdersReport;
SELECT * FROM OrdersReport;


'*** IMPORTING and EXPORTING with BCP  ***'
-----------------------------------------------------------------------------------------------------------------------
--  The BCP utility can both EXPORT and IMPORT data from data files and tables 
DROP TABLE TempDB.dbo.OrdersReport
Go
SELECT DISTINCT CompanyName, Convert(Date, OrderDate) AS OrderDate
  INTO TempDB.dbo.OrdersReport -- New Demo table
  FROM Northwind.dbo.Orders INNER JOIN Northwind.dbo.Customers 
  ON Northwind.dbo.Orders.CustomerID = Northwind.dbo.Customers.CustomerID 

'Note: Turn off SQL Cmd Mode under the Query Menu'
-- Let first make a folder for our work using the 
SQL CMD Mode feature http://msdn.microsoft.com/en-us/library/ms174187.aspx

!! DIR C:\_data
!! MD C:\_data

--  Exporting data from a table into a data file
!!BCP TempDB.dbo.OrdersReport OUT "C:\_data\ReportData.csv" -T -c -t "," -r "\n"

!!NOTEPAD.exe "C:\_data\ReportData.csv"
--  http://msdn.microsoft.com/en-us/library/ms162802.aspx

/* Here is syntax for the BCP command:  
    BCP {[[database_name.][owner].]{table_name | view_name} | "query"}
        {in | out | queryout | format} data_file
        [-m max_errors] [-f format_file] [-x] [-e err_file]
        [-F first_row] [-L last_row] [-b batch_size]
        [-n] [-c] [-w] [-N] [-V (60 | 65 | 70 | 80)] [-6] 
        [-q] [-C { ACP | OEM | RAW | code_page } ] [-tfield_term] 
        [-rrow_term] [-i input_file] [-o output_file] [-a packet_size]
        [-S server_name[\instance_name]] [-U login_id] [-P password]
        [-T] [-v] [-R] [-k] [-E] [-h "hint [,...n]"] "

-c Performs the operation using a character data type
-r Specifies the row terminator. The default is \n (newline character). 
-t Specifies the field terminator. The default is \t (tab character).
-T Specifies that the bcp utility connects to SQL Server with a trusted (Window's Securtity) connection.

*/

'Some Important options and facts about BCP'
--  1) You cannot export data out of a Single # table, but you can with ##'
--  2) Demo: 
		!! BCP ##pricetable out c:\_data\pricelist.txt -c -T  
		!! Explorer.exe C:\_data   

--You can Import data in a similar way, but a table must exist before 
--you can fill it with data. 
--SELECT INTO can be used to create an empty table using 
--a false where condition. Here is an example:

SELECT DISTINCT CompanyName, OrderDate 
  INTO TempDB.dbo.NewOrdersReport -- New data table
  FROM Northwind.dbo.Orders INNER JOIN Northwind.dbo.Customers 
  ON Northwind.dbo.Orders.CustomerID = Northwind.dbo.Customers.CustomerID 
  WHERE 5 = 4; -- NOTE: THIS WILL NEVER BE TRUE and so create an empty table!!!

-- If you check the table will be empty:
SELECT * FROM TempDB.dbo.NewOrdersReport;

-- To import data, you use almost the same command. 
!! BCP TempDB.dbo.NewOrdersReport IN "C:\_SQLDev\ReportData.csv" -T -c -t "," -r "\n"

-- You can now check again and see if the data imported correctly:
SELECT * FROM TempDB.dbo.NewOrdersReport;

'Note: Turn off SQL Cmd Mode'

'*** Bulk Insert ***'
-----------------------------------------------------------------------------------------------------------------------
use TempDB;
go

'Note: Copy and Paste the PatientData.csv file to the C:\_data folder'

-- Let's say we has some external data we want to examine. We can create a report
-- table to hold the data, make reports on it, then analyse the reports.

-- 1) Create a report table
If Exists(Select Name from Sys.Tables Where Name = 'PatientsReports') Drop Table PatientsReports;
go
Create Table PatientsReports	
(PatientID int Identity --Primary Key
,PatientFirstName nVarchar(100) Not Null
,PatientLastName nVarchar(100) Not Null
,PatientPhoneNumber	nVarchar(100) Not Null
,PatientAddress nVarchar(100) Not Null		
,PatientCity nVarchar(100) Not Null		
,PatientState nchar(2) Not Null		
,PatientZipCode nVarchar(10) Not Null
);
go
 
-- 2) Create a staging table to hold the imported data
If Exists(Select Name from Sys.Tables Where Name = 'PatientStagingData') Drop Table PatientStagingData;
go
Create Table PatientStagingData (
	[FirstName] Varchar(100),
	[LastName] Varchar(100),
	[Phone] Varchar(100),
	[Address] Varchar(100),
	[City] Varchar(100),
	[State] Varchar(100),
	[Zip] Varchar(100)   
);
go

-- 3) We then insert that data into to staging table
BULK INSERT PatientStagingData
 FROM 'C:\_data\PatientData.csv'
	WITH (DATAFILETYPE = 'char',  FIELDTERMINATOR = ',');  
-- Select * From PatientStagingData;

-- 4) Then we add data to the report table from the staging table
Insert Into PatientsReports
 (PatientFirstName, PatientLastName, PatientPhoneNumber, PatientAddress, PatientCity, PatientState, PatientZipCode)
 Select
 [FirstName], [LastName], [Phone], [Address], [City], Cast([State] as nVarchar(2)), Cast([Zip] as nvarchar(10))
 From PatientStagingData;

-- 5) Check to see the results
Select * From PatientsReports; 


'*** OPENROWSET ***'
-----------------------------------------------------------------------------------------------------------------------
use TempDB;
go

SELECT s.*
FROM OPENROWSET('SQLNCLI11'
,'Server=continuumsql.westus2.cloudapp.azure.com;uid=BICert;pwd=BICert;database=StudentEnrollments;' 
, 'SELECT * From Students'
) AS s;

/* EXPECT THIS ERROR!
Msg 15281, Level 16, State 1, Line 3
SQL Server blocked access to STATEMENT 'OpenRowset/OpenDatasource'
 of component 'Ad Hoc Distributed Queries.' 
 because this component is turned off as part of the security configuration for this server. 
A system administrator can enable the use of 'Ad Hoc Distributed Queries' by using sp_configure. 
*/

-- Run this on LOCAL Server
sp_configure; -- See the current settings
go
sp_configure 'show advanced option', '1'; -- Show advance settings
RECONFIGURE; -- Force the change
go
sp_configure -- Now see the advanced settings too
go
sp_configure 'Ad Hoc Distributed Queries', 1; -- Turn ON Ad Hoc queries
RECONFIGURE; -- Force the change
go

SELECT s.*
FROM OPENROWSET('SQLNCLI11'
,'Server=continuumsql.westus2.cloudapp.azure.com;uid=BICert;pwd=BICert;database=StudentEnrollments;' 
, 'SELECT * From Students'
) AS s;
go

sp_configure 'Ad Hoc Distributed Queries', 0; -- Turn OFF Ad Hoc queries
RECONFIGURE; -- Force the change 
go
sp_configure; -- See the current settings
go

sp_configure 'show advanced option', '0';
RECONFIGURE; -- Force the change 
go
sp_configure; -- See the current settings
go

