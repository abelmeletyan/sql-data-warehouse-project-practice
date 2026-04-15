/*
Comment about this code
*/

use master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name='WarehouseProject_Baraa')
BEGIN
	ALTER DATABASE WarehouseProject_Baraa SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE WarehouseProject_Baraa;
END

create database WarehouseProject_Baraa;
GO

use WarehouseProject_Baraa;
GO

create schema Bronze;
GO
create schema Silver;
GO
create schema Gold;
GO
