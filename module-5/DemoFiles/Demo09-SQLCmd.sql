--*************************************************************************--
-- Title: Automate creating a Staging table
-- Author: RRoot
-- Desc: This file creates a Demo database and staging table.
-- Change Log: When,Who,What
-- 2021-08-04,RRoot,Created File
--**************************************************************************--
Use TempDB;
go

Create or Alter Proc pSelXMLJobHistories
--*************************************************************************--
-- Desc: This sproc gets report data about job histories
-- Code borrowed from https://www.mssqltips.com/sqlservertip/2850/querying-sql-server-agent-job-history-data/
-- Change Log: When,Who,What
-- 2021-08-04,RRoot,Created File
--**************************************************************************--
As 
 Begin
  Set NoCount On
  Select 
   Job.name as 'JobName',
   msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
   ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) 
           as 'RunDurationMinutes'
  From msdb.dbo.sysjobs as Job 
  INNER JOIN msdb.dbo.sysjobhistory as hist 
   ON job.job_id = hist.job_id 
  Where job.enabled = 1   --Only Enabled Jobs
  Order by JobName, RunDateTime desc
  For XML Auto, Elements, Root('JobHistories');
End 
go
Exec pSelXMLJobHistories;