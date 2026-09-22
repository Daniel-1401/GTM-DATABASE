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

IF SCHEMA_ID(N'alimentacion') IS NULL
    THROW 51004, 'Reversión bloqueada: no existe el schema [alimentacion].', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Los procedimientos deben eliminarse antes de sus tablas, tipos tabla y schemas.
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ListarProductosPedidosPorNombre];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_MarcarReservasNoRecogidas];
    DROP PROCEDURE IF EXISTS [proximidad].[usp_ObtenerConfiguracionBeaconsSede];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_RevocarCodigoQRReservaPropia];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_EmitirCodigoQRReservaPropia];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ListarHistorialReservasPropias];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ObtenerResumenServicioHoyColaborador];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_CancelarReservaPropia];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_CrearReservaPropia];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ListarCalendarioReservableColaborador];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ListarPlanificacionesPlantilla];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ListarMenusConfiguracionPlantilla];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ActualizarMenuPlanificacion];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ReabrirPlanificacion];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ConsolidarPlanificacion];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_CerrarPlanificacion];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_PublicarPlanificacion];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_EliminarMenuPlanificacion];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ListarTiposServicio];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ActualizarNombreSedePlanificacion];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_EliminarPlanificacion];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_CrearMenusPlanificacionLote];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_CrearMenuPlanificacion];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_CrearPlanificacionBorrador];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ListarMenusPlanificacionPorTipoServicio];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ObtenerResumenPlanificacion];
    DROP PROCEDURE IF EXISTS [alimentacion].[usp_ListarPlanificaciones];
    DROP PROCEDURE IF EXISTS [auditoria].[usp_RegistrarErrorProcedimiento];

    -- Las vistas se eliminan antes que las tablas que consultan.
    DROP VIEW IF EXISTS [proximidad].[VistaMajorAreaBeacon];

    -- Orden inverso de las dependencias de claves foráneas.
    DROP TABLE IF EXISTS [alimentacion].[ValidacionEntrega];
    DROP TABLE IF EXISTS [alimentacion].[Entrega];
    DROP TABLE IF EXISTS [alimentacion].[CodigoQR];
    DROP TABLE IF EXISTS [alimentacion].[Reserva];
    DROP TABLE IF EXISTS [alimentacion].[CantidadConsolidadaMenu];
    DROP TABLE IF EXISTS [alimentacion].[ConsolidacionPlanificacion];
    DROP TABLE IF EXISTS [alimentacion].[Menu];
    DROP TABLE IF EXISTS [alimentacion].[Planificacion];
    DROP TABLE IF EXISTS [alimentacion].[VentanaRetiroServicio];
    DROP TABLE IF EXISTS [alimentacion].[TipoServicio];

    DROP TABLE IF EXISTS [proximidad].[BeaconAutorizado];
    DROP TABLE IF EXISTS [proximidad].[ConfiguracionBeacon];
    DROP TABLE IF EXISTS [proximidad].[MajorAreaBeacon];

    DROP TYPE IF EXISTS [alimentacion].[TipoMenuPlanificacionLoteCreacion];

    -- La infraestructura de auditoría fue creada por la migración 016.
    DROP TABLE IF EXISTS [auditoria].[ErrorProcedimiento];

    -- Solo se eliminan schemas que queden vacíos; objetos ajenos los preservan.
    IF SCHEMA_ID(N'alimentacion') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id = SCHEMA_ID(N'alimentacion'))
       AND NOT EXISTS (SELECT 1 FROM sys.table_types WHERE schema_id = SCHEMA_ID(N'alimentacion'))
        DROP SCHEMA [alimentacion];

    IF SCHEMA_ID(N'proximidad') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id = SCHEMA_ID(N'proximidad'))
       AND NOT EXISTS (SELECT 1 FROM sys.table_types WHERE schema_id = SCHEMA_ID(N'proximidad'))
        DROP SCHEMA [proximidad];

    IF SCHEMA_ID(N'auditoria') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id = SCHEMA_ID(N'auditoria'))
       AND NOT EXISTS (SELECT 1 FROM sys.table_types WHERE schema_id = SCHEMA_ID(N'auditoria'))
        DROP SCHEMA [auditoria];

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
