-- Creación: núcleo corporativo / 002_crear_catalogos_corporativos
-- Motor objetivo: Microsoft SQL Server 2017
-- Alcance: catálogos transversales administrados por CO.

SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [catalogo].[TipoDocumento]
(
    [IdTipoDocumento] SMALLINT IDENTITY(1,1) NOT NULL,
    [CodigoTipoDocumento] NVARCHAR(20) NOT NULL,
    [NombreTipoDocumento] NVARCHAR(100) NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_TipoDocumento_EstaActivo] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_TipoDocumento_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_TipoDocumento] PRIMARY KEY CLUSTERED ([IdTipoDocumento]),
    CONSTRAINT [CU_TipoDocumento_Codigo] UNIQUE ([CodigoTipoDocumento]),
    CONSTRAINT [RV_TipoDocumento_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoTipoDocumento]))) > 0),
    CONSTRAINT [RV_TipoDocumento_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreTipoDocumento]))) > 0)
);

CREATE TABLE [catalogo].[EstadoCivil]
(
    [IdEstadoCivil] SMALLINT IDENTITY(1,1) NOT NULL,
    [CodigoEstadoCivil] NVARCHAR(20) NOT NULL,
    [NombreEstadoCivil] NVARCHAR(100) NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_EstadoCivil_EstaActivo] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_EstadoCivil_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_EstadoCivil] PRIMARY KEY CLUSTERED ([IdEstadoCivil]),
    CONSTRAINT [CU_EstadoCivil_Codigo] UNIQUE ([CodigoEstadoCivil]),
    CONSTRAINT [RV_EstadoCivil_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoEstadoCivil]))) > 0),
    CONSTRAINT [RV_EstadoCivil_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreEstadoCivil]))) > 0)
);

CREATE TABLE [catalogo].[Genero]
(
    [IdGenero] SMALLINT IDENTITY(1,1) NOT NULL,
    [CodigoGenero] NVARCHAR(20) NOT NULL,
    [NombreGenero] NVARCHAR(100) NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_Genero_EstaActivo] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_Genero_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_Genero] PRIMARY KEY CLUSTERED ([IdGenero]),
    CONSTRAINT [CU_Genero_Codigo] UNIQUE ([CodigoGenero]),
    CONSTRAINT [RV_Genero_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoGenero]))) > 0),
    CONSTRAINT [RV_Genero_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreGenero]))) > 0)
);

CREATE TABLE [catalogo].[Pais]
(
    [IdPais] SMALLINT IDENTITY(1,1) NOT NULL,
    [CodigoPais] CHAR(2) NOT NULL,
    [NombrePais] NVARCHAR(100) NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_Pais_EstaActivo] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_Pais_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_Pais] PRIMARY KEY CLUSTERED ([IdPais]),
    CONSTRAINT [CU_Pais_Codigo] UNIQUE ([CodigoPais]),
    CONSTRAINT [RV_Pais_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoPais]))) = 2),
    CONSTRAINT [RV_Pais_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombrePais]))) > 0)
);

COMMIT TRANSACTION;
GO
