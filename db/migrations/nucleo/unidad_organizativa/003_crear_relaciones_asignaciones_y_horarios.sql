-- Migración: 003_crear_relaciones_asignaciones_y_horarios
-- Fecha: 2026-09-24
-- Entidad(es) afectada(s): RelacionLaboral, AsignacionOrganizacional, HorarioLaboral, VigenciaHorario
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Crear relaciones laborales, asignación operativa y horarios locales por empresa.

-- UP
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [rrhh].[RelacionLaboral]
(
    [IdRelacionLaboral] BIGINT IDENTITY(1,1) NOT NULL,
    [IdRelacionLaboralCorporativa] UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT [VP_RelacionLaboral_IdRelacionLaboralCorporativa] DEFAULT (NEWSEQUENTIALID()),
    [IdColaboradorCorporativo] UNIQUEIDENTIFIER NOT NULL,
    [IdEmpresaReferencia] INT NOT NULL,
    [CodigoColaboradorSAP] NVARCHAR(30) NOT NULL,
    [IdCargoSAP] INT NOT NULL,
    [EstaActiva] BIT NOT NULL CONSTRAINT [VP_RelacionLaboral_EstaActiva] DEFAULT (1),
    [FechaIngreso] DATE NOT NULL,
    [FechaCese] DATE NULL,
    [MotivoCese] NVARCHAR(250) NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_RelacionLaboral_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_RelacionLaboral] PRIMARY KEY CLUSTERED ([IdRelacionLaboral]),
    CONSTRAINT [CU_RelacionLaboral_IdRelacionLaboralCorporativa]
        UNIQUE ([IdRelacionLaboralCorporativa]),
    CONSTRAINT [CU_RelacionLaboral_ColaboradorEmpresa]
        UNIQUE ([IdColaboradorCorporativo], [IdEmpresaReferencia]),
    CONSTRAINT [CU_RelacionLaboral_EmpresaIdRelacionLaboral]
        UNIQUE ([IdEmpresaReferencia], [IdRelacionLaboral]),
    CONSTRAINT [CU_RelacionLaboral_EmpresaCodigoColaboradorSAP]
        UNIQUE ([IdEmpresaReferencia], [CodigoColaboradorSAP]),
    CONSTRAINT [CE_RelacionLaboral_EmpresaReferencia]
        FOREIGN KEY ([IdEmpresaReferencia])
        REFERENCES [organizacion].[EmpresaReferencia] ([IdEmpresaReferencia]),
    CONSTRAINT [CE_RelacionLaboral_CargoSAP]
        FOREIGN KEY ([IdEmpresaReferencia], [IdCargoSAP])
        REFERENCES [organizacion].[CargoSAP] ([IdEmpresaReferencia], [IdCargoSAP]),
    CONSTRAINT [RV_RelacionLaboral_CodigoColaboradorSAPNoVacio]
        CHECK (LEN(LTRIM(RTRIM([CodigoColaboradorSAP]))) > 0),
    CONSTRAINT [RV_RelacionLaboral_Cese] CHECK
    (
        ([EstaActiva] = 1 AND [FechaCese] IS NULL AND [MotivoCese] IS NULL)
        OR ([EstaActiva] = 0 AND [FechaCese] IS NOT NULL AND [FechaCese] >= [FechaIngreso])
    )
);

CREATE INDEX [IN_RelacionLaboral_EmpresaActiva]
    ON [rrhh].[RelacionLaboral] ([IdEmpresaReferencia], [EstaActiva])
    INCLUDE ([IdColaboradorCorporativo], [IdCargoSAP], [CodigoColaboradorSAP]);

CREATE TABLE [rrhh].[AsignacionOrganizacional]
(
    [IdAsignacionOrganizacional] BIGINT IDENTITY(1,1) NOT NULL,
    [IdAsignacionOrganizacionalCorporativa] UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT [VP_AsignacionOrganizacional_IdAsignacionOrganizacionalCorporativa] DEFAULT (NEWSEQUENTIALID()),
    [IdRelacionLaboralCorporativa] UNIQUEIDENTIFIER NOT NULL,
    [IdColaboradorCorporativo] UNIQUEIDENTIFIER NOT NULL,
    [IdUnidadOrganizativaOrigenCorporativa] UNIQUEIDENTIFIER NOT NULL,
    [IdEmpresaEmpleadoraCorporativa] UNIQUEIDENTIFIER NOT NULL,
    [IdEmpresaReferencia] INT NOT NULL,
    [IdSede] INT NOT NULL,
    [IdArea] INT NOT NULL,
    [EstaActiva] BIT NOT NULL CONSTRAINT [VP_AsignacionOrganizacional_EstaActiva] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_AsignacionOrganizacional_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_AsignacionOrganizacional] PRIMARY KEY CLUSTERED ([IdAsignacionOrganizacional]),
    CONSTRAINT [CU_AsignacionOrganizacional_IdAsignacionOrganizacionalCorporativa]
        UNIQUE ([IdAsignacionOrganizacionalCorporativa]),
    CONSTRAINT [CU_AsignacionOrganizacional_RelacionLaboral]
        UNIQUE ([IdRelacionLaboralCorporativa]),
    CONSTRAINT [CE_AsignacionOrganizacional_EmpresaReferencia]
        FOREIGN KEY ([IdEmpresaReferencia])
        REFERENCES [organizacion].[EmpresaReferencia] ([IdEmpresaReferencia]),
    CONSTRAINT [CE_AsignacionOrganizacional_Sede]
        FOREIGN KEY ([IdEmpresaReferencia], [IdSede])
        REFERENCES [organizacion].[Sede] ([IdEmpresaReferencia], [IdSede]),
    CONSTRAINT [CE_AsignacionOrganizacional_Area]
        FOREIGN KEY ([IdEmpresaReferencia], [IdArea])
        REFERENCES [organizacion].[Area] ([IdEmpresaReferencia], [IdArea])
);

CREATE INDEX [IN_AsignacionOrganizacional_EmpresaAreaActiva]
    ON [rrhh].[AsignacionOrganizacional] ([IdEmpresaReferencia], [IdArea], [EstaActiva])
    INCLUDE ([IdRelacionLaboralCorporativa], [IdColaboradorCorporativo], [IdSede], [IdEmpresaEmpleadoraCorporativa]);

CREATE TABLE [rrhh].[HorarioLaboral]
(
    [IdHorarioLaboral] INT IDENTITY(1,1) NOT NULL,
    [IdEmpresaReferencia] INT NOT NULL,
    [CodigoHorarioGTM] NVARCHAR(30) NOT NULL,
    [CodigoHorarioSAP] NVARCHAR(50) NOT NULL,
    [TipoTurno] NVARCHAR(20) NOT NULL,
    [NombreHorario] NVARCHAR(150) NOT NULL,
    [Descripcion] NVARCHAR(500) NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_HorarioLaboral_EstaActivo] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_HorarioLaboral_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_HorarioLaboral] PRIMARY KEY CLUSTERED ([IdHorarioLaboral]),
    CONSTRAINT [CU_HorarioLaboral_EmpresaIdHorarioLaboral]
        UNIQUE ([IdEmpresaReferencia], [IdHorarioLaboral]),
    CONSTRAINT [CU_HorarioLaboral_EmpresaCodigoGTM]
        UNIQUE ([IdEmpresaReferencia], [CodigoHorarioGTM]),
    CONSTRAINT [CU_HorarioLaboral_EmpresaCodigoSAP]
        UNIQUE ([IdEmpresaReferencia], [CodigoHorarioSAP]),
    CONSTRAINT [CE_HorarioLaboral_EmpresaReferencia]
        FOREIGN KEY ([IdEmpresaReferencia]) REFERENCES [organizacion].[EmpresaReferencia] ([IdEmpresaReferencia]),
    CONSTRAINT [RV_HorarioLaboral_CodigoNoVacio]
        CHECK (LEN(LTRIM(RTRIM([CodigoHorarioGTM]))) > 0),
    CONSTRAINT [RV_HorarioLaboral_CodigoSAPNoVacio]
        CHECK (LEN(LTRIM(RTRIM([CodigoHorarioSAP]))) > 0),
    CONSTRAINT [RV_HorarioLaboral_TipoTurno]
        CHECK ([TipoTurno] IN (N'MANANA', N'TARDE', N'NOCHE', N'MADRUGADA')),
    CONSTRAINT [RV_HorarioLaboral_NombreNoVacio]
        CHECK (LEN(LTRIM(RTRIM([NombreHorario]))) > 0)
);

CREATE TABLE [rrhh].[VigenciaHorario]
(
    [IdVigenciaHorario] BIGINT IDENTITY(1,1) NOT NULL,
    [IdRelacionLaboral] BIGINT NOT NULL,
    [IdEmpresaReferencia] INT NOT NULL,
    [IdHorarioLaboral] INT NOT NULL,
    [Fecha] DATE NOT NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_VigenciaHorario_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_VigenciaHorario] PRIMARY KEY CLUSTERED ([IdVigenciaHorario]),
    CONSTRAINT [CE_VigenciaHorario_EmpresaReferencia]
        FOREIGN KEY ([IdEmpresaReferencia])
        REFERENCES [organizacion].[EmpresaReferencia] ([IdEmpresaReferencia]),
    CONSTRAINT [CE_VigenciaHorario_RelacionLaboral]
        FOREIGN KEY ([IdEmpresaReferencia], [IdRelacionLaboral])
        REFERENCES [rrhh].[RelacionLaboral] ([IdEmpresaReferencia], [IdRelacionLaboral]),
    CONSTRAINT [CE_VigenciaHorario_HorarioLaboral]
        FOREIGN KEY ([IdEmpresaReferencia], [IdHorarioLaboral])
        REFERENCES [rrhh].[HorarioLaboral] ([IdEmpresaReferencia], [IdHorarioLaboral])
);

CREATE UNIQUE INDEX [IN_VigenciaHorario_RelacionLaboralFecha]
    ON [rrhh].[VigenciaHorario] ([IdRelacionLaboral], [Fecha])
    INCLUDE ([IdHorarioLaboral]);

COMMIT TRANSACTION;
GO

-- DOWN
-- La reversión se ejecuta centralizadamente en
-- db/reversiones/revertir_nucleo_unidad_organizativa_completo.sql, en orden de dependencias.
