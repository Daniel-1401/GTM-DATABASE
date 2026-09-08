-- Migración: 009_crear_schema_y_configuracion_alimentacion
-- Fecha: 2026-09-04T12:00:00-05:00
-- Entidad(es) afectada(s): alimentacion, alimentacion.VentanaRetiroServicio, alimentacion.BeaconAutorizado, alimentacion.ConfiguracionProximidadBeacon
-- Referencia: Lineamientos/Alimentacion/referencias-tecnicas/SQL_SERVER_BASELINE.md / STACK.md
-- Motivo: Crear el límite lógico y la configuración operativa inicial de Alimentación sin duplicar sedes ni horarios del núcleo GTM.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF SCHEMA_ID(N'alimentacion') IS NULL
    EXEC(N'CREATE SCHEMA [alimentacion] AUTHORIZATION [dbo]');

CREATE TABLE [alimentacion].[VentanaRetiroServicio]
(
    [IdVentanaRetiroServicio] BIGINT IDENTITY(1,1) NOT NULL,
    [IdSede] INT NOT NULL,
    [TipoServicio] NVARCHAR(20) NOT NULL,
    [HoraInicio] TIME(0) NOT NULL,
    [HoraFin] TIME(0) NOT NULL,
    [FechaInicioVigencia] DATE NOT NULL,
    [FechaFinVigencia] DATE NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_VentanaRetiroServicio_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [CP_VentanaRetiroServicio] PRIMARY KEY CLUSTERED ([IdVentanaRetiroServicio]),
    CONSTRAINT [CE_VentanaRetiroServicio_Sede] FOREIGN KEY ([IdSede]) REFERENCES [organizacion].[Sede] ([IdSede]),
    CONSTRAINT [RV_VentanaRetiroServicio_TipoServicio] CHECK ([TipoServicio] IN (N'DESAYUNO', N'ALMUERZO', N'CENA')),
    CONSTRAINT [RV_VentanaRetiroServicio_HorasDistintas] CHECK ([HoraInicio] <> [HoraFin]),
    CONSTRAINT [RV_VentanaRetiroServicio_Vigencia] CHECK ([FechaFinVigencia] IS NULL OR [FechaFinVigencia] > [FechaInicioVigencia])
);

CREATE UNIQUE INDEX [IN_VentanaRetiroServicio_Abierta]
    ON [alimentacion].[VentanaRetiroServicio] ([IdSede], [TipoServicio])
    WHERE [FechaFinVigencia] IS NULL;

CREATE INDEX [IN_VentanaRetiroServicio_SedeVigencia]
    ON [alimentacion].[VentanaRetiroServicio] ([IdSede], [TipoServicio], [FechaInicioVigencia], [FechaFinVigencia]);

CREATE TABLE [alimentacion].[BeaconAutorizado]
(
    [IdBeaconAutorizado] BIGINT IDENTITY(1,1) NOT NULL,
    [IdSede] INT NOT NULL,
    [IdentificadorUuid] UNIQUEIDENTIFIER NOT NULL,
    [NumeroMajor] INT NOT NULL,
    [NumeroMinor] INT NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_BeaconAutorizado_EstaActivo] DEFAULT (1),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_BeaconAutorizado_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_BeaconAutorizado] PRIMARY KEY CLUSTERED ([IdBeaconAutorizado]),
    CONSTRAINT [CU_BeaconAutorizado_Identificador] UNIQUE ([IdentificadorUuid], [NumeroMajor], [NumeroMinor]),
    CONSTRAINT [CE_BeaconAutorizado_Sede] FOREIGN KEY ([IdSede]) REFERENCES [organizacion].[Sede] ([IdSede]),
    CONSTRAINT [RV_BeaconAutorizado_Major] CHECK ([NumeroMajor] BETWEEN 0 AND 65535),
    CONSTRAINT [RV_BeaconAutorizado_Minor] CHECK ([NumeroMinor] BETWEEN 0 AND 65535)
);

CREATE INDEX [IN_BeaconAutorizado_SedeActivo]
    ON [alimentacion].[BeaconAutorizado] ([IdSede], [EstaActivo]);

CREATE TABLE [alimentacion].[ConfiguracionProximidadBeacon]
(
    [IdConfiguracionProximidadBeacon] BIGINT IDENTITY(1,1) NOT NULL,
    [IdBeaconAutorizado] BIGINT NOT NULL,
    [CantidadMinimaEmisiones] SMALLINT NOT NULL,
    [VentanaConfirmacionMilisegundos] INT NOT NULL,
    [TiempoSalidaRangoMilisegundos] INT NOT NULL,
    [UmbralRssi] SMALLINT NULL,
    [FechaInicioVigenciaUtc] DATETIME2(3) NOT NULL,
    [FechaFinVigenciaUtc] DATETIME2(3) NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_ConfiguracionProximidadBeacon_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [CP_ConfiguracionProximidadBeacon] PRIMARY KEY CLUSTERED ([IdConfiguracionProximidadBeacon]),
    CONSTRAINT [CE_ConfiguracionProximidadBeacon_Beacon] FOREIGN KEY ([IdBeaconAutorizado]) REFERENCES [alimentacion].[BeaconAutorizado] ([IdBeaconAutorizado]),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_Emisiones] CHECK ([CantidadMinimaEmisiones] > 0),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_Ventana] CHECK ([VentanaConfirmacionMilisegundos] > 0),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_SalidaRango] CHECK ([TiempoSalidaRangoMilisegundos] > 0),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_Rssi] CHECK ([UmbralRssi] IS NULL OR [UmbralRssi] BETWEEN -127 AND 0),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_Vigencia] CHECK ([FechaFinVigenciaUtc] IS NULL OR [FechaFinVigenciaUtc] > [FechaInicioVigenciaUtc])
);

CREATE UNIQUE INDEX [IN_ConfiguracionProximidadBeacon_Abierta]
    ON [alimentacion].[ConfiguracionProximidadBeacon] ([IdBeaconAutorizado])
    WHERE [FechaFinVigenciaUtc] IS NULL;

CREATE INDEX [IN_ConfiguracionProximidadBeacon_BeaconVigencia]
    ON [alimentacion].[ConfiguracionProximidadBeacon] ([IdBeaconAutorizado], [FechaInicioVigenciaUtc], [FechaFinVigenciaUtc]);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. Debe ejecutarse después de revertir las migraciones posteriores.
/*
DROP TABLE IF EXISTS [alimentacion].[ConfiguracionProximidadBeacon];
DROP TABLE IF EXISTS [alimentacion].[BeaconAutorizado];
DROP TABLE IF EXISTS [alimentacion].[VentanaRetiroServicio];
IF SCHEMA_ID(N'alimentacion') IS NOT NULL EXEC(N'DROP SCHEMA [alimentacion]');
GO
*/
