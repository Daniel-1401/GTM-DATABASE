-- Creación: núcleo corporativo / 001_crear_esquemas_corporativos
-- Motor objetivo: Microsoft SQL Server 2017
-- Alcance: instancia CO. No crea bases de datos ni objetos de USERMANAGEMENTCORP.

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF SCHEMA_ID(N'catalogo') IS NULL
    EXEC(N'CREATE SCHEMA [catalogo] AUTHORIZATION [dbo]');

IF SCHEMA_ID(N'rrhh') IS NULL
    EXEC(N'CREATE SCHEMA [rrhh] AUTHORIZATION [dbo]');

IF SCHEMA_ID(N'organizacion') IS NULL
    EXEC(N'CREATE SCHEMA [organizacion] AUTHORIZATION [dbo]');

COMMIT TRANSACTION;
GO
