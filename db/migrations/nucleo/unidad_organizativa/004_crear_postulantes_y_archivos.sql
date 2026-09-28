-- Creación: núcleo de unidad organizativa / 004_crear_postulantes_y_archivos
-- Fecha: 2026-09-22T00:00:00-05:00
-- Entidad(es) afectada(s): seleccion.Postulante, seleccion.ArchivoPostulante, seleccion.HistorialEstadoPostulante
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Mantener el prefiltro de postulantes y sus adjuntos como un módulo
--         independiente de la identidad y vida laboral oficiales.

-- UP
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF SCHEMA_ID(N'seleccion') IS NULL
    EXEC(N'CREATE SCHEMA [seleccion] AUTHORIZATION [dbo]');

CREATE TABLE [seleccion].[Postulante]
(
    [IdPostulante] BIGINT IDENTITY(1,1) NOT NULL,
    [IdentificadorPublico] UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT [VP_Postulante_IdentificadorPublico] DEFAULT (NEWSEQUENTIALID()),
    [Nombres] NVARCHAR(120) NOT NULL,
    [ApellidoPaterno] NVARCHAR(80) NOT NULL,
    [ApellidoMaterno] NVARCHAR(80) NULL,
    [FechaNacimiento] DATE NULL,
    [Correo] NVARCHAR(320) NULL,
    [Telefono] NVARCHAR(30) NULL,
    [EstadoProceso] NVARCHAR(30) NOT NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_Postulante_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_Postulante] PRIMARY KEY CLUSTERED ([IdPostulante]),
    CONSTRAINT [CU_Postulante_IdentificadorPublico] UNIQUE ([IdentificadorPublico]),
    CONSTRAINT [RV_Postulante_NombresNoVacios]
        CHECK (LEN(LTRIM(RTRIM([Nombres]))) > 0),
    CONSTRAINT [RV_Postulante_ApellidoPaternoNoVacio]
        CHECK (LEN(LTRIM(RTRIM([ApellidoPaterno]))) > 0),
    CONSTRAINT [RV_Postulante_CorreoNoVacio]
        CHECK ([Correo] IS NULL OR LEN(LTRIM(RTRIM([Correo]))) > 0),
    CONSTRAINT [RV_Postulante_TelefonoNoVacio]
        CHECK ([Telefono] IS NULL OR LEN(LTRIM(RTRIM([Telefono]))) > 0),
    CONSTRAINT [RV_Postulante_EstadoProcesoNoVacio]
        CHECK (LEN(LTRIM(RTRIM([EstadoProceso]))) > 0)
);

CREATE INDEX [IN_Postulante_EstadoProcesoFechaCreacion]
    ON [seleccion].[Postulante] ([EstadoProceso], [FechaCreacion]);

CREATE TABLE [seleccion].[ArchivoPostulante]
(
    [IdArchivoPostulante] BIGINT IDENTITY(1,1) NOT NULL,
    [IdPostulante] BIGINT NOT NULL,
    [TipoArchivo] NVARCHAR(30) NOT NULL,
    [NombreOriginal] NVARCHAR(260) NOT NULL,
    [TipoMime] NVARCHAR(100) NOT NULL,
    [TamanoBytes] BIGINT NOT NULL,
    [HashSHA256] CHAR(64) NULL,
    [IdentificadorAlmacenamiento] NVARCHAR(500) NOT NULL,
    [EstaVigente] BIT NOT NULL
        CONSTRAINT [VP_ArchivoPostulante_EstaVigente] DEFAULT (1),
    [FechaCarga] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_ArchivoPostulante_FechaCarga] DEFAULT (SYSDATETIME()),
    [FechaCreacion] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_ArchivoPostulante_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_ArchivoPostulante] PRIMARY KEY CLUSTERED ([IdArchivoPostulante]),
    CONSTRAINT [CE_ArchivoPostulante_Postulante]
        FOREIGN KEY ([IdPostulante]) REFERENCES [seleccion].[Postulante] ([IdPostulante]),
    CONSTRAINT [RV_ArchivoPostulante_TipoArchivoNoVacio]
        CHECK (LEN(LTRIM(RTRIM([TipoArchivo]))) > 0),
    CONSTRAINT [RV_ArchivoPostulante_NombreOriginalNoVacio]
        CHECK (LEN(LTRIM(RTRIM([NombreOriginal]))) > 0),
    CONSTRAINT [RV_ArchivoPostulante_TipoMimeNoVacio]
        CHECK (LEN(LTRIM(RTRIM([TipoMime]))) > 0),
    CONSTRAINT [RV_ArchivoPostulante_TamanoBytesPositivo]
        CHECK ([TamanoBytes] > 0),
    CONSTRAINT [RV_ArchivoPostulante_IdentificadorAlmacenamientoNoVacio]
        CHECK (LEN(LTRIM(RTRIM([IdentificadorAlmacenamiento]))) > 0)
);

CREATE INDEX [IN_ArchivoPostulante_PostulanteFechaCarga]
    ON [seleccion].[ArchivoPostulante] ([IdPostulante], [FechaCarga])
    INCLUDE ([TipoArchivo], [NombreOriginal], [TipoMime], [EstaVigente]);

CREATE UNIQUE INDEX [IN_ArchivoPostulante_CurriculumVigente]
    ON [seleccion].[ArchivoPostulante] ([IdPostulante])
    WHERE [TipoArchivo] = N'CV' AND [EstaVigente] = 1;

CREATE TABLE [seleccion].[HistorialEstadoPostulante]
(
    [IdHistorialEstadoPostulante] BIGINT IDENTITY(1,1) NOT NULL,
    [IdPostulante] BIGINT NOT NULL,
    [EstadoProceso] NVARCHAR(30) NOT NULL,
    [Observacion] NVARCHAR(500) NULL,
    [FechaCambio] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_HistorialEstadoPostulante_FechaCambio] DEFAULT (SYSDATETIME()),
    [FechaCreacion] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_HistorialEstadoPostulante_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_HistorialEstadoPostulante] PRIMARY KEY CLUSTERED ([IdHistorialEstadoPostulante]),
    CONSTRAINT [CE_HistorialEstadoPostulante_Postulante]
        FOREIGN KEY ([IdPostulante]) REFERENCES [seleccion].[Postulante] ([IdPostulante]),
    CONSTRAINT [RV_HistorialEstadoPostulante_EstadoProcesoNoVacio]
        CHECK (LEN(LTRIM(RTRIM([EstadoProceso]))) > 0)
);

CREATE INDEX [IN_HistorialEstadoPostulante_PostulanteFechaCambio]
    ON [seleccion].[HistorialEstadoPostulante] ([IdPostulante], [FechaCambio]);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. Ejecutar únicamente cuando no existan dependencias posteriores.
/*
DROP TABLE IF EXISTS [seleccion].[HistorialEstadoPostulante];
DROP TABLE IF EXISTS [seleccion].[ArchivoPostulante];
DROP TABLE IF EXISTS [seleccion].[Postulante];
IF SCHEMA_ID(N'seleccion') IS NOT NULL EXEC(N'DROP SCHEMA [seleccion]');
GO
*/
