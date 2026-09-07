-- Migración: 010_crear_planificaciones_menus_y_consolidacion
-- Fecha: 2026-09-04T12:00:00-05:00
-- Entidad(es) afectada(s): alimentacion.Planificacion, alimentacion.Menu, alimentacion.ComponenteMenu, alimentacion.ConsolidacionPlanificacion, alimentacion.CantidadConsolidadaMenu
-- Referencia: Lineamientos/Alimentacion/funcionalidades/01_MENUS_Y_PUBLICACION.md / STACK.md
-- Motivo: Persistir una planificación con días elegidos libremente (no necesariamente consecutivos ni del mismo mes), el menú informativo y la fotografía irreversible de cantidades consolidadas.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [alimentacion].[Planificacion]
(
    [IdPlanificacion] BIGINT IDENTITY(1,1) NOT NULL,
    [IdentificadorPublico] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_Planificacion_IdentificadorPublico] DEFAULT (NEWSEQUENTIALID()),
    [IdSede] INT NOT NULL,
    [Estado] NVARCHAR(25) NOT NULL CONSTRAINT [VP_Planificacion_Estado] DEFAULT (N'BORRADOR'),
    [VersionRegistro] BIGINT NOT NULL CONSTRAINT [VP_Planificacion_VersionRegistro] DEFAULT (1),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_Planificacion_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_Planificacion] PRIMARY KEY CLUSTERED ([IdPlanificacion]),
    CONSTRAINT [CU_Planificacion_IdentificadorPublico] UNIQUE ([IdentificadorPublico]),
    CONSTRAINT [CU_Planificacion_IdSede] UNIQUE ([IdPlanificacion], [IdSede]),
    CONSTRAINT [CE_Planificacion_Sede] FOREIGN KEY ([IdSede]) REFERENCES [organizacion].[Sede] ([IdSede]),
    CONSTRAINT [RV_Planificacion_Estado] CHECK ([Estado] IN (N'BORRADOR', N'PUBLICADA_ABIERTA', N'PUBLICADA_CERRADA', N'CONSOLIDADA')),
    CONSTRAINT [RV_Planificacion_VersionRegistro] CHECK ([VersionRegistro] > 0)
);

CREATE INDEX [IN_Planificacion_SedeEstado]
    ON [alimentacion].[Planificacion] ([IdSede], [Estado]) INCLUDE ([VersionRegistro]);

CREATE TABLE [alimentacion].[Menu]
(
    [IdMenu] BIGINT IDENTITY(1,1) NOT NULL,
    [IdentificadorPublico] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_Menu_IdentificadorPublico] DEFAULT (NEWSEQUENTIALID()),
    [IdPlanificacion] BIGINT NOT NULL,
    [FechaServicio] DATE NOT NULL,
    [TipoServicio] NVARCHAR(20) NOT NULL,
    [EstaDisponible] BIT NOT NULL,
    [Nombre] NVARCHAR(200) NULL,
    [Descripcion] NVARCHAR(1000) NULL,
    [ReferenciaImagen] NVARCHAR(500) NULL,
    [VersionRegistro] BIGINT NOT NULL CONSTRAINT [VP_Menu_VersionRegistro] DEFAULT (1),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_Menu_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_Menu] PRIMARY KEY CLUSTERED ([IdMenu]),
    CONSTRAINT [CU_Menu_IdentificadorPublico] UNIQUE ([IdentificadorPublico]),
    CONSTRAINT [CU_Menu_PlanificacionFechaServicio] UNIQUE ([IdPlanificacion], [FechaServicio], [TipoServicio]),
    CONSTRAINT [CU_Menu_IdPlanificacionFechaServicio] UNIQUE ([IdMenu], [IdPlanificacion], [FechaServicio], [TipoServicio]),
    CONSTRAINT [CU_Menu_IdPlanificacion] UNIQUE ([IdMenu], [IdPlanificacion]),
    CONSTRAINT [CE_Menu_Planificacion] FOREIGN KEY ([IdPlanificacion]) REFERENCES [alimentacion].[Planificacion] ([IdPlanificacion]),
    CONSTRAINT [RV_Menu_TipoServicio] CHECK ([TipoServicio] IN (N'DESAYUNO', N'ALMUERZO', N'CENA')),
    CONSTRAINT [RV_Menu_Contenido] CHECK
    (
        ([EstaDisponible] = 1 AND NULLIF(LTRIM(RTRIM([Nombre])), N'') IS NOT NULL)
        OR
        ([EstaDisponible] = 0 AND [Nombre] IS NULL AND [Descripcion] IS NULL AND [ReferenciaImagen] IS NULL)
    ),
    CONSTRAINT [RV_Menu_VersionRegistro] CHECK ([VersionRegistro] > 0)
);

CREATE INDEX [IN_Menu_FechaServicioDisponible]
    ON [alimentacion].[Menu] ([FechaServicio], [TipoServicio], [EstaDisponible])
    INCLUDE ([IdPlanificacion], [Nombre], [VersionRegistro]);

CREATE TABLE [alimentacion].[ComponenteMenu]
(
    [IdComponenteMenu] BIGINT IDENTITY(1,1) NOT NULL,
    [IdMenu] BIGINT NOT NULL,
    [Orden] SMALLINT NOT NULL,
    [DescripcionComponente] NVARCHAR(300) NOT NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_ComponenteMenu_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [CP_ComponenteMenu] PRIMARY KEY CLUSTERED ([IdComponenteMenu]),
    CONSTRAINT [CU_ComponenteMenu_MenuOrden] UNIQUE ([IdMenu], [Orden]),
    CONSTRAINT [CE_ComponenteMenu_Menu] FOREIGN KEY ([IdMenu]) REFERENCES [alimentacion].[Menu] ([IdMenu]),
    CONSTRAINT [RV_ComponenteMenu_Orden] CHECK ([Orden] > 0),
    CONSTRAINT [RV_ComponenteMenu_DescripcionNoVacia] CHECK (LEN(LTRIM(RTRIM([DescripcionComponente]))) > 0)
);

CREATE TABLE [alimentacion].[ConsolidacionPlanificacion]
(
    [IdConsolidacionPlanificacion] BIGINT IDENTITY(1,1) NOT NULL,
    [IdPlanificacion] BIGINT NOT NULL,
    [IdActorColaborador] BIGINT NOT NULL,
    [EstadoAnterior] NVARCHAR(25) NOT NULL,
    [VersionPlanificacion] BIGINT NOT NULL,
    [FechaConsolidacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_ConsolidacionPlanificacion_FechaConsolidacionUtc] DEFAULT (SYSUTCDATETIME()),
    [IdCorrelacion] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [CP_ConsolidacionPlanificacion] PRIMARY KEY CLUSTERED ([IdConsolidacionPlanificacion]),
    CONSTRAINT [CU_ConsolidacionPlanificacion_Planificacion] UNIQUE ([IdPlanificacion]),
    CONSTRAINT [CU_ConsolidacionPlanificacion_IdPlanificacion] UNIQUE ([IdConsolidacionPlanificacion], [IdPlanificacion]),
    CONSTRAINT [CU_ConsolidacionPlanificacion_Correlacion] UNIQUE ([IdCorrelacion]),
    CONSTRAINT [CE_ConsolidacionPlanificacion_Planificacion] FOREIGN KEY ([IdPlanificacion]) REFERENCES [alimentacion].[Planificacion] ([IdPlanificacion]),
    CONSTRAINT [CE_ConsolidacionPlanificacion_Actor] FOREIGN KEY ([IdActorColaborador]) REFERENCES [rrhh].[Colaborador] ([IdColaborador]),
    CONSTRAINT [RV_ConsolidacionPlanificacion_EstadoAnterior] CHECK ([EstadoAnterior] = N'PUBLICADA_CERRADA'),
    CONSTRAINT [RV_ConsolidacionPlanificacion_Version] CHECK ([VersionPlanificacion] > 0)
);

CREATE TABLE [alimentacion].[CantidadConsolidadaMenu]
(
    [IdConsolidacionPlanificacion] BIGINT NOT NULL,
    [IdPlanificacion] BIGINT NOT NULL,
    [IdMenu] BIGINT NOT NULL,
    [CantidadReservas] INT NOT NULL,
    CONSTRAINT [CP_CantidadConsolidadaMenu] PRIMARY KEY CLUSTERED ([IdConsolidacionPlanificacion], [IdMenu]),
    CONSTRAINT [CE_CantidadConsolidadaMenu_Consolidacion] FOREIGN KEY ([IdConsolidacionPlanificacion], [IdPlanificacion]) REFERENCES [alimentacion].[ConsolidacionPlanificacion] ([IdConsolidacionPlanificacion], [IdPlanificacion]),
    CONSTRAINT [CE_CantidadConsolidadaMenu_Menu] FOREIGN KEY ([IdMenu], [IdPlanificacion]) REFERENCES [alimentacion].[Menu] ([IdMenu], [IdPlanificacion]),
    CONSTRAINT [RV_CantidadConsolidadaMenu_Cantidad] CHECK ([CantidadReservas] >= 0)
);

CREATE INDEX [IN_CantidadConsolidadaMenu_Planificacion]
    ON [alimentacion].[CantidadConsolidadaMenu] ([IdPlanificacion], [IdMenu]) INCLUDE ([CantidadReservas]);

COMMIT TRANSACTION;
GO

-- DOWN
/*
DROP TABLE IF EXISTS [alimentacion].[CantidadConsolidadaMenu];
DROP TABLE IF EXISTS [alimentacion].[ConsolidacionPlanificacion];
DROP TABLE IF EXISTS [alimentacion].[ComponenteMenu];
DROP TABLE IF EXISTS [alimentacion].[Menu];
DROP TABLE IF EXISTS [alimentacion].[Planificacion];
GO
*/
