--*************************************************************************--
-- Title: Heaps and Clusters
-- Author: RRoot
-- Desc: This file demonstrates the differencs between Heaps and Clusters.
-- Change Log: When,Who,What
-- 2021-08-17,RRoot,Created File
--**************************************************************************--

-- Create the database
Use Master;
go

If Exists(Select name from master.dbo.sysdatabases Where Name = 'Mod7DemoDB')
Begin
	Use [master];
	Alter Database [Mod7DemoDB] Set Single_User With Rollback Immediate;
	Drop Database [Mod7DemoDB];
End;
go

Create Database Mod7DemoDB; 
go

Use Mod7DemoDB;
go


'*** Heaps and Clusters ***'
-----------------------------------------------------------------------------------------------------------------------
-- Heaps --
-- By default, data is placed in pages in the first available space. 
-- This may start off as being sequential but the sequence is NOT maintained.
-- This type of orgainization is referered to as a HEAP.

-- When a table is first made the configuration of that table is a Heap. 
CREATE TABLE PhoneList
( Id int, Name varchar(50), Extension char(5))
Go
INSERT INTO PhoneList VALUES (1, 'Bob Smith', '11')
INSERT INTO PhoneList VALUES (2, 'Sue Jones', '12')
INSERT INTO PhoneList VALUES (3, 'Joe Harris', '13')
Go
SELECT * FROM Phonelist

-- While the table may appear to be sequentially organized, 
-- if you remove a row and then add one back you will see 
-- that SQL Server uses the first available slot in a page.
DELETE FROM PhoneList WHERE Id = 2
Go
INSERT INTO PhoneList VALUES (4, 'Tim Thomas', '14')
Go
SELECT * FROM Phonelist

-- This is not a big deal since you can have it display the results sequentially 
-- using an order by statements. However, this causes the server to sort 
-- the results before returing them.
'Note: Turn on the Execution Plan'
SELECT * FROM Phonelist
Go 
SELECT * FROM Phonelist  ORDER BY [Id]
Go
SELECT * FROM Phonelist  ORDER BY [Name]

'NOTE that the biggest percentage of work is due to sorting the data.'

-- Clustering --
-- SQL Server maintains the sequence on the page when
-- you add a Clustered Index to the table.
CREATE CLUSTERED INDEX ci_Id ON PhoneList(Id)
Go

-- Now the table will be physically sorted on that Indexed column. 
-- This will improve performance on some of your querys, but not all of them.
SELECT * FROM Phonelist
Go 
SELECT * FROM Phonelist  ORDER BY [Id]
Go
SELECT * FROM Phonelist  ORDER BY [Name]

-- If you believe that more users will search by Name then by Id,
--  you may want to place the Clustered index on the Name column instead.
-- However, the data pages can be sorted only one way at a time. 
-- So, you will have to drop the current Clustered Index before you can 
-- make a new one.
DROP INDEX PhoneList.ci_Id
Go
CREATE CLUSTERED INDEX ci_Name ON PhoneList(Name)
Go
-- See how the statements preform now. 
SELECT * FROM Phonelist
Go 
SELECT * FROM Phonelist  ORDER BY [Id]
Go
SELECT * FROM Phonelist  ORDER BY [Name]