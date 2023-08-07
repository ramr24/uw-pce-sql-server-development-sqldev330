--*************************************************************************--
-- Title: Assignment02
-- Author: RRoot
-- Desc: This file tests you knowlege on how to create a Incremental ETL process with SQL code
-- Change Log: When,Who,What
-- 2018-01-17,RRoot,Created File

-- Instructions: 
-- (STEP 1) Restore the AdventureWorks_Basics database by running the provided code.
-- (STEP 2) Create a new Data Warehouse called DWAdventureWorks_BasicsWithSCD based on the AdventureWorks_Basics DB.
--          The DW should have three dimension tables (for Customers, Products, and Dates) and one fact table.
-- (STEP 3) Fill the DW by creating an Incremental ETL Script
--**************************************************************************--
USE [DWAdventureWorks_BasicsWithSCD];
go
SET NoCount ON;
go
	If Exists(Select * from Sys.objects where Name = 'vETLDimProducts')
   Drop View vETLDimProducts;
go
	If Exists(Select * from Sys.objects where Name = 'pETLSyncDimProducts')
   Drop Procedure pETLSyncDimProducts;
go
	If Exists(Select * from Sys.objects where Name = 'vETLDimCustomers')
   Drop View vETLDimCustomers;
go
	If Exists(Select * from Sys.objects where Name = 'pETLSyncDimCustomers')
   Drop Procedure pETLSyncDimCustomers;
go
	If Exists(Select * from Sys.objects where Name = 'pETLFillDimDates')
   Drop Procedure pETLFillDimDates;
go
	If Exists(Select * from Sys.objects where Name = 'vETLFactOrders')
   Drop View vETLFactOrders;
go
	If Exists(Select * from Sys.objects where Name = 'pETLSyncFactOrders')
   Drop Procedure pETLSyncFactOrders;

--********************************************************************--
-- A) NOT NEEDED FOR INCREMENTAL LOADING: 
 --   Drop the FOREIGN KEY CONSTRAINTS and Clear the tables
--********************************************************************--

--********************************************************************--
-- B) Synchronize the Tables
--********************************************************************--

/****** [dbo].[DimProducts] ******/
go 
Create View vETLDimProducts
/* Author: RRoot
** Desc: Extracts and transforms data for DimProducts
** Change Log: When,Who,What
** 2018-01-17,RRoot,Created Sproc.
*/
As
SELECT 
	 [ProductID] = [ProductID]
	,[ProductName] = Cast(p.[Name] as nvarchar(50))
	,[StandardListPrice] = Cast([ListPrice] as decimal(18,4))
	,[ProductSubCategoryID] = p.[ProductSubcategoryID]
	,[ProductSubCategoryName] = Cast(ps.Name as nvarchar(50))
	,[ProductCategoryID] = ps.ProductCategoryID
	,[ProductCategoryName] = Cast(pc.Name as nvarchar(50))
  FROM [AdventureWorks_Basics].[dbo].[Products] as p
   JOIN [AdventureWorks_Basics].[dbo].[ProductSubcategory] as ps -- If you use a Full Join you will get parts without a SubCategories or ListPrice
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
   JOIN [AdventureWorks_Basics].[dbo].[ProductCategory] as pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
   --WHERE ListPrice <> 0 
   --AND ProductID in (Select ProductID from [AdventureWorks_Basics].[dbo].[SalesOrderDetail]) 
   --AND p.ProductSubcategoryID is Null -- Not Needed unless you use a Full Join
go
/* Testing Code:
 Select * From vETLDimProducts;
*/

go
Create Procedure pETLSyncDimProducts
/* Author: RRoot
** Desc: Updates data in DimProducts using the vETLDimProducts view
** Change Log: When,Who,What
** 2018-01-17,RRoot,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    -- NOTE: Performing the Update before an Insert makes the coding eaiser since there is only one current version of the data
    -- 1) For UPDATE: Change the EndDate and IsCurrent on any added rows 
		With ChangedProducts 
		As(
			Select ProductID, ProductName, StandardListPrice, ProductSubCategoryID, ProductSubCategoryName, ProductCategoryID, ProductCategoryName From vETLDimProducts
			Except
			Select ProductID, ProductName, StandardListPrice, ProductSubCategoryID, ProductSubCategoryName, ProductCategoryID, ProductCategoryName From DimProducts
			 Where IsCurrent = 1 -- Needed if the value is changed back to previous value
		)UPDATE [DWAdventureWorks_BasicsWithSCD].dbo.DimProducts 
		  SET EndDate = GetDate()
			 ,IsCurrent = 0
		   WHERE ProductID IN (Select ProductID From ChangedProducts)
		;

		/* TEST Examples: 
		 Update [AdventureWorks_Basics]..Products Set ListPrice = 1 Where ProductID = 680
		 Select * From [AdventureWorks_Basics]..Products Where ProductID = 680
		 Select * From DimProducts Where ProductID = 680

		 Update [AdventureWorks_Basics]..Products Set ListPrice = 1431.50 Where ProductID = 680
		 Select * From [AdventureWorks_Basics]..Products Where ProductID = 680
		 Select * From DimProducts Where ProductID = 680
		*/

    -- 2)For INSERT or UPDATES: Add new rows to the table
		With AddedORChangedProducts 
		As(
			Select ProductID, ProductName, StandardListPrice, ProductSubCategoryID, ProductSubCategoryName, ProductCategoryID, ProductCategoryName From vETLDimProducts
			Except
			Select ProductID, ProductName, StandardListPrice, ProductSubCategoryID, ProductSubCategoryName, ProductCategoryID, ProductCategoryName From DimProducts
             Where IsCurrent = 1 -- Needed if the value is changed back to previous value
		)INSERT INTO [DWAdventureWorks_BasicsWithSCD].dbo.DimProducts
        ([ProductID],[ProductName],[StandardListPrice],[ProductSubCategoryID],[ProductSubCategoryName],[ProductCategoryID],[ProductCategoryName],[StartDate],[EndDate],[IsCurrent])
         SELECT
           [ProductID]
          ,[ProductName]
		  ,[StandardListPrice]
          ,[ProductSubCategoryID]
		  ,[ProductSubCategoryName]	     
          ,[ProductCategoryID]
          ,[ProductCategoryName]
          ,[StartDate] = GetDate()
          ,[EndDate] = Null
          ,[IsCurrent] = 1
         FROM vETLDimProducts
         WHERE ProductID IN (Select ProductID From AddedORChangedProducts)
       ;

    -- 3) For Delete: Change the IsCurrent status to zero
		With DeletedProducts 
			As(
				Select ProductID, ProductName, StandardListPrice, ProductSubCategoryID, ProductSubCategoryName, ProductCategoryID, ProductCategoryName From DimProducts
				 Where IsCurrent = 1 -- We do not care about row already marked zero!
 				Except            			
      			Select ProductID, ProductName, StandardListPrice, ProductSubCategoryID, ProductSubCategoryName, ProductCategoryID, ProductCategoryName From vETLDimProducts
   		)UPDATE [DWAdventureWorks_BasicsWithSCD].dbo.DimProducts 
		  SET EndDate = GetDate()
			 ,IsCurrent = 0
		   WHERE ProductID IN (Select ProductID From DeletedProducts)
	   ;
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLSyncDimProducts;
 Print @Status;
 Select * From DimProducts Order By ProductID
*/


/****** [dbo].[DimCustomers] ******/
go 
Create View vETLDimCustomers
/* Author: RRoot
** Desc: Extracts and transforms data for DimCustomers
** Change Log: When,Who,What
** 2018-01-17,RRoot,Created Sproc.
*/
As
SELECT [CustomerId] = [CustomerID]
      ,[CustomerFullName] = Cast(([FirstName] +  ' ' + [LastName]) as nvarchar(100))
      ,[CustomerCityName] = Cast([City] as nvarchar(50))
      ,[CustomerStateProvinceName] = Cast([StateProvinceName] as nvarchar(50))
      ,[CustomerCountryRegionCode] = Cast([CountryRegionCode] as nvarchar(50))
      ,[CustomerCountryRegionName] = Cast([CountryRegionName] as nvarchar(50))
 FROM [AdventureWorks_Basics].[dbo].[Customer]
go
/* Testing Code:
 Select * From vETLDimCustomers;
*/

go
Create Procedure pETLSyncDimCustomers
/* Author: RRoot
** Desc: Inserts data into DimCustomers
** Change Log: When,Who,What
** 2018-01-17,RRoot,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    -- NOTE: Performing the Update before an Insert makes the coding eaiser since there is only one current version of the data
    -- 1) For UPDATE: Change the EndDate and IsCurrent on any added rows 
		With ChangedCustomers 
		As(
			Select CustomerId, CustomerFullName, CustomerCityName, CustomerStateProvinceName, CustomerCountryRegionCode, CustomerCountryRegionName From vETLDimCustomers
			Except
			Select CustomerId, CustomerFullName, CustomerCityName, CustomerStateProvinceName, CustomerCountryRegionCode, CustomerCountryRegionName From DimCustomers
             Where IsCurrent = 1 -- Needed if the value is changed back to previous value
		)UPDATE [DWAdventureWorks_BasicsWithSCD].[dbo].[DimCustomers]
		  SET EndDate = GetDate()
			 ,IsCurrent = 0
		   WHERE CustomerID IN (Select CustomerID From ChangedCustomers)
		;

    -- 2)For INSERT or UPDATES: Add new rows to the table
		With AddedORChangedCustomers 
		As(
			Select CustomerId, CustomerFullName, CustomerCityName, CustomerStateProvinceName, CustomerCountryRegionCode, CustomerCountryRegionName From vETLDimCustomers
			Except
			Select CustomerId, CustomerFullName, CustomerCityName, CustomerStateProvinceName, CustomerCountryRegionCode, CustomerCountryRegionName From DimCustomers
             Where IsCurrent = 1 -- Needed if the value is changed back to previous value
		)INSERT INTO [DWAdventureWorks_BasicsWithSCD].[dbo].[DimCustomers]
        ([CustomerId], [CustomerFullName], [CustomerCityName], [CustomerStateProvinceName], [CustomerCountryRegionCode], [CustomerCountryRegionName], [StartDate], [EndDate], [IsCurrent])
         SELECT
           [CustomerId]
		  ,[CustomerFullName]
		  ,[CustomerCityName]
		  ,[CustomerStateProvinceName]
		  ,[CustomerCountryRegionCode]
		  ,[CustomerCountryRegionName]
          ,[StartDate] = GetDate()
          ,[EndDate] = Null
          ,[IsCurrent] = 1
         FROM vETLDimCustomers
         WHERE CustomerID IN (Select CustomerID From AddedORChangedCustomers)
       ;

    -- 3) For Delete: Change the IsCurrent status to zero
		With DeletedCustomers 
			As(
			    Select CustomerId, CustomerFullName, CustomerCityName, CustomerStateProvinceName, CustomerCountryRegionCode, CustomerCountryRegionName From DimCustomers
				 Where IsCurrent = 1 -- We do not care about row already marked zero!
 				Except            			
			    Select CustomerId, CustomerFullName, CustomerCityName, CustomerStateProvinceName, CustomerCountryRegionCode, CustomerCountryRegionName From vETLDimCustomers
   		)UPDATE [DWAdventureWorks_BasicsWithSCD].[dbo].[DimCustomers]
		  SET EndDate = GetDate()
			 ,IsCurrent = 0
		   WHERE CustomerID IN (Select CustomerID From DeletedCustomers)
	   ;
      Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLSyncDimCustomers;
 Print @Status;
 Select * From DimCustomers
*/
go

go
ALTER Procedure pETLSyncDimCustomers
/* Author: RRoot
** Desc: Inserts data into DimCustomers
** Change Log: When,Who,What
** 2018-01-17,RRoot,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    -- NOTE: Performing the Update before an Insert makes the coding eaiser since there is only one current version of the data
 	    -- 1)For INSERT, UPDATES and DELETES
		Merge Into [dbo].[DimCustomers] as TargetTable
		Using [dbo].[vETLDimCustomers] as SourceTable
			ON TargetTable.[CustomerID] = SourceTable.[CustomerID]
		   AND TargetTable.[CustomerFullName] = SourceTable.[CustomerFullName]
		   AND TargetTable.[CustomerCityName] = SourceTable.[CustomerCityName]
		   AND TargetTable.[CustomerStateProvinceName] = SourceTable.[CustomerStateProvinceName]
		   AND TargetTable.[CustomerCountryRegionCode] = SourceTable.[CustomerCountryRegionCode]
		   AND TargetTable.[CustomerCountryRegionName] = SourceTable.[CustomerCountryRegionName]
		   AND IsCurrent = 1 -- Needed if the value is changed back to previous value
		  When Not Matched -- If ANY column in the Source is not found the the Target  		    
		   Then INSERT ([CustomerId]
		               ,[CustomerFullName]
		               ,[CustomerCityName]
		               ,[CustomerStateProvinceName]
		               ,[CustomerCountryRegionCode]
		               ,[CustomerCountryRegionName]
		               ,[StartDate]
		               ,[EndDate]
		               ,[IsCurrent] 
					   )
			   VALUES (SourceTable.CustomerId
					  ,SourceTable.CustomerFullName
					  ,SourceTable.CustomerCityName
					  ,SourceTable.CustomerStateProvinceName
					  ,SourceTable.CustomerCountryRegionCode
					  ,SourceTable.CustomerCountryRegionName
					  ,GetDate()
					  ,Null
					  ,1
					  )
			When Not Matched By Source
			 Then -- At least one Value is in the Target table, but not in the source table so...
			  UPDATE 
				 SET TargetTable.EndDate = GetDate() 
					,TargetTable.IsCurrent = 0
		; -- The merge statement demands a semicolon at the end!
		/* TEST Examples: 
		 Update [AdventureWorks_Basics]..Customer Set FirstName = 'JOHN' Where CustomerID = 11000
		 Select * From [AdventureWorks_Basics]..Customer Where CustomerID = 11000
		 Select * From DimCustomers Where CustomerID = 11000

		 Update [AdventureWorks_Basics]..Customer Set FirstName = 'Jon' Where CustomerID = 11000
		 Select * From [AdventureWorks_Basics]..Customer Where CustomerID = 11000
		 Select * From DimCustomers Where CustomerID = 11000
		*/
      Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLSyncDimCustomers;
 Print @Status;
 Select * From DimCustomers
*/
go


/****** [dbo].[DimDates] ******/
Create Procedure pETLFillDimDates
/* Author: RRoot
** Desc: Inserts data into DimDates
** Change Log: When,Who,What
** 2018-01-17,RRoot,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --	  
      --Delete From DimDates; -- Clears table data with the need for dropping FKs
	  If ((Select Count(*) From DimDates) = 0)
	  Begin
		  Declare @StartDate datetime = '01/01/2000' --< NOTE THE DATE RANGE!
		  Declare @EndDate datetime = '12/31/2010' --< NOTE THE DATE RANGE! 
		  Declare @DateInProcess datetime  = @StartDate
		  -- Loop through the dates until you reach the end date
		  While @DateInProcess <= @EndDate
		   Begin
		   -- Add a row into the date dimension table for this date
		   Insert Into DimDates 
		   ( [DateKey], [FullDate], [FullDateName], [MonthID], [MonthName], [YearID], [YearName] )
		   Values ( 
			 Cast(Convert(nVarchar(50), @DateInProcess, 112) as int) -- [DateKey]
			,@DateInProcess -- [FullDate]
			,DateName(weekday, @DateInProcess) + ', ' + Convert(nVarchar(50), @DateInProcess, 110) -- [FullDateName]  
			,Cast(Left(Convert(nVarchar(50), @DateInProcess, 112), 6) as int)  -- [MonthID]
			,DateName(month, @DateInProcess) + ' - ' + DateName(YYYY,@DateInProcess) -- [MonthName]
			,Year(@DateInProcess) -- [YearID] 
			,Cast(Year(@DateInProcess ) as nVarchar(50)) -- [YearName] 
			)  
		   -- Add a day and loop again
		   Set @DateInProcess = DateAdd(d, 1, @DateInProcess)
		   End -- While
	   End -- If
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLFillDimDates;
 Print @Status;
 Select * From DimDates;
*/
go

/****** [dbo].[FactOrders] ******/
go 
Create View vETLFactOrders
/* Author: RRoot
** Desc: Extracts and transforms data for FactOrders
** Change Log: When,Who,What
** 2018-01-17,RRoot,Created Sproc.
*/
As
SELECT
  [SalesOrderID] = soh.[SalesOrderID]
 ,[SalesOrderDetailID] = [SalesOrderDetailID]
 ,[OrderDate]
 ,[OrderDateKey] = Cast(Convert(nvarchar(50), [OrderDate], 112) as int)
 ,soh.[CustomerID]
 ,[CustomerKey] = dc.CustomerKey
 ,sod.[ProductID] 
 ,[ProductKey] = dp.ProductKey
 ,[OrderQty] = Cast([OrderQty] as Int)
 ,[ActualUnitPrice] = Cast([UnitPrice] as decimal(18,4))
 FROM [AdventureWorks_Basics].[dbo].[SalesOrderHeader] as soh
 JOIN [AdventureWorks_Basics].[dbo].[SalesOrderDetail] as sod
  ON soh.SalesOrderID = sod.SalesOrderID
 JOIN [DWAdventureWorks_BasicsWithSCD].[dbo].[DimCustomers] as dc
  ON soh.CustomerID = dc.CustomerId
 JOIN [DWAdventureWorks_BasicsWithSCD].[dbo].[DimProducts] as dp
  ON sod.ProductID = dp.ProductID
 WHERE dc.IsCurrent = 1 AND dp.IsCurrent = 1 --<IMPORTANT: If you do not add this you will get multiple rows if the FactTable is updated!
 ;
go
/* Testing Code:
 Select * From vETLFactOrders;
*/

go
Create Procedure pETLSyncFactOrders
/* Author: RRoot
** Desc: Inserts data into FactOrders
** Change Log: When,Who,What
** 2018-01-17,RRoot,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
	    -- 1)For INSERT, UPDATES and DELETES
		Merge Into [dbo].[FactSalesOrders] as TargetTable
		Using [dbo].[vETLFactOrders] as SourceTable
			ON TargetTable.[SalesOrderID] = SourceTable.[SalesOrderID] -- This value will not change in my design
		   AND TargetTable.[SalesOrderDetailID] = SourceTable.[SalesOrderDetailID] -- This value will not change in my design 
		   --AND TargetTable.[OrderDateKey] = SourceTable.[OrderDateKey] -- If this is added, the value will not change in my design
		   AND TargetTable.[CustomerKey] = SourceTable.[CustomerKey] -- If this is added, the value will not change in my design 
		   AND TargetTable.[ProductKey] = SourceTable.[ProductKey] -- If this is added, the value will not change in my design
		  When Not Matched -- The IDs and Keys in the Source is not found the the Target
		   Then INSERT ([SalesOrderID]
				       ,[SalesOrderDetailID]
				       ,[OrderDateKey]
				       ,[CustomerKey]
				       ,[ProductKey]
				       ,[OrderQty]
				       ,[ActualUnitPrice]
					   )
			   VALUES (SourceTable.[SalesOrderID]
					  ,SourceTable.[SalesOrderDetailID]
					  ,SourceTable.[OrderDateKey]
					  ,SourceTable.[CustomerKey]  
					  ,SourceTable.[ProductKey] 
					  ,SourceTable.[OrderQty]  
					  ,SourceTable.[ActualUnitPrice]
					  )
		  When Matched -- When all the IDs and Keys match for the row currently being looked 
			    AND (SourceTable.[OrderQty] <> TargetTable.[OrderQty]  -- if [OrderQty] does not match...
			    OR   SourceTable.[ActualUnitPrice] <> TargetTable.[ActualUnitPrice] -- or [ActualUnitPrice] does not match
				OR   TargetTable.[OrderDateKey] <> SourceTable.[OrderDateKey] --< Not a great option, but this is an example of how a Sales Order Header value could change.
			     )
		   Then UPDATE -- It knows your target, so you dont specify the FactOrders
				 SET  TargetTable.[OrderQty] = SourceTable.[OrderQty] 
					, TargetTable.[ActualUnitPrice] = SourceTable.[ActualUnitPrice]
					, TargetTable.[OrderDateKey] = SourceTable.[OrderDateKey] --< Not a great option, but this is an example of how a Sales Order Header value could change.
			When Not Matched By Source
			 Then -- The SalesOrderID and SalesOrderDetailID is in the Target table, but not the source table
			  DELETE
		; -- The merge statement demands a semicolon at the end!
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLSyncFactOrders;
 Print @Status;
 Select * From FactSalesOrders Where SalesOrderID = 43971;
*/
go

--********************************************************************--
-- C)  NOT NEEDED FOR INCREMENTAL LOADING: Re-Create the FOREIGN KEY CONSTRAINTS
--********************************************************************--


--********************************************************************--
-- D) Review the results of this script
--********************************************************************--
go
Declare @Status int = 0;
Exec @Status = pETLSyncDimProducts;
Select [Object] = 'pETLSyncDimProducts', [Status] = @Status;

Exec @Status = pETLSyncDimCustomers;
Select [Object] = 'pETLSyncDimCustomers', [Status] = @Status;

Exec @Status = pETLFillDimDates;
Select [Object] = 'pETLFillDimDates', [Status] = @Status;

Exec @Status = pETLSyncFactOrders;
Select [Object] = 'pETLFillFactOrders', [Status] = @Status;

go
Select * from [dbo].[DimProducts];
Select * from [dbo].[DimCustomers];
Select * from [dbo].[DimDates];
Select * from [dbo].[FactSalesOrders] Order By 1;