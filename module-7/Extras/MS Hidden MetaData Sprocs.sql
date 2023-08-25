--Looping by Table
--A few years ago, Microsoft introduced an undocumented stored procedure (Sproc) that will allow you to run code using the name of each table in a database. This is something that we have could do on your own by creating a SQL cursor, but it is nice to have it written for you! 
--The stored procedure is named “sp_msforeachtable” and it allows you to submit a text string for processing as shown here
sp_msforeachtable @Command1 = 'print  "?" '
Go
 

--Note that a question mark in double quotes is used as a placeholder which will be replaced with each table’s name when the Sproc is called. 
--Since there is a table named dbo.store in the database this Sproc executes the following code:
print '[dbo].[stores]'

--It does this for each user table if finds in the current database, but not system tables. 
--Speaking of system tables, you can use this Sproc to get meta data about your user tables easily. Here is an example:
sp_msforeachtable 
@Command1 = 'Select Object_Name(object_id), * 
	      From Sys.Columns Where Object_ID = Object_ID("?")'


--You can also use Microsoft’s stored procedures, like sp_help, with each table as follows:

sp_msforeachtable @Command1 = 'sp_help [?]'
Go

--Notice that sp_help is called for each table in the database and that I am using square brackets instead of a double quote. 
--This make this command evaluate as an object and not just a string, which can be important sometimes, though in this case it doesn’t matter.

--We create our own Sproc and pass in the table name as an argument value. 
--This next example uses the TSQL Exec command run a string of text characters as if it were a typed-out SQL statement.
Create Proc pSelTop2
(@TableName as nVarchar(100))
AS 
Declare @SQLCode nvarchar(100)= ' Select Top 2 * from  ' + @TableName
Exec(@SQLCode)


--Now I can use Microsoft’s stored procedure to execute my stored procedure like this:
sp_msforeachtable @Command1 = 'exec pSelTop2 "?" '
Go

--Each version of Microsoft SQL server comes with several new functions and Sprocs. In 2010, this included not only sp_msforeachtable, 
--but a similar stored procedure that loops through each database on the server.  
sp_msforeachdb @Command1 = 'sp_helpDB [?]'
Go

--Keep in mind that both are considered non-supported code. Relying on these in a production database may cause trouble 
--if one of Microsoft service pack changes the code. If you are consernd about this, remember that you can always create 
--your own stored procedure using Microsoft’s code, which can be displayed using sp_HelpText.
sp_helptext [sp_msforeachtable] 
