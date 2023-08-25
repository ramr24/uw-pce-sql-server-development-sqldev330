--*************************************************************************--
-- Title:  Encryption Demo
-- Author: RRoot
-- Desc: This file demonstrates how you can configure basic SQL Encryption
-- Change Log: When,Who,What
-- 2021-018-19,RRoot,Created File
--**************************************************************************--
USE [Master];
go
If Exists (SELECT name FROM sys.databases WHERE name = N'EncryptionDB')
  Begin
    -- Remove any database backups that were tracked in the MSDB database!
    EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'EncryptionDB'
    ALTER DATABASE [EncryptionDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [EncryptionDB];
  End
go
Create Database EncryptionDB;
go

Use EncryptionDB;
go

'*** Encrypting Column Data ***'
-----------------------------------------------------------------------------------------------------------------------
-- To Encrypt data you need a "Seed" 
-- SQL uses certificates as a "Seed" since they contain complex, yet recognizable values 
-- There are a number of built-in Certificates.
Select * From Master.sys.certificates
Go

-- However, you must create a custom one to start the encrytion process.
-- First you must create a Master Key in the database before you can create a Certificate
Create Certificate MyDBCert with subject = 'demo1' -- You will get an error!
Go
'Msg 15581, Level 16, State 1, Line 13
Please create a master key in the database or open the master key in the session before performing this operation.'

-- Let's create one now.
-- Use EncryptionDB;
Create Master Key ENCRYPTION By Password = 'P@ssw0rd'
Go
-- Note Keys are Context specific!
Select * from Master.sys.Symmetric_keys 
Select * from EncryptionDB.sys.Symmetric_keys 
-- So, be CAREFUL to create in the database you want to use
Go

-- Note Certs are Context specific too!
-- Use EncryptionDB
go
Create Certificate MyDBCert with subject = 'demo1' 
Go
Select * From Master.sys.certificates
Select * From EncryptionDB.sys.certificates

-- The Certificate is the Seed used to create an Encryption Key
Create SYMMETRIC Key DemoSKey 
	with Algorithm = AES_256
	Encryption By Certificate MyDBCert
Go
-- Now see if the Certificate was added. 
Select [key_guid], * from Master.sys.Symmetric_keys 
Select [key_guid], * from EncryptionDB.sys.Symmetric_keys 
Go
-- The Key's GUID is used for Decryption 
-- and can be accessed with this function
Select Key_Guid('DemoSKey') 
Go 

-- Create a table to test this on.
'NOTE: ONLY types nvarchar, char, varchar, binary, varbinary, or nchar can be encrypted with a key.'
Create -- Drop
Table DemoTable 
(	AccountId int, 
	AccountNumberAsString nVarchar(100), -- Must be Character data and must be Unicode
	AccountName varbinary(100) --  -- Binary data is OK to
);

-- Before using the Key you need to OPEN it using
-- the Certificate the Key was made with.
Open Symmetric Key DemoSKey Decryption by Certificate MyDBCert
Go
-- Now add the data to the table
Insert into DemoTable(AccountId, AccountNumberAsString, AccountName)
Values 
(	100,
	EncryptByKey(Key_Guid('DemoSKey'), '4455'),
	EncryptByKey(Key_Guid('DemoSKey'), 'Bob Smith')
)
Go

-- Now the data cannot be seen without decrypting it
Select * From DemoTable
Go

-- The DecryptByKey function return a varbinary data type! 
Select DecryptByKey(AccountNumberAsString) as c1 
From DemoTable

-- So, you must convert the data back to the original data type as follows:
-- HOWEVER, Don't use nVarchar! 
Select 
	AccountId , 
	Convert(nvarchar(100), DecryptByKey(AccountNumberAsString)) as [AcctNoStr], 
	Convert(nvarchar(100), DecryptByKey(AccountName)) as AccountName
From DemoTable

-- Use Varchar instead! (Though BOL say to use nvarchar!)
Select 
	AccountId , 
	Convert(varchar(100), DecryptByKey(AccountNumberAsString)) as [AcctNoStr], 
	Convert(varchar(100), DecryptByKey(AccountName)) as AccountName
From DemoTable

--TDE does real-time I/O encryption and decryption of data and log files. 
--The encryption uses a database encryption key (DEK). 
--The database boot record stores the key for availability during recovery. 
USE master;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Pa$$word';
go
Create Certificate MyServerCert WITH SUBJECT = 'My DB Encryption Certificate';
go
GO
Select * From Master.sys.certificates
Go
Use EncryptionDB;
go
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE MyServerCert;
GO
ALTER DATABASE EncryptionDB SET ENCRYPTION ON;
GO

Create -- Drop
Table DemoTable2 
(	AccountId int, 
	AccountNumberAsString int,
	AccountName nVarchar(100) 
);

Insert into DemoTable2
(AccountId, AccountNumberAsString, AccountName)
Values 
(100, 1234,'Sue Jones');
Go

-- The Encryption in invisable to the uses!
Select * From DemoTable2;

-- You cannot drop the key or you would not be able to access the data!
DROP DATABASE ENCRYPTION KEY

-- You can turn it off if you want and then drop the key 
ALTER DATABASE EncryptionDB SET ENCRYPTION OFF;
GO
DROP DATABASE ENCRYPTION KEY

----- Clean Up Code ---

Use Master
Drop Symmetric Key DemoSKey; 
Drop Certificate MyDBCert;
Drop Certificate MyServerCert 
go
Drop Database EncryptionDB
go
