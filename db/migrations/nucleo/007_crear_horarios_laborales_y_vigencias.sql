-- Migración: 007_crear_horarios_laborales_y_vigencias
-- Fecha: 2026-09-04T08:00:21-05:00
-- Entidad(es) afectada(s): rrhh.HorarioLaboral, rrhh.VigenciaHorario
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Mantener el maestro local de códigos de horario y su asignación diaria por relación laboral.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [rrhh].[HorarioLaboral]
(
    [IdHorarioLaboral] INT IDENTITY(1,1) NOT NULL,
    [CodigoHorarioGTM] NVARCHAR(30) NOT NULL,
    [CodigoHorarioSAP] NVARCHAR(50) NOT NULL,
    [NombreHorario] NVARCHAR(150) NOT NULL,
    [Descripcion] NVARCHAR(500) NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_HorarioLaboral_EstaActivo] DEFAULT (1),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_HorarioLaboral_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_HorarioLaboral] PRIMARY KEY CLUSTERED ([IdHorarioLaboral]),
    CONSTRAINT [CU_HorarioLaboral_Codigo] UNIQUE ([CodigoHorarioGTM]),
    CONSTRAINT [CU_HorarioLaboral_CodigoSAP] UNIQUE ([CodigoHorarioSAP]),
    CONSTRAINT [RV_HorarioLaboral_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoHorarioGTM]))) > 0),
    CONSTRAINT [RV_HorarioLaboral_CodigoSAPNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoHorarioSAP]))) > 0),
    CONSTRAINT [RV_HorarioLaboral_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreHorario]))) > 0)
);

CREATE TABLE [rrhh].[VigenciaHorario]
(
    [IdVigenciaHorario] BIGINT IDENTITY(1,1) NOT NULL,
    [IdRelacionLaboral] BIGINT NOT NULL,
    [IdHorarioLaboral] INT NOT NULL,
    [Fecha] DATE NOT NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_VigenciaHorario_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_VigenciaHorario] PRIMARY KEY CLUSTERED ([IdVigenciaHorario]),
    CONSTRAINT [CE_VigenciaHorario_RelacionLaboral] FOREIGN KEY ([IdRelacionLaboral]) REFERENCES [rrhh].[RelacionLaboral] ([IdRelacionLaboral]),
    CONSTRAINT [CE_VigenciaHorario_HorarioLaboral] FOREIGN KEY ([IdHorarioLaboral]) REFERENCES [rrhh].[HorarioLaboral] ([IdHorarioLaboral])
);

CREATE UNIQUE INDEX [IN_VigenciaHorario_RelacionFecha]
    ON [rrhh].[VigenciaHorario] ([IdRelacionLaboral], [Fecha])
    INCLUDE ([IdHorarioLaboral]);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. La asignación se registra por día, sin ciclos ni excepciones adicionales.
/*
DROP TABLE IF EXISTS [rrhh].[VigenciaHorario];
DROP TABLE IF EXISTS [rrhh].[HorarioLaboral];
GO
*/
