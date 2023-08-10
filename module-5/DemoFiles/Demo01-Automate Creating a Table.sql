--*************************************************************************--
-- Title: Automate creating a Staging table
-- Author: RRoot
-- Desc: This file creates a Demo database and staging table.
-- Change Log: When,Who,What
-- 2018-02-07,RRoot,Created File
--**************************************************************************--

--[ Demo - Automate Creating a Table with SQL Agent ]--
Use tempdb;
go
If Exists(Select [Name] 
           From [Sys].[Tables] 
            Where [Name] = 'StudentsStaging')
   Drop Table StudentsStaging;
Go 
Create Table StudentsStaging
([StudentID] nvarchar(100) 
,[StudentFirstName] nvarchar(100)
,[StudentLastName] nvarchar(100) 
,[StudentEmail] nvarchar(100)
);
go
Select * From StudentsStaging;