--*************************************************************************--
-- Title: Index Basics
-- Author: RRoot
-- Desc: This file demonstrates working with SQL Indexes.
-- Change Log: When,Who,What
-- 2021-08-17,RRoot,Created File
--**************************************************************************--
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

'Comparing Clustered and NonClustered Indexes'
-- Let's capture some data for the demo
Begin Try Drop Table TestTitles; End Try Begin Catch End Catch
Begin Try Drop Table TestPublishers; End Try Begin Catch End Catch
go
Select * Into TestTitles From pubs..titles
Select * Into TestPublishers From Pubs..publishers
go
'Note: Turn on the Execution Plan'
-- The orignal was clustered, but the copy is a heap
Select * From pubs..Titles;
Select * From pubs..Publishers;

Select * From TestTitles;
Select * From TestPublishers;
go


-- Queries on the copy have to scan the heap
'Compare the cost of using a heap when filtering data'

Select p.Pub_Name, t.* 
  From pubs..Titles as t Join pubs..Publishers as p
   On t.pub_id = p.Pub_id
  Where Pub_name = 'New Moon Books';
go

Select p.Pub_Name, t.* 
  From TestTitles as t Join TestPublishers as p
    On t.pub_id = p.Pub_id
  Where Pub_name = 'New Moon Books';
go

-- Let's add some indexes to help with the Join
-- Parent table (NOTE: This will create Key IDs since the table is now clustered)
Create Clustered Index ciPub_id
  On TestPublishers(pub_id) 
go
-- The Child table (NOTE: This will use a Row ID since the table is a heap)
Create NonClustered Index nciPub_id
  On TestTitles(pub_id)
go

Exec Sp_helpIndex TestPublishers
Exec Sp_helpIndex TestTitles
go

DBCC ShowContig (TestPublishers)
DBCC ShowContig (TestTitles) 
'Index ID of 1 is always a Clustered Index. '
'Index ID of 0 is always a Heap. '
go

DBCC ShowContig (TestTitles) With ALL_INDEXES
go
-- Let's add another index and see what ID it gets
-- NOTE: This will use a RID since the table is a heap)
Create NonClustered Index nciType
  On TestTitles(type);
go
Exec Sp_helpIndex TestTitles;
DBCC ShowContig (TestTitles) With ALL_INDEXES; -- Returns a Message (Print)
DBCC ShowContig (TestTitles) With TABLERESULTS, ALL_INDEXES; -- Returns a Results (Select)

-- Lets change the table from a Heap to to Cluster
-- before we do, note the Execution place using the Heap.
Select p.Pub_Name, t.* 
  From TestTitles as t Join TestPublishers as p
    On t.pub_id = p.Pub_id
  Where Pub_name = 'New Moon Books';
go

Alter Table TestTitles -- Drop Constraint pkTestTitles
  Add Constraint pkTestTitles Primary Key (title_id);
go
'NOTE: Though invisible, both NonClustered indexes were rebuilt
 to use Keys instead of RIDS, and the execution plance now shows an index scan!'

-- Note that "Index" ID 0 is now Index ID 1
DBCC ShowContig (TestTitles) With ALL_INDEXES;


-- OK now look at the execution plan again and note the change.
Select p.Pub_Name, t.* 
  From TestTitles as t Join TestPublishers as p
    On t.pub_id = p.Pub_id -- This will cause an Index Seek in Publishers
  Where Pub_name = 'New Moon Books'; -- This will cause an Clusered Index Seek in Publishers
go

Select p.Pub_Name, t.* 
  From TestTitles as t Join TestPublishers as p
    On t.pub_id = p.Pub_id; -- This will cause a Clusered Index Seek Publishers
    -- ,but this is now doing an Clusered Index Scan instead of a heap Scan in Titles 
go

-- ODDLY, even with a Where on a Indexed column you may still get an Clusered Index Seek
Select * 
  From TestTitles 
  Where type = 'business'; -- SQL says, "Table is too small so ignore NCI!"
go

-- Though you can force it, is usually does not get better results then the QUERY OPTIMIZER
Select * 
  From TestTitles 
  Where type = 'business'; -- SQL says, "Table is too small so ignore NCI!"
go
Select * 
  From TestTitles WITH(Index(nciType)) -- Force the query to use this index"
  Where type = 'business';
go
'Note: The QUERY OPTIMIZER is almost always correct, but you can always test it this way!'

-- You can use this system view to see WHEN or IF and index is used
Select Object_name([object_id]) ,*
From sys.dm_db_index_usage_stats
Where Object_name([object_id]) = 'TestTitles'
Go
'Note: Indexes that never get used should be dropped.'


-- Microsoft has created several views and stored procedures for investigating indexes.
Exec Sp_help TestTitles;
-- or
Exec Sp_helpIndex TestTitles;
-- or
Select * From SysIndexes Where Id = Object_id('TestTitles')
-- or
Select * From Sys.Indexes Where [Object_Id] = Object_id('TestTitles')
go

-- Microsoft has been trying to replace there Database Console Commands (DBCC) 
-- for several years now, but with mixed results.
-- Here is an example of a function that is supposed to replace DBCC ShowContig 
USE MASTER -- Only runs if you are pointed to Master DB
go
sp_help 'sys.dm_db_index_physical_stats'
go
Select 
  index_id	
,	index_type_desc	
,	avg_fragmentation_in_percent
, fragment_count	
,	page_count	
, avg_page_space_used_in_percent	
, record_count	
,	min_record_size_in_bytes
,	max_record_size_in_bytes	
, avg_record_size_in_bytes	
From sys.dm_db_index_physical_stats  --<<< This is a Function, so these are arguments and do not require a WHERE clause
(DB_id('Mod7DemoDB') -- @DatabaseId =
,Object_id(N'Mod7DemoDB.dbo.TestTitles') -- @ObjectId
,null -- @IndexId
,null -- @PartitionNumber 
,'Sampled' -- @Mode
)
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver15

