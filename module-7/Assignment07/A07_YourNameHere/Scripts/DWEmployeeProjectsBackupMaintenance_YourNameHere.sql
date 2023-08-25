--*************************************************************************--
-- Title: DWEmployeeProjects Backup Maintenance
-- Author: RRoot
-- Desc: This file creates several Backup maintenance objects.
-- Change Log: When,Who,What
-- 2021-018-19,RRoot,Created File
--**************************************************************************--
Use TempDB
go
Create or Alter Proc pMaintDWEmployeeProjectsFullBackup
--*************************************************************************--
-- Desc:This Sproc is for DWEmployeeProjectsFullBackup Maintenance. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As
Begin
  Declare @RC int = 1;
  Begin Try

    -- TODO ADD Code Here

    Exec pInsMaintLog
	        @MaintAction = 'pMaintDWEmployeeProjectsFullBackup'
	       ,@MaintLogMessage = 'DWEmployeeProjects Full Backup: Success';
    Set @RC = 1;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	  Exec pInsMaintLog 
	        @MaintAction = 'pMaintDWEmployeeProjectsFullBackup'
	       ,@MaintLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

Exec pMaintDWEmployeeProjectsFullBackup
Select * From vMaintLog


go
Create or Alter Proc pMaintDWEmployeeProjectsFullBackupValidator
--*************************************************************************--
-- Desc:This Sproc is for Restore validation. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As
Begin
  Declare @RC int = 1;
  Begin Try
    --TODO: Add Code Here


    -- Validate rowcounts --
    Declare @CurrentCount int
    Declare @RestoredCount int; 
    Declare @CurrentDateTime DateTime = GetDate()
    
    -- Test Row Counts for Employees
    Select @CurrentCount = count(*) From DWEmployeeProjects.dbo.DimEmployees;
    Select @RestoredCount = count(*) From [DWEmployeeProjectsReadOnly].dbo.DimEmployees;
    If (@CurrentCount = @RestoredCount)        
      Exec pInsValidationLog
               @ValidationDateTime = @CurrentDateTime
              ,@ValidationObject = 'pMaintDWEmployeeProjectsFullBackupValidator'
              ,@ValidationStatus = 'Success'
              ,@ValidationMessage ='DimEmployee Row Count Test'
    Else
      Exec pInsValidationLog 
               @ValidationDateTime = @CurrentDateTime
              ,@ValidationObject = 'pMaintDWEmployeeProjectsFullBackupValidator'
              ,@ValidationStatus = 'Failed'
              ,@ValidationMessage ='DimEmployee Row Count Test'
   
    --TODO: Add Code Here
    -- Test Row Counts for DimProjects
    -- Test Row Counts for FactEmployeeProjects       
        
    -- Compare Data in DimEmployees --
    Declare @DuplicateCount int
    Select  @DuplicateCount = Count(*) 
            From 
            (Select * From DWEmployeeProjects.dbo.DimEmployees
             Except
             Select * From [DWEmployeeProjectsReadOnly].dbo.DimEmployees) as Results
    If @DuplicateCount = 0
         Exec pInsValidationLog 
                @ValidationDateTime = @CurrentDateTime
               ,@ValidationObject = 'pMaintDWEmployeeProjectsFullBackupValidator'
               ,@ValidationStatus = 'Success'
               ,@ValidationMessage ='DimEmployee Duplicate Test'
    Else
          Exec pInsValidationLog 
                @ValidationDateTime = @CurrentDateTime
               ,@ValidationObject = 'pMaintDWEmployeeProjectsFullBackupValidator'
               ,@ValidationStatus = 'Failed'
               ,@ValidationMessage ='DimEmployee Duplicate Test'

    -- TODO: Add Code Here
    -- Compare Data in DimProjects
    -- Compare Data in FactEmployeeProjects      

    Exec pInsMaintLog
	        @MaintAction = 'pMaintDWEmployeeProjectsFullBackupValidator'
	       ,@MaintLogMessage = 'pValidateRestore: Success';
    Set @RC = 1;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	  Exec pInsMaintLog
	        @MaintAction = 'pMaintDWEmployeeProjectsFullBackupValidator'
	       ,@MaintLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

-- Delete From MaintLog;
-- Delete From ValidationLog;
Exec pMaintDWEmployeeProjectsFullBackupValidator;
Select * From vMaintLog;
Select * From vValidationLog

