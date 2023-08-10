# Step 1) Create a new SQL Script
#  Use the following Code to create a test script
    If(Test-Path C:\BackupFiles) {
     Write-Host "Folder Ready"
    }
    Else {
     MD C:\BackupFiles
    }
    Backup-SqlDatabase -ServerInstance localhost `
    -Database Northwind -BackupFile C:\BackupFiles\NW.bak -Initialize
