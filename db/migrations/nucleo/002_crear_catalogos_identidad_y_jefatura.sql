-- Migración: 002_crear_catalogos_identidad_y_jefatura
-- Fecha: 2026-09-04T08:00:21-05:00
-- Entidad(es) afectada(s): catalogo.TipoDocumento, catalogo.TipoJefatura
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Crear catálogos extensibles sin fijar valores todavía no aprobados.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [catalogo].[TipoDocumento]
(
    [IdTipoDocumento] SMALLINT IDENTITY(1,1) NOT NULL,
    [CodigoTipoDocumento] NVARCHAR(20) NOT NULL,
    [NombreTipoDocumento] NVARCHAR(100) NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_TipoDocumento_EstaActivo] DEFAULT (1),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_TipoDocumento_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [CP_TipoDocumento] PRIMARY KEY CLUSTERED ([IdTipoDocumento]),
    CONSTRAINT [CU_TipoDocumento_Codigo] UNIQUE ([CodigoTipoDocumento]),
    CONSTRAINT [RV_TipoDocumento_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoTipoDocumento]))) > 0),
    CONSTRAINT [RV_TipoDocumento_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreTipoDocumento]))) > 0)
);

CREATE TABLE [catalogo].[TipoJefatura]
(
    [IdTipoJefatura] SMALLINT IDENTITY(1,1) NOT NULL,
    [CodigoTipoJefatura] NVARCHAR(30) NOT NULL,
    [NombreTipoJefatura] NVARCHAR(100) NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_TipoJefatura_EstaActivo] DEFAULT (1),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_TipoJefatura_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [CP_TipoJefatura] PRIMARY KEY CLUSTERED ([IdTipoJefatura]),
    CONSTRAINT [CU_TipoJefatura_Codigo] UNIQUE ([CodigoTipoJefatura]),
    CONSTRAINT [RV_TipoJefatura_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoTipoJefatura]))) > 0),
    CONSTRAINT [RV_TipoJefatura_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreTipoJefatura]))) > 0)
);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. Pierde los catálogos y requiere que no existan dependencias posteriores.
/*
DROP TABLE IF EXISTS [catalogo].[TipoJefatura];
DROP TABLE IF EXISTS [catalogo].[TipoDocumento];
GO
*/
