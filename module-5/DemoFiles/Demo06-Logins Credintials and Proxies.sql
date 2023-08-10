--*************************************************************************--
-- Title: SQL Agent Proxies Demo
-- Author: RRoot
-- Desc: This file creates a login, credintial, and a proxy.
-- Change Log: When,Who,What
-- 2021-08-04,RRoot,Created File
--**************************************************************************--
USE [master]
GO
CREATE LOGIN [RRLAPTOP1\Admin] 
 FROM WINDOWS 
  WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [RRLAPTOP1\Admin]
GO
CREATE CREDENTIAL [Credential for Python Scripts] 
 WITH IDENTITY = N'RSLaptop\Admin'
GO
EXEC msdb.dbo.sp_add_proxy 
 @proxy_name=N'OS for Python Scripts'
,@credential_name=N'Credential for Python Scripts'
,@enabled=1
GO

EXEC msdb.dbo.sp_grant_proxy_to_subsystem 
 @proxy_name=N'OS for Python Scripts'
,@subsystem_id=3
GO

EXEC msdb.dbo.sp_grant_proxy_to_subsystem 
 @proxy_name=N'OS for Python Scripts'
,@subsystem_id=12
GO
