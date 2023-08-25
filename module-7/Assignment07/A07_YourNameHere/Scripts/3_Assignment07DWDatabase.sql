--*************************************************************************--
-- Title: Module05 DW Destination Database
-- Desc:This file will drop and create a DW database for module 05's assignment. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
--*************************************************************************--
-- Create the database
Use Master;
go

If Exists(Select name from master.dbo.sysdatabases Where Name = 'DWEmployeeProjects')
Begin
	Use [master];
	Alter Database [DWEmployeeProjects] Set Single_User With Rollback Immediate;
	Drop Database [DWEmployeeProjects];
End;
go

Create Database DWEmployeeProjects; 
go

Use DWEmployeeProjects;
go

--********************************************************************--
-- Create the tables --
--********************************************************************--
Create Table DimEmployees
(EmployeeKey int Primary Key Identity
,EmployeeID int 
,EmployeeName varchar(100)
);
go

go
Create Table DimProjects
(ProjectKey int Primary Key Identity
,ProjectID int 
,ProjectName varchar(100)
);

Create Table DimDates
([DateKey] int Constraint pkDimDates Primary Key
,[FullDate] date
,[USADateName] varchar(100)
,[MonthKey] int
,[MonthName] varchar(100)
,[QuarterKey] int
,[QuarterName] varchar(100)
,[YearKey] int
,[YearName] varchar(100)
);
go

Create Table FactEmployeeProjectHours 
([EmployeeProjectHoursID] int Not Null
,[EmployeeKey] int Not Null 
,[ProjectKey] int Not Null
,[DateKey] int Not Null
,[HoursWorked] decimal(4,2) Not Null
Constraint pkEmployeeProjectHours Primary Key ([EmployeeProjectHoursID],[EmployeeKey],[ProjectKey],[DateKey])
);
go

--********************************************************************--
-- Add the constraints --
--********************************************************************--
Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimEmployees
    Foreign Key(EmployeeKey) References DimEmployees(EmployeeKey);
go

Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimProjects
    Foreign Key(ProjectKey) References DimProjects(ProjectKey);
go

Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimDates
    Foreign Key(DateKey) References DimDates(DateKey);
go

-- TODO: Add NC Indexes on the FK columns

Select  
[SourceObjectName] = TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME + '.' + COLUMN_NAME
, IS_NULLABLE
, DATA_TYPE
, CHARACTER_MAXIMUM_LENGTH = IIf(DATA_TYPE = 'int','NA', IsNull(Cast(CHARACTER_MAXIMUM_LENGTH as varchar(10)), 'NA'))
, NUMERIC_PRECISION = IIf(DATA_TYPE = 'int', 'NA', IsNull(Cast(NUMERIC_PRECISION as varchar(10)), 'NA'))
, NUMERIC_SCALE = IIf(RTrim(DATA_TYPE) = 'int', 'NA', IsNull(Cast(NUMERIC_SCALE as varchar(10)), 'NA'))
From INFORMATION_SCHEMA.COLUMNS
go