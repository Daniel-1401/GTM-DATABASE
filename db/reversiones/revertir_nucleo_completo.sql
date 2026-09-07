-- Reversión integral del núcleo GTM.
-- Requiere SQLCMD -v ConfirmarReversion=SI BaseDatosEsperada="<nombre-exacto>".
-- Destruye todos los objetos y datos creados por las migraciones 001..008.

:ON ERROR EXIT

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- IF UPPER(N'$(ConfirmarReversion)') <> N'SI'
--     THROW 51099, N'Reversión bloqueada. Use ConfirmarReversion=SI tras la aprobación humana correspondiente.', 1;
--
-- DECLARE @BaseDatosEsperada SYSNAME = NULLIF(LTRIM(RTRIM(N'$(BaseDatosEsperada)')), N'');
--
-- IF @BaseDatosEsperada IS NULL OR @BaseDatosEsperada = N'$(BaseDatosEsperada)'
--     THROW 51098, N'Reversión bloqueada. Debe declarar BaseDatosEsperada con el nombre exacto de la base autorizada.', 1;
--
-- IF DB_ID() <= 4
--     THROW 51097, N'Reversión bloqueada sobre una base de sistema.', 1;
--
-- IF DB_NAME() COLLATE Latin1_General_100_BIN2 <> @BaseDatosEsperada COLLATE Latin1_General_100_BIN2
--     THROW 51096, N'La conexión actual no apunta a BaseDatosEsperada.', 1;

IF SCHEMA_ID(N'catalogo') IS NULL
   OR SCHEMA_ID(N'rrhh') IS NULL
   OR SCHEMA_ID(N'organizacion') IS NULL
   OR SCHEMA_ID(N'integracion') IS NULL
   OR OBJECT_ID(N'[catalogo].[TipoDocumento]', N'U') IS NULL
   OR OBJECT_ID(N'[catalogo].[TipoJefatura]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[Persona]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[Colaborador]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[DocumentoPersona]', N'U') IS NULL
   OR OBJECT_ID(N'[integracion].[CuentaMicrosoftCorporativa]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Empresa]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Sede]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Area]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Cargo]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[RelacionLaboral]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[AsignacionOrganizacional]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[HorarioLaboral]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[VigenciaHorario]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[JefaturaRelacionLaboral]', N'U') IS NULL
    THROW 51095, N'La base no contiene la huella estructural completa de las migraciones 001..008.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DROP TABLE IF EXISTS [rrhh].[JefaturaRelacionLaboral];
    DROP TABLE IF EXISTS [rrhh].[VigenciaHorario];
    DROP TABLE IF EXISTS [rrhh].[HorarioLaboral];
    DROP TABLE IF EXISTS [rrhh].[AsignacionOrganizacional];
    DROP TABLE IF EXISTS [rrhh].[RelacionLaboral];
    DROP TABLE IF EXISTS [organizacion].[Cargo];
    DROP TABLE IF EXISTS [organizacion].[Area];
    DROP TABLE IF EXISTS [organizacion].[Sede];
    DROP TABLE IF EXISTS [organizacion].[Empresa];
    DROP TABLE IF EXISTS [integracion].[CuentaMicrosoftCorporativa];
    DROP TABLE IF EXISTS [rrhh].[DocumentoPersona];
    DROP TABLE IF EXISTS [rrhh].[Colaborador];
    DROP TABLE IF EXISTS [rrhh].[Persona];
    DROP TABLE IF EXISTS [catalogo].[TipoJefatura];
    DROP TABLE IF EXISTS [catalogo].[TipoDocumento];

    IF SCHEMA_ID(N'integracion') IS NOT NULL EXEC(N'DROP SCHEMA [integracion]');
    IF SCHEMA_ID(N'organizacion') IS NOT NULL EXEC(N'DROP SCHEMA [organizacion]');
    IF SCHEMA_ID(N'rrhh') IS NOT NULL EXEC(N'DROP SCHEMA [rrhh]');
    IF SCHEMA_ID(N'catalogo') IS NOT NULL EXEC(N'DROP SCHEMA [catalogo]');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
