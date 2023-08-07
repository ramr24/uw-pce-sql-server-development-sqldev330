--*************************************************************************--
-- Title: Module03 Source Database
-- Desc:This file will drop and create a database for module 03's assignment. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
--*************************************************************************--
-- Create the database
Use Master;
go
If Exists(Select name from master.dbo.sysdatabases Where Name = 'EmployeeProjects')
Begin
	Use [master];
	Alter Database [EmployeeProjects] Set Single_User With Rollback Immediate;
	Drop Database [EmployeeProjects];
End;
go

Create Database EmployeeProjects; 
go

Use EmployeeProjects;
go

--********************************************************************--
-- Create the tables --
--********************************************************************--

Create Table Employees
([ID] int Constraint pkEmployees Primary Key Identity(10,10)
,[FName] varchar(15)
,[LName] varchar(20)
,[Address] varchar(100)
,[City] varchar(50)
,[State] char(2)
,[Zipcode] char(5)
);
go

Create Table Projects
([ID] int Constraint pkProjects Primary Key Identity(10,10)
,[Name] varchar(17)
,[Desc] varchar(200)
);
go

Create Table EmployeeProjectHours
([EmployeeProjectHoursID] int Constraint pkEmployeeProjectHours Primary Key Identity
,[EmployeeID] int 
,[ProjectID] int
,[Date] date
,[Hrs] decimal(4,2)
);
go

--********************************************************************--
-- Add the constraints --
--********************************************************************--

Alter Table EmployeeProjectHours 
  Add Constraint FK_EmployeeProjectHours_Employees
  Foreign Key (EmployeeID) References Employees(ID);
go

Alter table EmployeeProjectHours 
  Add Constraint FK_EmployeeProjectHours_Projects
  Foreign Key(ProjectID) References Projects(ID);
go

--********************************************************************--
-- Fill the tables with mockup data --
--********************************************************************--
-- Data was generated using the app at https://www.mockaroo.com/
Set NoCount On;														
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Roselin', 'Habershon', '00441 Briar Crest Lane', 'San Jose', 'CA', '95123');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Samuel', 'Kwietek', '9367 Pennsylvania Junction', 'Los Angeles', 'CA', '90010');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Zorina', 'McTaggart', '0 Debra Junction', 'Seattle', 'WA', '98158');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Josiah', 'Janicki', '18542 Stuart Lane', 'Spokane', 'WA', '99252');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Arabele', 'Ivashnikov', '5449 Russell Drive', 'Seattle', 'WA', '98166');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Margaretha', 'Novik', '881 Sommers Avenue', 'Los Angeles', 'CA', '90055');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Cosimo', 'Cheverell', '884 Knutson Drive', 'Santa Monica', 'CA', '90405');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Debbie', 'Trusler', '36885 Lien Avenue', 'San Diego', 'CA', '92196');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Catha', 'Klaesson', '5644 Mallory Street', 'Stockton', 'CA', '95205');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Orton', 'Dandy', '3 Thackeray Crossing', 'Seattle', 'WA', '98175');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Nathaniel', 'Whate', '05870 Dennis Center', 'Los Angeles', 'CA', '90081');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Sean', 'Mustoo', '0274 Oak Pass', 'Irvine', 'CA', '92710');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Adler', 'Reames', '453 Prentice Center', 'Portland', 'OR', '97206');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Petronella', 'Jinkin', '7177 Welch Street', 'Santa Barbara', 'CA', '93111');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Jamaal', 'McClaren', '608 6th Park', 'Bakersfield', 'CA', '93399');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Dyana', 'Vurley', '079 Brown Center', 'Burbank', 'CA', '91505');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Fabien', 'Maddrell', '4386 Dorton Place', 'Irvine', 'CA', '92619');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Katharine', 'Bottoner', '3 Prentice Lane', 'Salem', 'OR', '97312');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Olivero', 'Coping', '999 Southridge Terrace', 'Sacramento', 'CA', '95852');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Philbert', 'Abbotson', '9 North Park', 'Santa Rosa', 'CA', '95405');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Modesty', 'Rableau', '600 Debs Road', 'San Francisco', 'CA', '94105');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Drusi', 'Cluett', '3 Upham Trail', 'Santa Clara', 'CA', '95054');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Jackie', 'Boshere', '55151 Summer Ridge Crossing', 'San Diego', 'CA', '92127');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Debi', 'Beatey', '63 Old Gate Road', 'Fullerton', 'CA', '92640');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Silvanus', 'Ambrose', '058 Park Meadow Terrace', 'Spokane', 'WA', '99220');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Marika', 'Ludewig', '73 Carpenter Lane', 'Visalia', 'CA', '93291');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Giff', 'Tinwell', '1340 Stone Corner Terrace', 'Seattle', 'WA', '98121');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Leonora', 'Persent', '095 Waywood Pass', 'South Lake Tahoe', 'CA', '96154');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Lukas', 'Bole', '403 Grim Hill', 'Berkeley', 'CA', '94705');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Donnie', 'Jenicek', '8 Anzinger Point', 'Sacramento', 'CA', '95894');
go

Insert into Projects (Name, [Desc]) values ('Login Update', 'Login Update project');
Insert into Projects (Name, [Desc]) values ('DW Planing', 'DW Planing project');
Insert into Projects (Name, [Desc]) values ('DW Implementation', 'DW Implementation project');
Insert into Projects (Name, [Desc]) values ('Web Site Review', 'Web Site Review project');
Insert into Projects (Name, [Desc]) values ('Web Logging Addon', 'Web Logging Addon project');
Insert into Projects (Name, [Desc]) values ('ETL', 'ETL project');
Insert into Projects (Name, [Desc]) values ('Document Update', 'Document Update project');
Insert into Projects (Name, [Desc]) values ('DB Review', 'DB Review project');
Insert into Projects (Name, [Desc]) values ('DW Test', 'DW Test project');
Insert into Projects (Name, [Desc]) values ('DW Release', 'DW Release project');			
go		

Create Table EmployesProjectHoursStaging
([EmployeeID] int 
,[ProjectID] int
,[Date] date  -- Using a stating table so that I can sort the random data before inserting
,[Hrs] int
,[HrsPart] decimal(4,2)
);
go

Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (40, 90, '01/29/2020', 1, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (70, 80, '01/01/2020', 3, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (130, 70, '01/21/2020', 4, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (40, 10, '01/19/2020', 5, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (130, 10, '01/01/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (80, 40, '01/06/2020', 7, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (280, 90, '01/09/2020', 0, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (60, 30, '01/06/2020', 6, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (220, 50, '01/24/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (70, 70, '01/19/2020', 8, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (220, 80, '01/25/2020', 7, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (210, 40, '01/06/2020', 1, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (10, 60, '01/08/2020', 8, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (70, 80, '01/22/2020', 3, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (210, 80, '01/16/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (250, 10, '01/19/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (60, 90, '01/03/2020', 8, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (100, 100, '01/18/2020', 4, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (290, 10, '01/19/2020', 7, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (70, 70, '01/24/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (120, 70, '01/21/2020', 0, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (30, 10, '01/21/2020', 4, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (40, 50, '01/16/2020', 6, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (260, 70, '01/08/2020', 7, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (60, 90, '01/03/2020', 0, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (110, 60, '01/04/2020', 5, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (260, 10, '01/15/2020', 7, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (50, 40, '01/25/2020', 7, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (20, 40, '01/12/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (190, 60, '01/01/2020', 7, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (280, 60, '01/20/2020', 5, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (80, 60, '01/22/2020', 1, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (160, 20, '01/16/2020', 0, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (290, 40, '01/05/2020', 7, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (20, 100, '01/11/2020', 3, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (180, 40, '01/06/2020', 8, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (80, 80, '01/01/2020', 4, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (70, 70, '01/24/2020', 8, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (220, 70, '01/23/2020', 6, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (290, 10, '01/10/2020', 1, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (240, 90, '01/17/2020', 6, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (140, 50, '01/26/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (20, 20, '01/09/2020', 8, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (80, 40, '01/22/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (220, 70, '01/02/2020', 3, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (110, 10, '01/15/2020', 5, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (70, 50, '01/24/2020', 7, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (220, 40, '01/08/2020', 6, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (90, 80, '01/22/2020', 6, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (260, 20, '01/07/2020', 3, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (170, 10, '01/07/2020', 1, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (210, 40, '01/17/2020', 8, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (70, 70, '01/03/2020', 4, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (100, 10, '01/21/2020', 1, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (200, 60, '01/12/2020', 1, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (70, 90, '01/25/2020', 4, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (10, 80, '01/12/2020', 5, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (60, 80, '01/09/2020', 4, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (210, 30, '01/04/2020', 4, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (20, 90, '01/26/2020', 5, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (210, 20, '01/20/2020', 1, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (10, 100, '01/11/2020', 5, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (140, 60, '01/11/2020', 3, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (150, 60, '01/19/2020', 3, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (80, 60, '01/03/2020', 1, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (150, 100, '01/12/2020', 8, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (200, 70, '01/12/2020', 2, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (120, 40, '01/22/2020', 0, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (70, 90, '01/25/2020', 3, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (140, 50, '01/01/2020', 6, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (20, 30, '01/17/2020', 2, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (100, 80, '01/08/2020', 8, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (80, 70, '01/26/2020', 6, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (230, 30, '01/02/2020', 4, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (150, 50, '01/21/2020', 1, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (210, 50, '01/28/2020', 0, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (20, 50, '01/17/2020', 4, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (80, 50, '01/02/2020', 6, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (100, 40, '01/21/2020', 2, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (60, 10, '01/15/2020', 0, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (220, 60, '01/17/2020', 0, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (180, 60, '01/14/2020', 5, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (280, 10, '01/16/2020', 4, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (130, 50, '01/12/2020', 5, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (230, 60, '01/04/2020', 5, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (300, 80, '01/23/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (30, 10, '01/07/2020', 6, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (70, 20, '01/23/2020', 5, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (290, 20, '01/19/2020', 3, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (190, 30, '01/14/2020', 6, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (60, 70, '01/19/2020', 5, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (80, 80, '01/10/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (110, 30, '01/04/2020', 2, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (220, 70, '01/19/2020', 6, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (190, 100, '01/14/2020', 6, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (270, 20, '01/02/2020', 3, '.75');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (100, 20, '01/09/2020', 5, '.50');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (210, 10, '01/15/2020', 8, '.25');
Insert Into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (260, 20, '01/20/2020', 1, '.50');
Insert into EmployesProjectHoursStaging (EmployeeID, ProjectID, Date, Hrs, HrsPart) Values (200, 100, '01/21/2020', 3, '.25');
go																					

Insert Into EmployeeProjectHours
(EmployeeID, ProjectID, Date,[Hrs]) 
Select Distinct EmployeeID, ProjectID, Date, Hrs + HrsPart as [Hrs] 
From EmployesProjectHoursStaging
Order By [Date] asc;
go

Drop Table EmployesProjectHoursStaging;
go

--********************************************************************--
-- Show the database's metadata and data
--********************************************************************--
Select  
[SourceObjectName] = TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME + '.' + COLUMN_NAME
, IS_NULLABLE
, DATA_TYPE
, CHARACTER_MAXIMUM_LENGTH
, NUMERIC_PRECISION
, NUMERIC_SCALE
From INFORMATION_SCHEMA.COLUMNS
go

Select * From Employees;
Select * From Projects;
Select * From EmployeeProjectHours;
go

