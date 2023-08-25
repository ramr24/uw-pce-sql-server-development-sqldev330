--*************************************************************************--
-- Title: Final ETL Reporting Views
-- Author: RRoot
-- Desc: This file creates several ETL views used in Final reports
-- Change Log: When,Who,What
-- 2018-02-07,RRoot,Created File
--**************************************************************************--
Use DWIndependentBookSellers;
go
-- Use these statements to check and clear the jobhistory table as needed
-- Select * From msdb.dbo.sysjobs;
-- Select * From msdb.dbo.sysjobhistory;
-- EXEC MSDB.dbo.sp_purge_jobhistory;  

go
Create or Alter View vDWIndependentBookSellersETLJobHistory
As
Select Top 100000
 [JobName] = j.name 
,[StepName] = h.step_name
,[RunDateTime] = msdb.dbo.agent_datetime(run_date, run_time)
,[RunDurationSeconds] = h.run_duration
From msdb.dbo.sysjobs as j 
  Inner Join msdb.dbo.sysjobhistory as h 
    ON j.job_id = h.job_id 
Where j.enabled = 1 And j.name = 'DWIndependentBookSellersETL'
Order by JobName, RunDateTime desc

go
Select * From vDWIndependentBookSellersETLJobHistory;

go
Create or Alter View vDimDatesTopTen
As
Select Top 10 -- Using Top 10 to make the reports easier to work with in the assignment
 [DateKey]
,[FullDate]
,[USADateName]
,[MonthKey]
,[MonthName]
,[QuarterKey]
,[QuarterName]
,[YearKey]
,[YearName]
From [DimDates]
Order by 1 desc
go
Select * From vDimDatesTopTen;

go
Create or Alter View vDimAuthorsTopTen
As
Select Top 10 -- Using Top 10 to make the reports easier to work with in the assignment
AuthorKey, AuthorID, AuthorName, AuthorCity, AuthorState
From [DimAuthors]
Order by 1 asc 
go
Select * From vDimAuthorsTopTen;

go
Create or Alter View vDimTitlesTopTen
As
Select Top 10 -- Using Top 10 to make the reports easier to work with in the assignment
TitleKey, TitleID, TitleName, TitleType, TitleListPrice
From [DimTitles]
Order by 1 asc
go
Select * From vDimTitlesTopTen;

go
Create or Alter View vDimStoresTopTen
As
Select Top 10 -- Using Top 10 to make the reports easier to work with in the assignment
StoreKey, StoreID, StoreName, StoreCity, StoreState
From [DimStores]
Order by 1 asc
go
Select * From vDimStoresTopTen;

go
Create or Alter View vFactTitleAuthorsTopTen
As
Select Top 10 -- Using Top 10 to make the reports easier to work with in the assignment
AuthorKey, TitleKey, AuthorOrder
From [FactTitleAuthors]
Order by 1 Asc
go
Select * From vFactTitleAuthorsTopTen;

go
Create or Alter View vFactSalesTopTen
As
Select Top 10 -- Using Top 10 to make the reports easier to work with in the assignment
OrderNumber, OrderDateKey, StoreKey, TitleKey, SalesQty, SalesPrice
From [FactSales]
Order by 1 Asc
go
Select * From vFactSalesTopTen;

go
Create or Alter View DWIndependentBookSellersRowCounts
As
With [RowCounts] -- Using a CTE to access the Top Command for the Order By statement in the view
As(
Select [SortCol] = 1, [TableName] = 'DimDates', [CurrentNumberOfRows] = Count(*) From [DimDates]
Union               
Select [SortCol] = 2, [TableName] = 'DimAuthors', [CurrentNumberOfRows] = Count(*) From [DimAuthors]
Union                
Select [SortCol] = 3, [TableName] = 'DimTitles', [CurrentNumberOfRows] = Count(*) From [DimTitles]
Union                
Select [SortCol] = 3, [TableName] = 'DimStores', [CurrentNumberOfRows] = Count(*) From [DimStores]
Union                
Select [SortCol] = 4, [TableName] = 'FactTitleAuthors', [CurrentNumberOfRows] = Count(*) From [FactTitleAuthors]
Union  
Select [SortCol] = 4, [TableName] = 'FactSales', [CurrentNumberOfRows] = Count(*) From [FactSales]
Union                
Select [SortCol] = 5, [TableName] = 'ETLLog', [CurrentNumberOfRows] = Count(*) From [ETLLog]
) Select Top 100000 [SortCol],[TableName],[CurrentNumberOfRows]
  From [RowCounts]
  Order By [SortCol] asc; -- Use a sort column so it does not sort by table name.
go

Select * From DWIndependentBookSellersRowCounts;
go

-- Use this for testing
-- Create a differences between the source and destination databases
Update [IndependentBookSellers].[dbo].[Stores] Set [stor_name] = 'Bookbeatzz' Where stor_id = 8042;
Select * From [IndependentBookSellers].[dbo].[Stores]
-- Verify the difference
Select * From vETLDimStores;
Select * From DimStores;
-- Reset the data
Update [IndependentBookSellers].[dbo].[Stores] Set [stor_name] = 'Bookbeat' Where stor_id = 8042;
go