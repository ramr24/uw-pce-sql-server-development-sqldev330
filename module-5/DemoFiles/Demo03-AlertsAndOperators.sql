--*************************************************************************--
-- Title: SQL Agent Operators and Alerts Demo
-- Author: RRoot
-- Desc: This file creates an operator and an alert.
-- Change Log: When,Who,What
-- 2021-08-04,RRoot,Created File
--**************************************************************************--
Use MSDB;
go
EXEC msdb.dbo.sp_add_operator @name=N'AdminTeam', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=80000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=80000, 
		@sunday_pager_end_time=180000, 
		@pager_days=65, 
		@email_address=N'ATeam@myCo.com', 
		@pager_address=N'ATeamOnDuty@myCo.com', 
		@category_name=N'[Uncategorized]'
GO

EXEC msdb.dbo.sp_add_alert @name=N'Fire on Northwind Log Full', 
		@message_id=9002, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=0, 
		@database_name=N'Northwind', 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO


EXEC dbo.sp_add_notification  
 @alert_name = N'Fire on Northwind Log Full',  
 @operator_name = N'AdminTeam',  
 @notification_method = 3 ;  
GO 

-- Note: These views do not show in the tree --
Select * From msdb.dbo.sysoperators;
Select * From msdb.dbo.sysalerts;
Select * From msdb.dbo.sysnotifications;
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-tables/dbo-sysnotifications-transact-sql?