-- Migración: 004_crear_organizacion_y_centros_costo_sap
-- Fecha: 2026-09-04T08:00:21-05:00
-- Entidad(es) afectada(s): organizacion.Empresa, organizacion.Sede, organizacion.Area, organizacion.Cargo
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Crear los maestros GTM de organización.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [organizacion].[Empresa]
(
    [IdEmpresa] INT IDENTITY(1,1) NOT NULL,
    [CodigoEmpresa] NVARCHAR(30) NOT NULL,
    [RazonSocial] NVARCHAR(200) NOT NULL,
    [NombreComercial] NVARCHAR(200) NULL,
    [NumeroIdentificacionTributaria] NVARCHAR(30) NULL,
    [EstaActiva] BIT NOT NULL CONSTRAINT [VP_Empresa_EstaActiva] DEFAULT (1),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_Empresa_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_Empresa] PRIMARY KEY CLUSTERED ([IdEmpresa]),
    CONSTRAINT [CU_Empresa_Codigo] UNIQUE ([CodigoEmpresa]),
    CONSTRAINT [RV_Empresa_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoEmpresa]))) > 0),
    CONSTRAINT [RV_Empresa_RazonSocialNoVacia] CHECK (LEN(LTRIM(RTRIM([RazonSocial]))) > 0)
);

CREATE TABLE [organizacion].[Sede]
(
    [IdSede] INT IDENTITY(1,1) NOT NULL,
    [IdentificadorPublico] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_Sede_IdentificadorPublico] DEFAULT (NEWSEQUENTIALID()),
    [IdEmpresa] INT NOT NULL,
    [CodigoSede] NVARCHAR(30) NOT NULL,
    [NombreSede] NVARCHAR(150) NOT NULL,
    [Direccion] NVARCHAR(300) NULL,
    [EstaActiva] BIT NOT NULL CONSTRAINT [VP_Sede_EstaActiva] DEFAULT (1),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_Sede_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_Sede] PRIMARY KEY CLUSTERED ([IdSede]),
    CONSTRAINT [CU_Sede_IdentificadorPublico] UNIQUE ([IdentificadorPublico]),
    CONSTRAINT [CU_Sede_EmpresaCodigo] UNIQUE ([IdEmpresa], [CodigoSede]),
    CONSTRAINT [CE_Sede_Empresa] FOREIGN KEY ([IdEmpresa]) REFERENCES [organizacion].[Empresa] ([IdEmpresa]),
    CONSTRAINT [RV_Sede_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoSede]))) > 0),
    CONSTRAINT [RV_Sede_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreSede]))) > 0)
);

CREATE TABLE [organizacion].[Area]
(
    [IdArea] INT IDENTITY(1,1) NOT NULL,
    [CodigoArea] NVARCHAR(30) NOT NULL,
    [NombreArea] NVARCHAR(150) NOT NULL,
    [Descripcion] NVARCHAR(500) NULL,
    [EstaActiva] BIT NOT NULL CONSTRAINT [VP_Area_EstaActiva] DEFAULT (1),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_Area_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_Area] PRIMARY KEY CLUSTERED ([IdArea]),
    CONSTRAINT [CU_Area_Codigo] UNIQUE ([CodigoArea]),
    CONSTRAINT [RV_Area_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoArea]))) > 0),
    CONSTRAINT [RV_Area_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreArea]))) > 0)
);

CREATE TABLE [organizacion].[Cargo]
(
    [IdCargo] INT IDENTITY(1,1) NOT NULL,
    [CodigoCargo] NVARCHAR(30) NOT NULL,
    [NombreCargo] NVARCHAR(150) NOT NULL,
    [Descripcion] NVARCHAR(500) NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_Cargo_EstaActivo] DEFAULT (1),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_Cargo_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_Cargo] PRIMARY KEY CLUSTERED ([IdCargo]),
    CONSTRAINT [CU_Cargo_Codigo] UNIQUE ([CodigoCargo]),
    CONSTRAINT [RV_Cargo_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoCargo]))) > 0),
    CONSTRAINT [RV_Cargo_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreCargo]))) > 0)
);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. Requiere revertir primero las relaciones y asignaciones posteriores.
/*
DROP TABLE IF EXISTS [organizacion].[Cargo];
DROP TABLE IF EXISTS [organizacion].[Area];
DROP TABLE IF EXISTS [organizacion].[Sede];
DROP TABLE IF EXISTS [organizacion].[Empresa];
GO
*/
