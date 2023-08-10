SQLCmd -S localhost -E -o "C:\_SQL330\Demo09-JobHistory.xml" -Q "Exec TempDB.dbo.pSelXMLJobHistories" -h -1
rem remove pause for automation or it will hang the job! 
pause
