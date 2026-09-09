-- Limpieza de datos: núcleo GTM
-- Motor objetivo: Microsoft SQL Server 2017
-- Alcance: elimina datos de las 15 tablas de catalogo, rrhh, organizacion e integracion.
-- Advertencia: operación destructiva. No ejecutarlo en producción.

SET XACT_ABORT ON;
SET NOCOUNT ON;

DECLARE @ConfirmarLimpieza BIT = 1;

IF @ConfirmarLimpieza <> 1
    THROW 51040, N'Operación cancelada. Establezca @ConfirmarLimpieza = 1 para eliminar los datos del núcleo.', 1;

IF OBJECT_ID(N'[rrhh].[JefaturaRelacionLaboral]', N'U') IS NULL
   OR OBJECT_ID(N'[integracion].[CuentaMicrosoftCorporativa]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Empresa]', N'U') IS NULL
   OR OBJECT_ID(N'[catalogo].[TipoDocumento]', N'U') IS NULL
    THROW 51041, N'Faltan tablas del núcleo. Aplique primero las migraciones 001 a 008.', 1;

BEGIN TRANSACTION;

DELETE FROM [rrhh].[JefaturaRelacionLaboral];
DELETE FROM [rrhh].[VigenciaHorario];
DELETE FROM [rrhh].[AsignacionOrganizacional];
DELETE FROM [rrhh].[RelacionLaboral];
DELETE FROM [integracion].[CuentaMicrosoftCorporativa];
DELETE FROM [rrhh].[DocumentoPersona];
DELETE FROM [rrhh].[Colaborador];
DELETE FROM [rrhh].[Persona];
DELETE FROM [rrhh].[HorarioLaboral];
DELETE FROM [organizacion].[Cargo];
DELETE FROM [organizacion].[Area];
DELETE FROM [organizacion].[Sede];
DELETE FROM [organizacion].[Empresa];
DELETE FROM [catalogo].[TipoJefatura];
DELETE FROM [catalogo].[TipoDocumento];

DBCC CHECKIDENT (N'[rrhh].[JefaturaRelacionLaboral]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[rrhh].[VigenciaHorario]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[rrhh].[AsignacionOrganizacional]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[rrhh].[RelacionLaboral]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[integracion].[CuentaMicrosoftCorporativa]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[rrhh].[DocumentoPersona]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[rrhh].[Colaborador]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[rrhh].[Persona]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[rrhh].[HorarioLaboral]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[organizacion].[Cargo]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[organizacion].[Area]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[organizacion].[Sede]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[organizacion].[Empresa]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[catalogo].[TipoJefatura]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[catalogo].[TipoDocumento]', RESEED, 0) WITH NO_INFOMSGS;

COMMIT TRANSACTION;
GO
