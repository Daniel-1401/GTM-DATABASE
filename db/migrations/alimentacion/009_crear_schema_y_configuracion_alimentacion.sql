-- Migración: 009_crear_schema_y_configuracion_alimentacion
-- Fecha: 2026-09-04T12:00:00-05:00
-- Entidad(es) afectada(s): alimentacion, alimentacion.TipoServicio, alimentacion.VentanaRetiroServicio, proximidad, proximidad.MajorAreaBeacon, proximidad.ConfiguracionBeacon, proximidad.BeaconAutorizado
-- Referencia: docs-proyecto/alimentacion/TABLAS_ALIMENTACION.md
-- Motivo: Crear el límite lógico y la configuración operativa inicial de Alimentación sin duplicar sedes ni horarios del núcleo GTM. Las áreas major y las políticas de proximidad se definen por sede y pueden reutilizarse entre varios beacons.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF SCHEMA_ID(N'alimentacion') IS NULL
    EXEC(N'CREATE SCHEMA [alimentacion] AUTHORIZATION [dbo]');
IF SCHEMA_ID(N'proximidad') IS NULL
    EXEC(N'CREATE SCHEMA [proximidad] AUTHORIZATION [dbo]');

CREATE TABLE [alimentacion].[TipoServicio]
(
    [IdTipoServicio] SMALLINT IDENTITY(1,1) NOT NULL,
    [CodigoTipoServicio] NVARCHAR(20) NOT NULL,
    [NombreTipoServicio] NVARCHAR(100) NOT NULL,
    [OrdenPresentacion] TINYINT NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_TipoServicio_EstaActivo] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_TipoServicio_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_TipoServicio] PRIMARY KEY CLUSTERED ([IdTipoServicio]),
    CONSTRAINT [CU_TipoServicio_Codigo] UNIQUE ([CodigoTipoServicio]),
    CONSTRAINT [CU_TipoServicio_Orden] UNIQUE ([OrdenPresentacion]),
    CONSTRAINT [RV_TipoServicio_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoTipoServicio]))) > 0),
    CONSTRAINT [RV_TipoServicio_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreTipoServicio]))) > 0)
);

INSERT INTO [alimentacion].[TipoServicio]
    ([CodigoTipoServicio], [NombreTipoServicio], [OrdenPresentacion])
VALUES
    (N'DESAYUNO', N'Desayuno', 1),
    (N'ALMUERZO', N'Almuerzo', 2),
    (N'CENA', N'Cena', 3);

CREATE TABLE [alimentacion].[VentanaRetiroServicio]
(
    [IdVentanaRetiroServicio] BIGINT IDENTITY(1,1) NOT NULL,
    [IdSede] INT NOT NULL,
    [TipoServicio] NVARCHAR(20) NOT NULL,
    [HoraInicio] TIME(0) NOT NULL,
    [HoraFin] TIME(0) NOT NULL,
    [FechaInicioVigencia] DATE NOT NULL,
    [FechaFinVigencia] DATE NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_VentanaRetiroServicio_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_VentanaRetiroServicio] PRIMARY KEY CLUSTERED ([IdVentanaRetiroServicio]),
    CONSTRAINT [CE_VentanaRetiroServicio_TipoServicio] FOREIGN KEY ([TipoServicio]) REFERENCES [alimentacion].[TipoServicio] ([CodigoTipoServicio]),
    CONSTRAINT [RV_VentanaRetiroServicio_HorasDistintas] CHECK ([HoraInicio] <> [HoraFin]),
    CONSTRAINT [RV_VentanaRetiroServicio_Vigencia] CHECK ([FechaFinVigencia] IS NULL OR [FechaFinVigencia] > [FechaInicioVigencia])
);

CREATE UNIQUE INDEX [IN_VentanaRetiroServicio_Abierta]
    ON [alimentacion].[VentanaRetiroServicio] ([IdSede], [TipoServicio])
    WHERE [FechaFinVigencia] IS NULL;

CREATE INDEX [IN_VentanaRetiroServicio_SedeVigencia]
    ON [alimentacion].[VentanaRetiroServicio] ([IdSede], [TipoServicio], [FechaInicioVigencia], [FechaFinVigencia]);

CREATE TABLE [proximidad].[MajorAreaBeacon]
(
    [IdMajorAreaBeacon] BIGINT IDENTITY(1,1) NOT NULL,
    [IdSede] INT NOT NULL,
    [NumeroMajor] INT NOT NULL,
    [CodigoAreaFisica] NVARCHAR(30) NOT NULL,
    [NombreAreaFisica] NVARCHAR(150) NOT NULL,
    [UbicacionReferencia] NVARCHAR(250) NULL,
    [Observacion] NVARCHAR(500) NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_MajorAreaBeacon_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_MajorAreaBeacon] PRIMARY KEY CLUSTERED ([IdMajorAreaBeacon]),
    CONSTRAINT [CU_MajorAreaBeacon_SedeMajor] UNIQUE ([IdSede], [NumeroMajor]),
    CONSTRAINT [CU_MajorAreaBeacon_IdSedeMajor] UNIQUE ([IdMajorAreaBeacon], [IdSede], [NumeroMajor]),
    CONSTRAINT [RV_MajorAreaBeacon_Major] CHECK ([NumeroMajor] BETWEEN 0 AND 65535),
    CONSTRAINT [RV_MajorAreaBeacon_CodigoAreaNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoAreaFisica]))) > 0),
    CONSTRAINT [RV_MajorAreaBeacon_NombreAreaNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreAreaFisica]))) > 0)
);

CREATE INDEX [IN_MajorAreaBeacon_SedeArea]
    ON [proximidad].[MajorAreaBeacon] ([IdSede], [CodigoAreaFisica]);

CREATE TABLE [proximidad].[ConfiguracionBeacon]
(
    [IdConfiguracionProximidadBeacon] BIGINT IDENTITY(1,1) NOT NULL,
    [IdSede] INT NOT NULL,
    [CodigoVersion] NVARCHAR(100) NOT NULL,
    [CantidadMinimaEmisiones] SMALLINT NOT NULL,
    [VentanaConfirmacionMilisegundos] INT NOT NULL,
    [IntervaloEvaluacionMilisegundos] INT NOT NULL,
    [TiempoSalidaRangoMilisegundos] INT NOT NULL,
    [UmbralRssi] SMALLINT NULL,
    [FechaInicioVigencia] DATETIME2(3) NOT NULL,
    [FechaFinVigencia] DATETIME2(3) NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_ConfiguracionProximidadBeacon_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_ConfiguracionProximidadBeacon] PRIMARY KEY CLUSTERED ([IdConfiguracionProximidadBeacon]),
    CONSTRAINT [CU_ConfiguracionProximidadBeacon_SedeVersion] UNIQUE ([IdSede], [CodigoVersion]),
    CONSTRAINT [CU_ConfiguracionProximidadBeacon_IdSede] UNIQUE ([IdConfiguracionProximidadBeacon], [IdSede]),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_CodigoVersionNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoVersion]))) > 0),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_Emisiones] CHECK ([CantidadMinimaEmisiones] > 0),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_Ventana] CHECK ([VentanaConfirmacionMilisegundos] > 0),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_IntervaloEvaluacion] CHECK ([IntervaloEvaluacionMilisegundos] > 0),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_SalidaRango] CHECK ([TiempoSalidaRangoMilisegundos] > 0),
    CONSTRAINT [RV_ConfiguracionProximidadBeacon_Rssi] CHECK ([UmbralRssi] IS NULL OR [UmbralRssi] BETWEEN -127 AND 0),
CONSTRAINT [RV_ConfiguracionProximidadBeacon_Vigencia] CHECK ([FechaFinVigencia] IS NULL OR [FechaFinVigencia] > [FechaInicioVigencia])
);

CREATE INDEX [IN_ConfiguracionProximidadBeacon_SedeVigencia]
    ON [proximidad].[ConfiguracionBeacon] ([IdSede], [FechaInicioVigencia], [FechaFinVigencia]);

CREATE TABLE [proximidad].[BeaconAutorizado]
(
    [IdBeaconAutorizado] BIGINT IDENTITY(1,1) NOT NULL,
    [IdSede] INT NOT NULL,
    [IdMajorAreaBeacon] BIGINT NOT NULL,
    [IdConfiguracionProximidadBeacon] BIGINT NOT NULL,
    [ReferenciaBeacon] NVARCHAR(100) NOT NULL,
    [DireccionMac] CHAR(17) NULL,
    [IdentificadorUuid] UNIQUEIDENTIFIER NOT NULL,
    [NumeroMajor] INT NOT NULL,
    [NumeroMinor] INT NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_BeaconAutorizado_EstaActivo] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_BeaconAutorizado_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_BeaconAutorizado] PRIMARY KEY CLUSTERED ([IdBeaconAutorizado]),
    CONSTRAINT [CU_BeaconAutorizado_Identificador] UNIQUE ([IdentificadorUuid], [NumeroMajor], [NumeroMinor]),
    CONSTRAINT [CE_BeaconAutorizado_MajorAreaSede] FOREIGN KEY ([IdMajorAreaBeacon], [IdSede], [NumeroMajor]) REFERENCES [proximidad].[MajorAreaBeacon] ([IdMajorAreaBeacon], [IdSede], [NumeroMajor]),
    CONSTRAINT [CE_BeaconAutorizado_ConfiguracionSede] FOREIGN KEY ([IdConfiguracionProximidadBeacon], [IdSede]) REFERENCES [proximidad].[ConfiguracionBeacon] ([IdConfiguracionProximidadBeacon], [IdSede]),
    CONSTRAINT [RV_BeaconAutorizado_ReferenciaNoVacia] CHECK (LEN(LTRIM(RTRIM([ReferenciaBeacon]))) > 0),
    CONSTRAINT [RV_BeaconAutorizado_DireccionMacFormato] CHECK ([DireccionMac] IS NULL OR [DireccionMac] COLLATE Latin1_General_100_BIN2 LIKE '[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]'),
    CONSTRAINT [RV_BeaconAutorizado_Major] CHECK ([NumeroMajor] BETWEEN 0 AND 65535),
    CONSTRAINT [RV_BeaconAutorizado_Minor] CHECK ([NumeroMinor] BETWEEN 0 AND 65535)
);

CREATE INDEX [IN_BeaconAutorizado_SedeActivo]
    ON [proximidad].[BeaconAutorizado] ([IdSede], [EstaActivo]);

CREATE INDEX [IN_BeaconAutorizado_Configuracion]
    ON [proximidad].[BeaconAutorizado] ([IdConfiguracionProximidadBeacon]);

CREATE INDEX [IN_BeaconAutorizado_MajorArea]
    ON [proximidad].[BeaconAutorizado] ([IdMajorAreaBeacon]);

CREATE INDEX [IN_BeaconAutorizado_SedeReferencia]
    ON [proximidad].[BeaconAutorizado] ([IdSede], [ReferenciaBeacon]);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. Debe ejecutarse después de revertir las migraciones posteriores.
/*
DROP TABLE IF EXISTS [proximidad].[BeaconAutorizado];
DROP TABLE IF EXISTS [proximidad].[ConfiguracionBeacon];
DROP TABLE IF EXISTS [proximidad].[MajorAreaBeacon];
DROP TABLE IF EXISTS [alimentacion].[VentanaRetiroServicio];
DROP TABLE IF EXISTS [alimentacion].[TipoServicio];
IF SCHEMA_ID(N'alimentacion') IS NOT NULL EXEC(N'DROP SCHEMA [alimentacion]');
GO
*/
