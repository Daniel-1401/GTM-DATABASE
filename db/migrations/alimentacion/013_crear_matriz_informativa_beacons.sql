-- Migración: 013_crear_matriz_informativa_beacons
-- Fecha: 2026-09-10T12:00:00-05:00
-- Entidad(es) afectada(s): proximidad.MatrizInformativaBeacon, proximidad.MajorAreaBeacon, proximidad.VistaMatrizInformativaBeacon
-- Referencia: docs-proyecto/alimentacion/TABLAS_ALIMENTACION.md
-- Motivo: Registrar la jerarquía operativa Empresa → UUID → Major/Área → Minor/Beacon sin duplicar los identificadores técnicos de cada beacon autorizado.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [proximidad].[MatrizInformativaBeacon]
(
    [IdMatrizInformativaBeacon] BIGINT IDENTITY(1,1) NOT NULL,
    [IdEmpresa] INT NOT NULL,
    [IdentificadorUuid] UNIQUEIDENTIFIER NOT NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_MatrizInformativaBeacon_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_MatrizInformativaBeacon] PRIMARY KEY CLUSTERED ([IdMatrizInformativaBeacon]),
    CONSTRAINT [CU_MatrizInformativaBeacon_Uuid] UNIQUE ([IdentificadorUuid]),
    CONSTRAINT [CE_MatrizInformativaBeacon_Empresa] FOREIGN KEY ([IdEmpresa]) REFERENCES [organizacion].[Empresa] ([IdEmpresa])
);

CREATE INDEX [IN_MatrizInformativaBeacon_Empresa]
    ON [proximidad].[MatrizInformativaBeacon] ([IdEmpresa]);

CREATE TABLE [proximidad].[MajorAreaBeacon]
(
    [IdMajorAreaBeacon] BIGINT IDENTITY(1,1) NOT NULL,
    [IdMatrizInformativaBeacon] BIGINT NOT NULL,
    [CodigoAreaFisica] NVARCHAR(30) NOT NULL,
    [NombreAreaFisica] NVARCHAR(150) NOT NULL,
    [NumeroMajor] INT NOT NULL,
    [UbicacionReferencia] NVARCHAR(250) NULL,
    [Observacion] NVARCHAR(500) NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_MajorAreaBeacon_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_MajorAreaBeacon] PRIMARY KEY CLUSTERED ([IdMajorAreaBeacon]),
    CONSTRAINT [CU_MajorAreaBeacon_MatrizMajor] UNIQUE ([IdMatrizInformativaBeacon], [NumeroMajor]),
    CONSTRAINT [CE_MajorAreaBeacon_Matriz] FOREIGN KEY ([IdMatrizInformativaBeacon]) REFERENCES [proximidad].[MatrizInformativaBeacon] ([IdMatrizInformativaBeacon]),
    CONSTRAINT [RV_MajorAreaBeacon_Major] CHECK ([NumeroMajor] BETWEEN 0 AND 65535),
    CONSTRAINT [RV_MajorAreaBeacon_CodigoAreaNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoAreaFisica]))) > 0),
    CONSTRAINT [RV_MajorAreaBeacon_NombreAreaNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreAreaFisica]))) > 0)
);

CREATE INDEX [IN_MajorAreaBeacon_Area]
    ON [proximidad].[MajorAreaBeacon] ([CodigoAreaFisica]);

COMMIT TRANSACTION;
GO

CREATE VIEW [proximidad].[VistaMatrizInformativaBeacon]
AS
SELECT
    [Empresa].[IdEmpresa],
    [Empresa].[CodigoEmpresa],
    [Empresa].[RazonSocial],
    [Matriz].[IdentificadorUuid],
    [MajorArea].[NumeroMajor],
    [MajorArea].[CodigoAreaFisica],
    [MajorArea].[NombreAreaFisica],
    [Beacon].[IdBeaconAutorizado],
    [Beacon].[NumeroMinor],
    [Beacon].[IdSede],
    [Sede].[CodigoSede],
    [Sede].[NombreSede],
    [Beacon].[EstaActivo] AS [EstaActivoBeacon],
    [MajorArea].[UbicacionReferencia],
    [MajorArea].[Observacion]
FROM [proximidad].[MatrizInformativaBeacon] AS [Matriz]
INNER JOIN [organizacion].[Empresa] AS [Empresa]
    ON [Empresa].[IdEmpresa] = [Matriz].[IdEmpresa]
INNER JOIN [proximidad].[MajorAreaBeacon] AS [MajorArea]
    ON [MajorArea].[IdMatrizInformativaBeacon] = [Matriz].[IdMatrizInformativaBeacon]
LEFT JOIN [proximidad].[BeaconAutorizado] AS [Beacon]
    ON [Beacon].[IdentificadorUuid] = [Matriz].[IdentificadorUuid]
   AND [Beacon].[NumeroMajor] = [MajorArea].[NumeroMajor]
LEFT JOIN [organizacion].[Sede] AS [Sede]
    ON [Sede].[IdSede] = [Beacon].[IdSede];
GO

-- DOWN (destructivo; solo sobre la base del proyecto y con aprobación explícita)
-- DROP VIEW IF EXISTS [proximidad].[VistaMatrizInformativaBeacon];
-- DROP TABLE IF EXISTS [proximidad].[MajorAreaBeacon];
-- DROP TABLE IF EXISTS [proximidad].[MatrizInformativaBeacon];
