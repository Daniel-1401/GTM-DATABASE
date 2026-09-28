-- Reversión destructiva y protegida de una instancia hija del núcleo.
-- Ejecutar en modo SQLCMD proporcionando:
--   -v ConfirmarReversionNucleoUO=SI BaseDatosEsperada=<nombre-exacto>
-- La huella UO se valida antes de eliminar cualquier objeto.

:ON ERROR EXIT

SET XACT_ABORT ON;
SET NOCOUNT ON;

IF N'$(ConfirmarReversionNucleoUO)' <> N'SI'
    THROW 51093, N'Reversión bloqueada: falta ConfirmarReversionNucleoUO=SI.', 1;

IF NULLIF(N'$(BaseDatosEsperada)', N'') IS NULL
   OR DB_NAME() <> N'$(BaseDatosEsperada)'
    THROW 51094, N'Reversión bloqueada: la base actual no coincide con BaseDatosEsperada.', 1;

IF DB_ID() <= 4 OR DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
    THROW 51095, N'Reversión bloqueada: no se permite operar sobre una base de sistema.', 1;

IF SCHEMA_ID(N'organizacion') IS NULL
   OR SCHEMA_ID(N'rrhh') IS NULL
   OR SCHEMA_ID(N'seleccion') IS NULL
   OR OBJECT_ID(N'[organizacion].[ConfiguracionUnidadOrganizativa]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[EmpresaReferencia]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Sede]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Area]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Cargo]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[CargoSAP]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[CargoJefatura]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[RelacionLaboral]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[AsignacionOrganizacional]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[HorarioLaboral]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[VigenciaHorario]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[vw_SedeConsulta]', N'V') IS NULL
   OR OBJECT_ID(N'[organizacion].[vw_EstructuraOrganizacionalConsulta]', N'V') IS NULL
   OR OBJECT_ID(N'[organizacion].[vw_JerarquiaCargoConsulta]', N'V') IS NULL
   OR OBJECT_ID(N'[rrhh].[vw_ContextoOrganizacionalColaborador]', N'V') IS NULL
   OR OBJECT_ID(N'[seleccion].[Postulante]', N'U') IS NULL
   OR OBJECT_ID(N'[seleccion].[ArchivoPostulante]', N'U') IS NULL
   OR OBJECT_ID(N'[seleccion].[HistorialEstadoPostulante]', N'U') IS NULL
    THROW 51096, N'Reversión bloqueada: la huella estructural UO está incompleta.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.tables AS [Tabla]
    WHERE [Tabla].[schema_id] IN (SCHEMA_ID(N'organizacion'), SCHEMA_ID(N'rrhh'), SCHEMA_ID(N'seleccion'))
      AND NOT
      (
          ([Tabla].[schema_id] = SCHEMA_ID(N'organizacion')
           AND [Tabla].[name] IN (N'ConfiguracionUnidadOrganizativa', N'EmpresaReferencia', N'Sede', N'Area', N'Cargo', N'CargoSAP', N'CargoJefatura'))
          OR ([Tabla].[schema_id] = SCHEMA_ID(N'rrhh')
              AND [Tabla].[name] IN (N'RelacionLaboral', N'AsignacionOrganizacional', N'HorarioLaboral', N'VigenciaHorario'))
          OR ([Tabla].[schema_id] = SCHEMA_ID(N'seleccion')
              AND [Tabla].[name] IN (N'Postulante', N'ArchivoPostulante', N'HistorialEstadoPostulante'))
      )
)
    THROW 51097, N'Reversión bloqueada: existen tablas ajenas a la huella UO.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.objects AS [Objeto]
    WHERE [Objeto].[schema_id] IN (SCHEMA_ID(N'organizacion'), SCHEMA_ID(N'rrhh'), SCHEMA_ID(N'seleccion'))
      AND [Objeto].[is_ms_shipped] = 0
      AND NOT
      (
          [Objeto].[type] IN (N'U', N'C', N'D', N'F', N'PK', N'UQ')
          OR ([Objeto].[type] = N'V'
              AND
              (
                  ([Objeto].[schema_id] = SCHEMA_ID(N'organizacion')
                   AND [Objeto].[name] IN (N'vw_SedeConsulta', N'vw_EstructuraOrganizacionalConsulta', N'vw_JerarquiaCargoConsulta'))
                  OR ([Objeto].[schema_id] = SCHEMA_ID(N'rrhh')
                      AND [Objeto].[name] = N'vw_ContextoOrganizacionalColaborador')
              ))
      )
)
    THROW 51098, N'Reversión bloqueada: existen objetos ajenos a la huella UO.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.foreign_keys AS [Fk]
    INNER JOIN sys.objects AS [Referencia] ON [Referencia].[object_id] = [Fk].[referenced_object_id]
    INNER JOIN sys.objects AS [Dependiente] ON [Dependiente].[object_id] = [Fk].[parent_object_id]
    WHERE [Referencia].[schema_id] IN (SCHEMA_ID(N'organizacion'), SCHEMA_ID(N'rrhh'), SCHEMA_ID(N'seleccion'))
      AND [Dependiente].[schema_id] NOT IN (SCHEMA_ID(N'organizacion'), SCHEMA_ID(N'rrhh'), SCHEMA_ID(N'seleccion'))
)
    THROW 51099, N'Reversión bloqueada: existen dependencias externas a la huella UO.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DROP VIEW [rrhh].[vw_ContextoOrganizacionalColaborador];
    DROP VIEW [organizacion].[vw_JerarquiaCargoConsulta];
    DROP VIEW [organizacion].[vw_EstructuraOrganizacionalConsulta];
    DROP VIEW [organizacion].[vw_SedeConsulta];

    DROP TABLE [seleccion].[HistorialEstadoPostulante];
    DROP TABLE [seleccion].[ArchivoPostulante];
    DROP TABLE [seleccion].[Postulante];

    DROP TABLE [rrhh].[VigenciaHorario];
    DROP TABLE [rrhh].[HorarioLaboral];
    DROP TABLE [rrhh].[AsignacionOrganizacional];
    DROP TABLE [rrhh].[RelacionLaboral];

    DROP TABLE [organizacion].[CargoJefatura];
    DROP TABLE [organizacion].[CargoSAP];
    DROP TABLE [organizacion].[Cargo];
    DROP TABLE [organizacion].[Area];
    DROP TABLE [organizacion].[Sede];
    DROP TABLE [organizacion].[EmpresaReferencia];
    DROP TABLE [organizacion].[ConfiguracionUnidadOrganizativa];

    DROP SCHEMA [seleccion];
    DROP SCHEMA [rrhh];
    DROP SCHEMA [organizacion];

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
