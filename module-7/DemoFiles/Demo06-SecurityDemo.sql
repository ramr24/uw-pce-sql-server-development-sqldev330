--*************************************************************************--
-- Title: Security Demo
-- Author: RRoot
-- Desc: This file demonstrates how you can configure basic SQL Security
-- Change Log: When,Who,What
-- 2021-018-19,RRoot,Created File
--**************************************************************************--
USE [Master];
go
If Exists (SELECT name FROM sys.databases WHERE name = N'SecDB')
  Begin
    -- Remove any database backups that were tracked in the MSDB database!
    EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'SecDB'
    ALTER DATABASE [SecDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [SecDB];
  End
go
Create Database SecDB
go

USE [Master];
-- This adds a SQL Login
-- sp_DropLogin 'WebUser'
sp_AddLogin 'WebUser', 'Pa$$w0rd'
-- Same as:
-- Drop LOGIN [Webuser] 
CREATE LOGIN [Webuser] WITH PASSWORD = 'Pa$$word';  
go

USE [SecDB]
go
-- This adds a new database user linked to the login
-- sp_DropUser 'WebUser'
sp_addUser 'WebUser', 'WebUser' -- Note: The names do not have to match
-- Same as:
-- Drop USER [WebUser]
CREATE USER [WebUser] FOR LOGIN [Webuser]
go

-- These built in functions give you information about the logins and users
'NOTE: Open a new connection using the WebUser Login and Run this code'
Use Master;
Select 
 [My DB User Name] = USER 
,[My Login Name] =  Suser_Sname()
,[Name of DB I am connected to] =  DB_Name();
Go
Use SecDB;
Select 
 [My DB User Name] = USER 
,[My Login Name] =  Suser_Sname()
,[Name of DB I am connected to] =  DB_Name();
Go

Create Table Students
(StudentId int Primary Key, StudentName nvarchar(50) )

-- To a Group (Role)
Grant Select On Students To Public
Revoke Select On Students To Public
Deny Select On Students To Public

-- Or to a indivdual
Grant Select On Students To WebUser
Revoke Select On Students To WebUser

-- Open a connect as SQL User and test the combonation of perms

-- Create a custom role for all the users dev user accounts
CREATE ROLE [DevAppUsers] 
GO

-- Add the users to the role
EXEC sp_AddRoleMember N'DevAppUsers', N'WebUser'
Go

-- No block access DIRECTLY to the role
Deny Select On Students To DevAppUsers

-- Now create a view to allow access
Create View vStudents
AS
	Select StudentId, StudentName 
	From Students
Go

Create Proc pInsStudents
(@StudentId int, @StudentName nvarchar(50))
AS
	Insert Into Students(StudentId, StudentName)
	Values (@StudentId, @StudentName)
Go
-- now they can use the view but not the table directly
Grant Select On vStudents To DevAppUsers	
Grant Execute On pInsStudents To DevAppUsers	

-- If you need to change the table design it will 
-- normally break the appliacitons, but not if 
-- the view makes it look the same as it was

Create -- Drop
Table Students
( StudentId int Primary Key
, StudentFirstName nvarchar(50) 
, StudentLastName nvarchar(50) 
)
Deny Select On Students To DevAppUsers

-- Now change the view to make the table 
-- look as it did

Alter View vStudents
AS
	Select 
	  StudentId
	, StudentName = StudentFirstName + ' ' + StudentLastName
	From Students
Go

Alter
 Proc pInsStudents
(@StudentId int, @StudentFirstName nvarchar(50), @StudentLastName nvarchar(50))
AS
	Insert Into Students(StudentId, StudentFirstName, StudentLastName)
	Values (@StudentId, @StudentFirstName , @StudentLastName)
Go

Exec pInsStudents 
	  @StudentId = 1
	, @StudentFirstName = 'Bob'
	, @StudentLastName = 'Smith' 


