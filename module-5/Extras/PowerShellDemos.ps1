<#
*************************************************************************
 Title: Module 08 - Automation with PowerShell Code
 Author: RRoot
 Desc: This file demonstrates how you can use PowerShell code with SQL Server.
 Change Log: When,Who,What
 2018-02-13,RRoot,Created File
**************************************************************************
#>

# The PowerShell allows you to use OS and .NET commands directly from a PowerShell Script

# There are a lot of versions and most articles are on ver 1 or 2, but since newer versions
# are backward compatible  that is just fine!

$Host.Version

<#
"Built on the .NET Framework, PowerShell is a task-based command-line shell 
and scripting language; it is designed specifically for system administrators 
and power-users, to rapidly automate the administration of multiple operating 
systems (Linux, macOS, Unix, and Windows) and the processes related to the applications 
that run on those operating systems." 
(https:#docs.microsoft.com/en-us/powershell/scripting/powershell-scripting?view=powershell-6, 2017)
#>

# [PS Commands] #################################################################
#PS code use a Verb-Object command pattern

#To "Print" data
Write-Host "Test"
Write-Host 'Test'
Write-Host Test
Get-Help Write-Host


# [Using OS Commands] ##################################################################
#A lot of Command Shell Commands are included in PS
<#
Using a mechanism called aliasing, Windows PowerShell allows users to refer to 
commands by alternate names. Aliasing allows users with experience in other shells to reuse 
common command names that they already know to perform similar operations in Windows PowerShell.
(https://docs.microsoft.com/en-us/powershell/scripting/getting-started/fundamental/using-familiar-command-names?view=powershell-6. 2017)
#>

#To clear the "Results Pane"
cls # This is really an alias for Clear-Host
Clear-Host
Get-Alias Cls
Get-Alias MD
Get-Alias del

cls # You can use OS command as if you were typing into a Command Prompt
DIR C:\DataToProcess

cls # You also use the PS Get-ChildItem
Get-Alias Dir
Get-ChildItem C:\DataToProcess

# [Using Conditions] #################################################################
# https://ss64.com/ps/syntax-compare.html

cls #using the standard IF
if (4 -eq 5) {Get-ChildItem C:\DataToProcess}

#using the standard IF-Else
if (4 -eq 5) {Get-ChildItem C:\DataToProcess}
else { Write-Host "Not Equal" }

if (4 -ne 5) {Get-ChildItem C:\DataToProcess}

# [Creating Folders] ##################################################################

cls #Make a folder
if (4 -ne 5) {
MD C:\DataToProcessZZZ
Get-ChildItem C:\DataToProcessZZZ
}

cls #Delete a folder
Remove-Item C:\DataToProcessZZZ


# [Error Handling] ##################################################################
cls # This works a lot like it does in SQL, C#, Python, etc.
try{$x = 4/0 }
catch {Write-Host $Error[0]}


cls # However, some errors do not throw a "terminating" error by default!
# https://kevinmarquette.github.io/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/
Try{
Remove-Item C:\DataToProcessZZZ 
}
Catch
{Write-Host $Error[0]}

# To force the terminating error use use this code
Try{
Remove-Item C:\DataToProcessZZZ -ErrorAction Stop
}
Catch
{Write-Host $Error[0] }


# [Writing Data to Files] ##################################################################
# Of course you can write to data to a file
# http://www.computerperformance.co.uk/powershell/powershell_file_outfile.htm

cls # Writing to files
Add-Content 'C:\DataToProcess\PSData.txt' 'Test Data'
#Or use "piping" 
Get-Date | Set-Content 'C:\DataToProcess\PSData.txt' 
#Or use "piping" 
Get-Date | Out-File 'C:\DataToProcess\PSData.txt'
#Or use "Appending" 
Get-Date | Out-File 'C:\DataToProcess\PSData.txt' -Append


# [Work with SQL Server] ##################################################################
# Like the SQLCmd application, you can use PS to process SQL code and data


cls #You can see what installation of SQL Server are on a PC by looking in the Registry
CD hklm:
dir “HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names”
CD C:

cls #You can use the Invoke-SqlCmd command-let(cmdlet) to access an instance of SQL Server
Get-Help Invoke-Sqlcmd

cls #SQLCmd.exe -E -S .\sql2017 -Q "Select ProductName, UnitPrice From Northwind.dbo.Products"
Invoke-Sqlcmd -ServerInstance .\sql2017 -Query "Select ProductName, UnitPrice From Northwind.dbo.Products"

cls #A back-tick is used for the line-continuation character (needs a space before but Never after the `)
Invoke-Sqlcmd  `
-ServerInstance .\sql2017 `
-Query "Select ProductName, UnitPrice From Northwind.dbo.Products"

cls #You can output the results to a text file
Invoke-Sqlcmd  `
-ServerInstance .\sql2017 `
-Query "Select ProductName, UnitPrice From Northwind.dbo.Products"

cls #You can output the results to a text file
Invoke-Sqlcmd  `
-ServerInstance .\sql2017 `
-Query "Select ProductName, UnitPrice From Northwind.dbo.Products" `
| Out-File "C:\DataToProcess\PSData.txt"

cls #You can connect to different servers of course
Invoke-Sqlcmd `
-ServerInstance .\sql2017 `
-Query "Select @@SERVERNAME as 'Server Name', @@Version as 'Server Version'"

Invoke-Sqlcmd `
  -ServerInstance . `
  -Query "Select @@SERVERNAME as 'Server Name', @@Version as 'Server Version'" 

Invoke-Sqlcmd `
-ServerInstance is-root01.ischool.uw.edu `
-Username info340 `
-Password sql `
-Query "Select @@SERVERNAME as 'Server Name', @@Version as 'Server Version'"


<#
 You can also use ADO.NET code from Powershell to connect to databases
#>
cls #Configure your variables
$SQLServer = ".\sql2017" 
$SQLDBName = "Northwind" 
$SqlQuery = "Select ProductName, UnitPrice From Northwind.dbo.Products" 

#Create and configure a connection object
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection 
$SqlConnection.ConnectionString = "Server=$SQLServer;Database=$SQLDBName;Integrated Security=True"

#Create and configure a command object 
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand 
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection 

#Create and configure a DataAdapter/DataSet pair of objects
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd 
$DataSet = New-Object System.Data.DataSet
 
#Fill the DataSet with Data and close the connection to the database
$SqlAdapter.Fill($DataSet) 
$SqlConnection.Close()

#Process the data in the DataSet 
foreach ($row in $DataSet.Tables[0].Rows) {
 $row[0].ToString() + "," + $row[1].ToString()
}

#Save the data from the DataSet to an XML file
$DataSet.WriteXml('C:\DataToProcess\DataSetData.txt')

# [Reading Data From Files] ##################################################################
cls # You cannot read data from a text, but you can open file that will.
Get-Content C:\DataToProcess\ProductList.txt 
Get-Content C:\DataToProcess\DataSetData.txt 

# [Using Variables] #
<#
 Use this to create a SQL variable that uses the name
 Declare @ComputerName varchar(100) = Host_Name()
 Select @ComputerName + '\BobSmith' # This mixes static and dynamic data

 Use this to create a SQLCmd variable with SQL Server Data
 :SetVar ComputerName Host_Name()
 Select $(ComputerName) + '\BobSmith'
#>
cls #Read Data from a File into a variable and show the results
$FileData = Get-Content C:\DataToProcess\ProductList.txt 
$FileData[0]
$FileData[1]
$FileData[2]


#[Automating a SQLCmd Script] ##################################################################

# Step 1) Create a new SQL Script
#  Use the following Code to create a test script
    If(Test-Path C:\BackupFiles) {
     Write-Host "Folder Ready"
    }
    Else {
     MD C:\BackupFiles
    }
    Backup-SqlDatabase -ServerInstance .\sql2017 -Database Northwind -BackupFile C:\BackupFiles\NW.bak -Initialize

# Step 2) Test that it works
    # Open a PS window from the Windows Start menu and type in the following code
    Backup-SqlDatabase -ServerInstance .\sql2017 -Database Northwind -BackupFile C:\BackupFiles\NW.bak -Initialize


# Step 3) Automate it
# you can do this with 
    #   * A SQL Agent Operating System (CmdExec) step
    #   * A SSIS Execute Process Task
    #   * Windows Task Scheduler