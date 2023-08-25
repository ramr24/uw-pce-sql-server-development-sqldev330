USE [master]
GO

-- Now to allow the Office 2007+ connections you have to install the supporing file:
AccessDatabaseEngine.exe
OR
AccessDatabaseEngine_x64.exe


-- You can query remote data directly from as SQL Query but you need to turn
-- a couple of setting on before you try.

-- You can see some of the settings using:
Exec sp_configure
Go
Exec sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
Exec sp_configure
Go


-- Then to you need to configure SQL Server with a couple of other settings:
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' , N'AllowInProcess' , 1
GO
RECONFIGURE;
GO

EXEC master . dbo. sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' , N'DynamicParameters' , 1
GO
RECONFIGURE;
GO

sp_configure 'Ad Hoc Distributed Queries', 1;
GO
RECONFIGURE;
GO

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Note, you still may have to restart SQL Server before this will take effect!
AND you may have to reboot Windows as well since the supporting dlls get 
locked sometimes!
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

/***************************************/
 -- OPENROWSET 
/***************************************/

-- You can also query Excel with the OpenRowSet command.
SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0;Database=C:\ExternalData\Book1.xlsx;HDR=Yes','Select * from [Sheet1$]')

-- Note that the HDR parameter indicates that one row is a header. 
SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0;Database=C:\ExternalData\Book1.xlsx;HDR=No','Select * from [Sheet1$]')

-- You can also query a named range of data.
SELECT * FROM OPENROWSET(
 'Microsoft.ACE.OLEDB.12.0'
,'Excel 12.0;Database=C:\ExternalData\Book1.xlsx;HDR=Yes'
,'Select * from [ListOfNames]'
)



-- You can also query a table from a Access Database.
SELECT * FROM OPENROWSET(
'Microsoft.ACE.OLEDB.12.0'
,'C:\ExternalData\Northwind.accdb'
;'admin'
;'',Products
)

-- This will also work to Join data between Access and SQL Server
With AccessData
AS
(
		SELECT * FROM OPENROWSET(
		'Microsoft.ACE.OLEDB.12.0'
		,'C:\ExternalData\Northwind.accdb'
		;'admin'
		;'',Products
		)
) 
SELECT 
  A.[Product Code]
, A.[Product Name]
, S.OrderID, S.Quantity 
FROM AccessData as A
JOIN Northwind.dbo.[Order Details] as S
	On A.ID = S.ProductID


/***************************************/
 -- Importing data
 /***************************************/

SELECT * 
Into #TempTableCustomers
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0;Database=C:\ExternalData\Book1.xlsx;HDR=Yes','Select * from [ListOfNames]')
Go
Select * from #TempTableCustomers



/***************************************/
 -- LinkedServers  
/***************************************/

/****** Add a LinkedServer [EXCELDEMO] ******/
If Exists (  Select * from SysServers Where srvName = 'EXCELDEMO'  )
	Begin
		/****** Remove a LinkedServer ******/
		EXEC master.dbo.sp_dropserver @server=N'EXCELDEMO', @droplogins='droplogins'
	End

EXEC master.dbo.sp_addlinkedserver 
  @server = N'EXCELDEMO'
, @srvproduct=N'Excel'
, @provider=N'Microsoft.ACE.OLEDB.12.0'
, @datasrc=N'C:\ExternalData\Book1.xlsx'
, @provstr=N'Excel 12.0'
Go

/* Set security to the linked server */
EXEC master.dbo.sp_addlinkedsrvlogin 
@rmtsrvname=N'EXCELDEMO'
,@useself=N'true' -- True will let you use your current logon for access
,@locallogin=NULL
,@rmtuser=NULL
,@rmtpassword=NULL
GO

-- You treat a Worksheet as if it were a table
select * from [EXCELDEMO]...[Sheet1$]
Go
-- However, you can also ask for just a range of its data
select * from openquery([EXCELDEMO] , 'SELECT * FROM [Sheet1$A2:C4]')
Go

-- And you can use a Named Range
Select * from [EXCELDEMO]...[ListOfNames]
Go

-- You can execute an UPDATE pass-through query against the linked server
UPDATE OPENQUERY ([EXCELDEMO], 'SELECT Name FROM [ListOfNames] WHERE CustomerId = 1') SET name = 'Robert';

-- Or an INSERT pass-through query
INSERT OPENQUERY ([EXCELDEMO], 'SELECT CustomerID, Name FROM [ListOfNames]') VALUES (4, 'NewName');

-- and a DELETE pass-through query
DELETE OPENQUERY ([EXCELDEMO], 'SELECT Name FROM [ListOfNames] WHERE Name = ''NewName''');
-- HOWEVER: "Deleting data in a linked table is not supported by this ISAM.".