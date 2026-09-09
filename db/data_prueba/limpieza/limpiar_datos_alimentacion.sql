-- Limpieza de datos: módulo Alimentación
-- Motor objetivo: Microsoft SQL Server 2017
-- Alcance: elimina datos de las 12 tablas del schema [alimentacion].
-- Advertencia: operación destructiva. No ejecutarlo en producción.

SET XACT_ABORT ON;
SET NOCOUNT ON;

DECLARE @ConfirmarLimpieza BIT = 0;

IF @ConfirmarLimpieza <> 1
    THROW 51030, N'Operación cancelada. Establezca @ConfirmarLimpieza = 1 para eliminar los datos de Alimentación.', 1;

IF OBJECT_ID(N'[alimentacion].[ValidacionEntrega]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[Entrega]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[CodigoQR]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[Reserva]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[CantidadConsolidadaMenu]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[ConsolidacionPlanificacion]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[ComponenteMenu]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[Menu]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[Planificacion]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[ConfiguracionProximidadBeacon]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[BeaconAutorizado]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[VentanaRetiroServicio]', N'U') IS NULL
    THROW 51031, N'Faltan tablas de Alimentación. Aplique primero las migraciones 009 a 012.', 1;

BEGIN TRANSACTION;

DELETE FROM [alimentacion].[ValidacionEntrega];
DELETE FROM [alimentacion].[Entrega];
DELETE FROM [alimentacion].[CodigoQR];
DELETE FROM [alimentacion].[Reserva];
DELETE FROM [alimentacion].[CantidadConsolidadaMenu];
DELETE FROM [alimentacion].[ConsolidacionPlanificacion];
DELETE FROM [alimentacion].[ComponenteMenu];
DELETE FROM [alimentacion].[Menu];
DELETE FROM [alimentacion].[Planificacion];
DELETE FROM [alimentacion].[ConfiguracionProximidadBeacon];
DELETE FROM [alimentacion].[BeaconAutorizado];
DELETE FROM [alimentacion].[VentanaRetiroServicio];

DBCC CHECKIDENT (N'[alimentacion].[Entrega]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[alimentacion].[Reserva]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[alimentacion].[CantidadConsolidadaMenu]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[alimentacion].[ConsolidacionPlanificacion]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[alimentacion].[ComponenteMenu]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[alimentacion].[Menu]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[alimentacion].[Planificacion]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[alimentacion].[ConfiguracionProximidadBeacon]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[alimentacion].[BeaconAutorizado]', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT (N'[alimentacion].[VentanaRetiroServicio]', RESEED, 0) WITH NO_INFOMSGS;

COMMIT TRANSACTION;
GO
