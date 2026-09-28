-- Reversión destructiva completa del núcleo corporativo de CO.
-- Ejecutar solo sobre una base creada exclusivamente con los scripts corporativos.

:ON ERROR EXIT

SET XACT_ABORT ON;
SET NOCOUNT ON;

-- Requiere modo SQLCMD: -v ConfirmarReversionNucleoCO=SI BaseDatosEsperada=<nombre-exacto>
IF N'$(ConfirmarReversionNucleoCO)' <> N'SI'
    THROW 51080, N'Reversion bloqueada: falta ConfirmarReversionNucleoCO=SI.', 1;

IF NULLIF(N'$(BaseDatosEsperada)', N'') IS NULL OR DB_NAME() <> N'$(BaseDatosEsperada)'
    THROW 51081, N'Reversion bloqueada: la base actual no coincide con BaseDatosEsperada.', 1;

IF DB_ID() <= 4 OR DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
    THROW 51082, N'Reversion bloqueada: no se permite operar sobre una base de sistema.', 1;

IF SCHEMA_ID(N'catalogo') IS NULL
   OR SCHEMA_ID(N'rrhh') IS NULL
   OR SCHEMA_ID(N'organizacion') IS NULL
   OR SCHEMA_ID(N'integracion') IS NULL
   OR SCHEMA_ID(N'auditoria') IS NULL
   OR OBJECT_ID(N'[catalogo].[TipoDocumento]', N'U') IS NULL
   OR OBJECT_ID(N'[catalogo].[EstadoCivil]', N'U') IS NULL
   OR OBJECT_ID(N'[catalogo].[Genero]', N'U') IS NULL
   OR OBJECT_ID(N'[catalogo].[Pais]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[UnidadOrganizativa]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Empresa]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[Persona]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[DocumentoPersona]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[Colaborador]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[vw_ColaboradorConsulta]', N'V') IS NULL
   OR OBJECT_ID(N'[integracion].[PersonalSAPStaging]', N'U') IS NULL
   OR TYPE_ID(N'[integracion].[TVP_RecepcionPersonalSAP]') IS NULL
   OR OBJECT_ID(N'[integracion].[usp_RegistrarPersonalSAPStaging]', N'P') IS NULL
   OR OBJECT_ID(N'[auditoria].[ErrorProcedimiento]', N'U') IS NULL
   OR OBJECT_ID(N'[auditoria].[usp_RegistrarErrorProcedimiento]', N'P') IS NULL
    THROW 51083, N'Reversion bloqueada: la huella estructural de CO no coincide.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DROP PROCEDURE [integracion].[usp_RegistrarPersonalSAPStaging];
    DROP PROCEDURE [auditoria].[usp_RegistrarErrorProcedimiento];
    DROP VIEW [rrhh].[vw_ColaboradorConsulta];
    DROP TYPE [integracion].[TVP_RecepcionPersonalSAP];
    DROP TABLE [integracion].[PersonalSAPStaging];
    DROP TABLE [auditoria].[ErrorProcedimiento];
    DROP TABLE [rrhh].[Colaborador];
    DROP TABLE [rrhh].[DocumentoPersona];
    DROP TABLE [rrhh].[Persona];
    DROP TABLE [organizacion].[Empresa];
    DROP TABLE [organizacion].[UnidadOrganizativa];
    DROP TABLE [catalogo].[Pais];
    DROP TABLE [catalogo].[Genero];
    DROP TABLE [catalogo].[EstadoCivil];
    DROP TABLE [catalogo].[TipoDocumento];

    IF SCHEMA_ID(N'organizacion') IS NOT NULL EXEC(N'DROP SCHEMA [organizacion]');
    IF SCHEMA_ID(N'rrhh') IS NOT NULL EXEC(N'DROP SCHEMA [rrhh]');
    IF SCHEMA_ID(N'catalogo') IS NOT NULL EXEC(N'DROP SCHEMA [catalogo]');
    IF SCHEMA_ID(N'integracion') IS NOT NULL EXEC(N'DROP SCHEMA [integracion]');
    IF SCHEMA_ID(N'auditoria') IS NOT NULL EXEC(N'DROP SCHEMA [auditoria]');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
