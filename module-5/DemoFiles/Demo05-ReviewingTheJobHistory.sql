--*************************************************************************--
-- Title: Automate creating a Staging table
-- Author: RRoot
-- Desc: This file creates a Demo database and staging table.
-- Change Log: When,Who,What
-- 2018-02-07,RRoot,Created File
--**************************************************************************--
Use TempDB;
go

Select * From msdb.dbo.sysjobs;
Select * From msdb.dbo.sysjobhistory;

-- Use this to clear the jobhistory table
-- EXEC MSDB.dbo.sp_purge_jobhistory ;  
go

Create or Alter View vJobHistory
-- From Code on https://www.mssqltips.com/sqlservertip/2850/querying-sql-server-agent-job-history-data/
As

Select Top 1000000
 [JobName] = j.name 
,[StepName] = h.step_name
,[RunDateTime] = msdb.dbo.agent_datetime(run_date, run_time)
,[RunDurationSeconds] = h.run_duration
From msdb.dbo.sysjobs as j 
  Inner Join msdb.dbo.sysjobhistory as h 
    ON j.job_id = h.job_id 
Where j.enabled = 1 --Only Enabled Jobs
Order by JobName, RunDateTime desc

go
Select * From vJobHistory;