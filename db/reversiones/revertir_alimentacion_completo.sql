-- Reversión integral y protegida del módulo Alimentación.
-- Ejecutar en modo SQLCMD proporcionando:
--   -v ConfirmarReversionAlimentacion=SI BaseDatosEsperada=<nombre-exacto>
-- Este script no elimina ni modifica tablas o schemas del núcleo GTM.

:ON ERROR EXIT

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- IF N'$(ConfirmarReversionAlimentacion)' <> N'SI'
--     THROW 51000, 'Reversión bloqueada: falta ConfirmarReversionAlimentacion=SI.', 1;
--
-- IF NULLIF(N'$(BaseDatosEsperada)', N'') IS NULL OR DB_NAME() <> N'$(BaseDatosEsperada)'
--     THROW 51001, 'Reversión bloqueada: la base actual no coincide con BaseDatosEsperada.', 1;
--
-- IF DB_ID() <= 4 OR DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
--     THROW 51002, 'Reversión bloqueada: no se permite operar sobre una base de sistema.', 1;
--
-- IF SCHEMA_ID(N'alimentacion') IS NULL
--     THROW 51003, 'Reversión bloqueada: no existe el schema esperado [alimentacion].', 1;

IF OBJECT_ID(N'[alimentacion].[ConfiguracionServicioHorario]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[VentanaRetiroServicio]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[BeaconAutorizado]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[ConfiguracionProximidadBeacon]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[Planificacion]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[Menu]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[ComponenteMenu]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[ConsolidacionPlanificacion]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[CantidadConsolidadaMenu]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[Reserva]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[CodigoQR]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[Entrega]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[ValidacionEntrega]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[RegistroIdempotencia]', N'U') IS NULL
 OR OBJECT_ID(N'[alimentacion].[EventoAuditoria]', N'U') IS NULL
    THROW 51004, 'Reversión bloqueada: la huella estructural completa de Alimentación no coincide.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.objects AS objeto
    WHERE objeto.schema_id = SCHEMA_ID(N'alimentacion')
      AND objeto.parent_object_id = 0
      AND objeto.type IN (N'U', N'V', N'P', N'FN', N'IF', N'TF', N'TR')
      AND objeto.name NOT IN
      (
          N'ConfiguracionServicioHorario', N'VentanaRetiroServicio',
          N'BeaconAutorizado', N'ConfiguracionProximidadBeacon',
          N'Planificacion', N'Menu', N'ComponenteMenu',
          N'ConsolidacionPlanificacion', N'CantidadConsolidadaMenu',
          N'Reserva', N'CodigoQR', N'Entrega', N'ValidacionEntrega',
          N'RegistroIdempotencia', N'EventoAuditoria'
      )
)
    THROW 51005, 'Reversión bloqueada: existen objetos no reconocidos dentro de [alimentacion].', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DROP TABLE [alimentacion].[EventoAuditoria];
    DROP TABLE [alimentacion].[RegistroIdempotencia];
    DROP TABLE [alimentacion].[Entrega];
    DROP TABLE [alimentacion].[ValidacionEntrega];
    DROP TABLE [alimentacion].[CodigoQR];
    DROP TABLE [alimentacion].[Reserva];
    DROP TABLE [alimentacion].[CantidadConsolidadaMenu];
    DROP TABLE [alimentacion].[ConsolidacionPlanificacion];
    DROP TABLE [alimentacion].[ComponenteMenu];
    DROP TABLE [alimentacion].[Menu];
    DROP TABLE [alimentacion].[Planificacion];
    DROP TABLE [alimentacion].[ConfiguracionProximidadBeacon];
    DROP TABLE [alimentacion].[BeaconAutorizado];
    DROP TABLE [alimentacion].[VentanaRetiroServicio];
    DROP TABLE [alimentacion].[ConfiguracionServicioHorario];
    DROP SCHEMA [alimentacion];

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
