--*************************************************************************--
-- Title: DWEmployeeProjects Index Maintenance
-- Author: RRoot
-- Desc: This file creates several Index maintenance objects.
-- Change Log: When,Who,What
-- 2021-018-19,RRoot,Created File
--**************************************************************************--
Use [DWEmployeeProjects]
go
Create or Alter Proc pMaintDWEmployeeProjectsIndexes
--*************************************************************************--
-- Desc:This Sproc is for DWEmployeeProjects Indexes Maintenance. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As
Begin
  Declare @RC int = 1;
  Begin Try

    -- TODO: ADD Code Here


    Exec TempDB.dbo.pInsMaintLog
	        @MaintAction = 'pMaintDWEmployeeProjectsIndexes'
	       ,@MaintLogMessage = 'DWEmployeeProjects Index Recreation: Success';
    Set @RC = 1;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	  Exec TempDB.dbo.pInsMaintLog 
	        @MaintAction = 'pMaintDWEmployeeProjectsIndexes'
	       ,@MaintLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

Exec pMaintDWEmployeeProjectsIndexes
Select * From Tempdb.dbo.vMaintLog


