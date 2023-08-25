--*************************************************************************--
-- Title: Demo03 - Managing Indexes
-- Author: RRoot
-- Desc: This file demonstrates how you can create and test indexes
-- Change Log: When,Who,What
-- 2018-02-28,RRoot,Created File
--**************************************************************************--

-- [Managing Indexes] -- 
-----------------------------------------------------------------------------------------------------------------------
-- SQL Server 2019 is good about mananaging fragmentaion when a database is created. 
-- So, I am going to use an older fragments copy of the Northwind database for this demo.
USE [TempDB];
go
Create Proc pResetDemo
As
Begin
  RESTORE DATABASE [NWTest] 
  FROM DISK = N'C:\_SQL330\northwind.bak' 
  WITH
   MOVE N'Northwind' TO N'C:\_SQL330\NWTest.MDF'
  ,MOVE N'Northwind_log' TO N'C:\_SQL330\NWTest_log.ldf'
  ,REPLACE;
End
GO

Exec pResetDemo;
go

Use NWTest;
go
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-compatibility-views/sys-sysindexes-transact-sql?view=sql-server-ver15
-- Getting information From SysIndexes (not the same as sys.Indexes)
Select id, Object_Name(id), indid, 'Data Pages' = dpages, origfillfactor, [name], [rows] 
 From NWTest.dbo.sysindexes
  Where name like '%Order%'
go

-- Note: The results  in IndID of the above query indicate the following
-- ID of index: 
Print '	0 = Table is in a HEAP
	      1 = Clustered index
	     >1 = Nonclustered
	    255 = Entry for tables that have text or image data'
go
-- Microsoft has created several views and stored procedures for investigating indexes.
Exec Sp_help 'Orders';
-- OR
Exec Sp_helpIndex 'Orders'; -- NOTE the redundent Indexes
-- OR
Select name, * From SysIndexes Where Id = Object_id('Orders')
-- OR
Select * From Sys.Indexes Where [Object_Id] = Object_id('Orders')
-- OR
DBCC ShowContig ('Orders') With ALL_INDEXES 
go

-- Seeing when an index was last used
Select TOP 1 * 
  From Orders as o Join [Order Details] as od ON o.OrderID = od.OrderID;
Select  index_id, user_seeks, user_scans, last_user_seek, last_user_scan, last_user_update
  From sys.dm_db_index_usage_stats Where Object_name([object_id]) = 'Orders'


--[Fixing Fragmentation]--
-----------------------------------------------------------------------------------------------------------------------
-- One way to fix framentation is to drop and recreate the index
-- Note that this index is fragmented at the Extent level.
Exec Sp_helpIndex 'Order Details';
DBCC ShowContig ('Order Details','ProductsOrder_Details') 
DBCC ShowContig ('Order Details','ProductID') 
go
-- We drop and remake the index then check it again
If Exists (Select * from sysindexes Where Name = 'ProductsOrder_Details')
  Drop Index [Order Details].ProductsOrder_Details
go
CREATE NONCLUSTERED INDEX ProductsOrder_Details
 ON [Order Details] (ProductID);
go
DBCC ShowContig ('Order Details','ProductsOrder_Details') 
DBCC ShowContig ('Order Details','ProductID') 
go
-- Another way to do this is to use the Drop Existing option
CREATE NONCLUSTERED INDEX ProductID ON [Order Details] (ProductID)
  WITH DROP_EXISTING;
go
DBCC ShowContig ('Order Details','ProductsOrder_Details') 
DBCC ShowContig ('Order Details','ProductID') 

 -- This will rebuild the index and has a number of options and is thorough
Exec Sp_helpIndex 'Order Details';
DBCC SHOWCONTIG ('Order Details', OrderID);
go
ALTER INDEX OrderID ON [Order Details] REBUILD
go
DBCC SHOWCONTIG ('Order Details', OrderID);


-- This will reorganize the index but has few options and is not as thorough
Exec Sp_helpIndex 'Order Details';
DBCC SHOWCONTIG ('Order Details', OrdersOrder_Details);
go
ALTER INDEX OrdersOrder_Details ON [Order Details] REORGANIZE 
go
DBCC SHOWCONTIG ('Order Details', OrdersOrder_Details);

-- This rebuilds the Clustered Index AND all NonClustered too
Use Master;
Exec pResetDemo;
Use NWTest;
go
Exec Sp_helpIndex 'Order Details';
DBCC ShowContig ([Order Details]) With ALL_INDEXES 
go
Alter Table [Order Details]
  Drop Constraint PK_Order_Details
go
Alter Table [Order Details]
  Add Constraint PK_Order_Details Primary Key(OrderID, ProductID);
go
DBCC ShowContig ([Order Details]) With ALL_INDEXES 

-- So will this
Use Master;
Exec pResetDemo;
Use NWTest;
go
DBCC ShowContig ([Order Details]) With ALL_INDEXES 
go
ALTER INDEX ALL ON [Order Details] REBUILD;
go
DBCC ShowContig ([Order Details]) With ALL_INDEXES 

-- [Index Fill Factors] --
-----------------------------------------------------------------------------------------------------------------------

-- Using the FILLFACTOR and PAD_INDEX Option changes how the pages are filled.
Exec Sp_helpIndex 'Orders';
Alter INDEX CustomerID ON Orders Rebuild WITH (FILLFACTOR= 10) -- 10% full and 90% empty
go
DBCC SHOWCONTIG (Orders, CustomerID) -- This command shows how full or empty the pages are
go
Alter INDEX CustomerID ON Orders Rebuild WITH (FILLFACTOR= 30) -- 30% full and 70% empty
go
DBCC SHOWCONTIG (Orders, CustomerID) -- This command shows how full or empty the pages are
go
Alter INDEX CustomerID ON Orders Rebuild WITH (FILLFACTOR= 100) -- 100% full and ???% empty
go
DBCC SHOWCONTIG (Orders, CustomerID) -- This command shows how full or empty the pages are
go

-- [ Rebuilding All Indexes with a SQL Cursor] --
-----------------------------------------------------------------------------------------------------------------------
Print 'Note: Turn OFF the Execution Plan';
use NWTest;
declare @date as varchar(20)
Select @date = convert(varchar(20), GetDate(), 101)
declare csrTableNames cursor
for
Select name From sys.Objects where type = 'u'
open csrTableNames
declare @name sysname
fetch next from csrTableNames into @name
while @@fetch_status <> -1
 begin
    Declare @Statement nvarchar(1000) = 'ALTER INDEX ALL ON [' + @name + '] REBUILD'
    Select @Statement  
    execute (@Statement)
    raiserror('Indexes were rebuilt on %s for %s', 10, 1, @date , @name)
   fetch next from csrTableNames into @name
 end
close csrTableNames
deallocate csrTableNames


-- [ Rebuilding All Indexes with a MSForEachTable Stored Procedure] --
-----------------------------------------------------------------------------------------------------------------------
USE NWTest;
GO
EXEC sp_MSforeachtable @command1="print 'rebuilding indexes in table: ?'", @command2="ALTER INDEX ALL ON ?
REBUILD WITH (ONLINE=ON)";
GO


-- [SQL Server Statistics] --
-----------------------------------------------------------------------------------------------------------------------
-- "By default, the query optimizer already updates statistics as necessary to 
-- improve the query plan; in some cases you can improve query performance by 
-- using UPDATE STATISTICS or the stored procedure sp_updatestats to update statistics 
-- more frequently than the default updates. 
-- ...
-- Updating statistics ensures that queries compile with up-to-date statistics."
  -- (https://docs.microsoft.com/en-us/sql/t-sql/statements/update-statistics-transact-sql, 2017)  -- 

USE NWTest;
GO

Select * From Sys.stats
DBCC SHOW_STATISTICS (Products, ProductsStats);  
GO  

CREATE STATISTICS ProductsStats  
 ON Products ([ProductName], ProductID)  
  WITH SAMPLE 50 PERCENT  

-- Time passes. The UPDATE STATISTICS statement is then executed.  
UPDATE STATISTICS Products;  
-- or 
UPDATE STATISTICS Products(ProductsStats) WITH SAMPLE 50 PERCENT;
-- or  
UPDATE STATISTICS Products(ProductsStats) WITH FullScan;

-- Updating All Statistics in the database --
EXEC sp_updatestats; 