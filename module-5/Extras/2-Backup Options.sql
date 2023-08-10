--*************************************************************************--
-- Title: Module 07 - Backup Options
-- Author: RRoot
-- Desc: This file demonstrates how you can perform database backups with verious options.
-- Change Log: When,Who,What
-- 2018-02-19,RRoot,Created File
--**************************************************************************--

-- [Setup Code] -- 
---------------------------------------------------------------------------------------------------------
/* Create the following folder for this demo
!! MD C:\Backup Files
USE [Master];
*/
go
If Exists (SELECT name FROM sys.databases WHERE name = N'BackupDemoDB')
  Begin
    -- Remove any database backups that were tracked in the MSDB database!
    EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'BackupDemoDB'
    ALTER DATABASE [BackupDemoDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [BackupDemoDB];
  End
go
CREATE DATABASE [BackupDemoDB] ON PRIMARY -- File Group
 ( NAME = N'BackupDemoDB' -- logical name
 , FILENAME = N'C:\BackupFiles\BackupDemoDB.mdf' ) -- physical name
 LOG ON 
 ( NAME = N'BackupDemoDB_log' -- logical name
 , FILENAME = N'C:\BackupFiles\BackupDemoDB.ldf' ); -- physical name
go

-- Let's create some starting data
USE [BackupDemoDB]
go
Create Table ProductList
 (ProductId int, ProductName nvarchar(100));
go
Insert into ProductList Values(1, 'ProdA');
Select * from ProductList; -- Check the data is there!
---------------------------------------------------------------------------------------------------------


-- [Mixed Backup Files] -- 
---------------------------------------------------------------------------------------------------------
-- One backup file can hold a mix of backup files (ex. both Full and Log )
Backup Database BackupDemoDB To Disk ='C:\BackupFiles\BackupDemoDB.bak' With Init;
Backup Log BackupDemoDB To Disk ='C:\BackupFiles\BackupDemoDB.bak';
Restore HeaderOnly From DISK = N'C:\BackupFiles\BackupDemoDB.bak';
go 
---------------------------------------------------------------------------------------------------------


-- [Backup Devices] -- 
---------------------------------------------------------------------------------------------------------
/*
"A logical device is a user-defined name that points to a specific physical backup device 
(a disk file or tape drive). The initialization of the physical device occurs later, 
when a backup is written to the backup device." 
https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/define-a-logical-backup-device-for-a-disk-file-sql-server
*/

-- If you know you are going to use a give file for you backups you can create 
-- a backup device to simplify things.
Use [Master]
go
if Exists (Select * From model.sys.sysdevices Where Name = N'BackupDemoDBDevice')
 EXEC master.dbo.sp_dropdevice @logicalname = N'BackupDemoDBDevice'
go
Exec master.dbo.sp_AdDumpDevice  -- Adds a "Dump" Device
  @devtype = N'disk'
, @logicalname = N'BackupDemoDBDevice'
, @physicalname = N'C:\BackupFiles\BackupDemoDB.bak'
go

-- Now when you back up the database you can use the device name instead of the acutal file path
Backup Database BackupDemoDB To BackupDemoDBDevice With Init;
Backup Log BackupDemoDB To BackupDemoDBDevice;
Restore HeaderOnly From BackupDemoDBDevice; 
go
---------------------------------------------------------------------------------------------------------


-- [Setting the Database Recovery Model] -- 
---------------------------------------------------------------------------------------------------------
-- A Database's Recovery Model determine what types of backup can be performed
/* "A recovery model is a database property that controls how transactions are logged, 
  whether the transaction log requires (and allows) backing up
  , and what kinds of restore operations are available. 

  Three recovery models exist: simple, full, and bulk-logged. 
  Typically, a database uses the full recovery model or simple recovery model.
  A database can be switched to another recovery model at any time. 
  The model database sets the default recovery model of new databases."
  https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/view-or-change-the-recovery-model-of-a-database-sql-server
*/

-- There are Three options
Alter Database [BackupDemoDB] Set Recovery Full WITH NO_WAIT;
Alter Database [BackupDemoDB] Set Recovery Bulk_logged WITH NO_WAIT;	
Alter Database [BackupDemoDB] Set Recovery Simple WITH NO_WAIT;	
go
-- You can see what the current setting is with this code
SELECT recovery_model_desc, * FROM sys.databases  WHERE name = 'BackupDemoDB' ;  

-- In all setting, you make changes to the database the same way
Insert into BackupDemoDB.dbo.ProductList Values(2, 'ProdB');
Select * from BackupDemoDB.dbo.ProductList;

-- and you can create a Full backup:
Backup Database BackupDemoDB To BackupDemoDBDevice With Init; 
go

-- However, if the DB is in Simple mode when you make changes ...
Insert into BackupDemoDB.dbo.ProductList Values(3, 'ProdC');
Select * from BackupDemoDB.dbo.ProductList;

-- the changes takes place, but the details about the transaction is NOT recorded in the log file.
-- This means a log file backup will FAIL!
Backup LOG BackupDemoDB To BackupDemoDBDevice; 
go
Print 'THE ISSUE IS >>> BACKUP LOG is not allowed while the recovery model is SIMPLE.'
go

-- Let's switch to bulk logged and try again

-- Step 1) change the recover mode
Alter Database [BackupDemoDB] Set Recovery Bulk_logged WITH NO_WAIT;	

-- Step 2) We have to do full backup afterwards
Backup Database BackupDemoDB To BackupDemoDBDevice With Init; 
go

-- Step 3) Make a change
Insert into BackupDemoDB.dbo.ProductList Values(4, 'ProdD');
Select * from BackupDemoDB.dbo.ProductList;

-- Step 4) Backup the Log
Backup LOG BackupDemoDB To BackupDemoDBDevice; 
go

-- Now you still continue to test those backup restores!
-- but the steps are a bit different!
USE [master];
go
-- Check on the contents of the backup device 

-- Step 1)
Restore HeaderOnly From BackupDemoDBDevice;
 
-- Step 2)
Restore database [BackupDemoReportsDB] 
 From BackupDemoDBDevice
  With File = 1
     , Move N'BackupDemoDB' TO N'C:\BackupFiles\BackupDemoReportsDB.mdf'
     , Move N'BackupDemoDB_log' TO N'C:\BackupFiles\BackupDemoReportsDB.ldf'
     , NoRecovery -- DB NOT open for use 
     , Replace -- Replaces the DB as needed 
go

-- Step 3)
Restore LOG [BackupDemoReportsDB] From BackupDemoDBDevice With File = 2, Recovery -- Now the database can be used again!
go

-- Step 4) continue to check it, of course!
Exec Master.dbo.pTestRestoreForBackupDemoDBToBackupDemoReportsDB;
go
---------------------------------------------------------------------------------------------------------


-- [StandBy Mode] --
---------------------------------------------------------------------------------------------------------
/*
" Setting up a standby server generally involves creating a full backup and 
periodic transaction log backups at the primary server, and then applying those backups, 
in sequence, to the standby server. The standby server is left in a read-only state between restores. 
When the standby server needs to be made available for use, any outstanding transaction 
log backups, including the backup of the active transaction log, from the primary server, 
are applied to the standby server and the database is recovered."
https://technet.microsoft.com/en-us/library/ms178034(v=sql.105).aspx
*/

-- Restoring a database in StandBy mode is another option for making a reports database
-- This option make the restored DB read-only and allows you to restore more database backups
-- WITHOUT have to kick everyone out of the database. 

use [Master];
-- Step 0) Normally- you must kick everyone off of the database before a restore
Alter Database [BackupDemoReportsDB] Set Single_User with Rollback Immediate;
go
-- Step 1) Restore a full backup in StandBy mode
Restore database [BackupDemoReportsDB] 
 From BackupDemoDBDevice
  With File = 1
     , Move N'BackupDemoDB' TO N'C:\BackupFiles\BackupDemoReportsDB.mdf'
     , Move N'BackupDemoDB_log' TO N'C:\BackupFiles\BackupDemoReportsDB.ldf'
     --, NoRecovery -- You do not use this with StandBy mode
     , Replace -- Replaces the DB as needed 
     , StandBy = N'C:\BackupFiles\ROLLBACK_UNDO_BackupDemoReports.BAK' -- Put the DB in StandBy mode
go
-- Step 3)
Restore LOG [BackupDemoReportsDB] 
 From BackupDemoDBDevice 
  With File = 2
     , StandBy = N'C:\BackupFiles\ROLLBACK_UNDO_BackupDemoReports.BAK'
go

-- This database is now a read-only reporting database that can be quickly sync'ed 
-- by restoring log backups.
-- You can see what the current setting is with this code
SELECT is_in_standby, recovery_model_desc, * FROM sys.databases WHERE name = 'BackupDemoDB';  
SELECT is_in_standby, recovery_model_desc, * FROM sys.databases WHERE name = 'BackupDemoReportsDB';  

-- If you make a change to the Source DB
Insert into BackupDemoDB.dbo.ProductList Values(5, 'ProdE');
Select * from BackupDemoDB.dbo.ProductList;
go
-- You cannot perform ETL with transactions
With ChangedData 
As (
 Select ProductId, ProductName From BackupDemoDB.dbo.ProductList
  Except 
 Select ProductId, ProductName From BackupDemoReportsDB.dbo.ProductList
) 
Insert Into BackupDemoReportsDB.dbo.ProductList
 Select ProductId, ProductName From ChangedData; 
go
Print 'Error >> Failed to update database "BackupDemoReportsDB" because the database is read-only.'

-- Instead you must backup and restore the database
Backup LOG BackupDemoDB To BackupDemoDBDevice 
 With Init; -- without Init you need to write complex code to find the Max File ID
Restore LOG [BackupDemoReportsDB] From BackupDemoDBDevice 
  With File = 1 , StandBy = N'C:\BackupFiles\ROLLBACK_UNDO_BackupDemoReports.BAK'

-- An now they are sync'ed!
Select ProductId, ProductName From BackupDemoDB.dbo.ProductList
Select ProductId, ProductName From BackupDemoReportsDB.dbo.ProductList
---------------------------------------------------------------------------------------------------------


-- [Differential Backups] --
---------------------------------------------------------------------------------------------------------
/*
"A differential backup is based on the most recent, previous full data backup. 
A differential backup captures only the data that has changed since that full backup."
https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/differential-backups-sql-server
*/

-- Differential Backups copy data pages that have changed since the Last Full Backup

-- Step 1) Backup the Database 
Backup Database BackupDemoDB To BackupDemoDBDevice With Init; 
go

-- Step 2) Make a change
Insert into BackupDemoDB.dbo.ProductList Values(6, 'ProdF');
Select * from BackupDemoDB.dbo.ProductList;
go

-- Step 3) Backup the Differential (of pages that have changed!)
Backup Database BackupDemoDB To BackupDemoDBDevice With Differential; 
go

-- Step 4) Check the contents of the backup device
Restore HeaderOnly From BackupDemoDBDevice;
go

-- Step 5) Check the contents of the backup device
Restore HeaderOnly From BackupDemoDBDevice;
go

-- Step 6) Restore a full backup 
Restore database [BackupDemoReportsDB] 
 From BackupDemoDBDevice
  With File = 1
     , Move N'BackupDemoDB' TO N'C:\BackupFiles\BackupDemoReportsDB.mdf'
     , Move N'BackupDemoDB_log' TO N'C:\BackupFiles\BackupDemoReportsDB.ldf'
     , NoRecovery -- You do not use this with StandBy mode
     , Replace -- Replaces the DB as needed 
     --, StandBy = N'C:\BackupFiles\ROLLBACK_UNDO_BackupDemoReports.BAK' -- StandBy mode cannot be used with a Differential backup!
go
-- Step 7)
Restore Database [BackupDemoReportsDB] 
 From BackupDemoDBDevice 
  With File = 2
     , Recovery
go

-- Step 8) continue to check it, of course!
Exec Master.dbo.pTestRestoreForBackupDemoDBToBackupDemoReportsDB;
go