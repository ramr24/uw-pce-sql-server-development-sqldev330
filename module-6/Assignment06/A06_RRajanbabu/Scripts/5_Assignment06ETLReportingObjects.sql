--*************************************************************************--
-- Title: Creating ETL Views
-- Author: RRoot
-- Desc: This file creates several ETL views used in Admin reports
-- Change Log: When,Who,What
-- 2018-02-07,RRoot,Created File
--**************************************************************************--
Use [DWEmployeeProjects];
go
-- Use these statements to check and clear the jobhistory table as needed
Select * From msdb.dbo.sysjobs;
Select * From msdb.dbo.sysjobhistory;
-- EXEC MSDB.dbo.sp_purge_jobhistory;  

go
Create or Alter View vDWEmployeeProjectsETLJobHistory
As
Select Top 100000
 [JobName] = j.name 
,[StepName] = h.step_name
,[RunDateTime] = msdb.dbo.agent_datetime(run_date, run_time)
,[RunDurationSeconds] = h.run_duration
From msdb.dbo.sysjobs as j 
  Inner Join msdb.dbo.sysjobhistory as h 
    ON j.job_id = h.job_id 
Where j.enabled = 1 And j.name = 'ETL DWEmployeeProjects' --'DWEmployeeProjectsETL'
Order by JobName, RunDateTime desc

go
Select * From vDWEmployeeProjectsETLJobHistory;


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
Create or Alter View vDimEmployeesTopTen
As
Select Top 10 -- Using Top 10 to make the reports easier to work with in the assignment
 [EmployeeKey]
,[EmployeeID]
,[EmployeeName]
From [DimEmployees]
Order by 1 asc 
go
Select * From vDimEmployeesTopTen;

go
Create or Alter View vDimProjectsTopTen
As
Select Top 10 -- Using Top 10 to make the reports easier to work with in the assignment
 [ProjectKey]
,[ProjectID]
,[ProjectName]
From [DimProjects]
Order by 1 asc
go
Select * From vDimProjectsTopTen;

go
Create or Alter View vFactEmployeeProjectHoursTopTen
As
Select Top 10 -- Using Top 10 to make the reports easier to work with in the assignment
 [EmployeeProjectHoursID]
,[EmployeeKey]
,[ProjectKey]
,[DateKey]
,[HoursWorked]
From [dbo].[FactEmployeeProjectHours]
Order by 1 Asc
go
Select * From vFactEmployeeProjectHoursTopTen;

go
Create or Alter View DWEmployeeProjectsRowCounts
As
With [RowCounts] -- Using a CTE to access the Top Command for the Order By statement in the view
As(
Select [SortCol] = 1, [TableName] = 'DimDates', [CurrentNumberOfRows] = Count(*) From [DimDates]
Union               
Select [SortCol] = 2, [TableName] = 'DimEmployees', [CurrentNumberOfRows] = Count(*) From [DimEmployees]
Union                
Select [SortCol] = 3, [TableName] = 'DimProjects', [CurrentNumberOfRows] = Count(*) From [DimProjects]
Union                
Select [SortCol] = 4, [TableName] = 'FactEmployeeProjectHours', [CurrentNumberOfRows] = Count(*) From [FactEmployeeProjectHours]
Union                
Select [SortCol] = 5, [TableName] = 'ETLMetadata', [CurrentNumberOfRows] = Count(*) From [ETLMetadata]
) Select Top 100000 [SortCol],[TableName],[CurrentNumberOfRows]
  From [RowCounts]
  Order By [SortCol] asc; -- Use a sort column so it does not sort by table name.
go


Select * From DWEmployeeProjectsRowCounts;

go

-- Use this for testing
Update EmployeeProjects.dbo.Employees Set LName = 'Habershonzzz' Where ID = 1;
Select * From EmployeeProjects.dbo.Employees
Select * From vETLDimEmployees;
Select * From DimEmployees;
-- Update EmployeeProjects.dbo.Employees Set LName = 'Habershon' Where ID = 1;
go