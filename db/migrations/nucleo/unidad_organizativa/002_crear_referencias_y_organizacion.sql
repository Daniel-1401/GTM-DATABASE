-- Migración: 002_crear_referencias_y_organizacion
-- Fecha: 2026-09-24
-- Entidad(es) afectada(s): ConfiguracionUnidadOrganizativa, EmpresaReferencia, Sede, Area, Cargo, CargoSAP, CargoJefatura
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Crear la proyección empresarial de la UO y sus maestros organizacionales locales.

-- UP
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [organizacion].[ConfiguracionUnidadOrganizativa]
(
    [IdConfiguracionUnidadOrganizativa] TINYINT NOT NULL,
    [IdUnidadOrganizativaCorporativa] UNIQUEIDENTIFIER NOT NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_ConfiguracionUnidadOrganizativa_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_ConfiguracionUnidadOrganizativa]
        PRIMARY KEY CLUSTERED ([IdConfiguracionUnidadOrganizativa]),
    CONSTRAINT [CU_ConfiguracionUnidadOrganizativa_IdUnidadOrganizativaCorporativa]
        UNIQUE ([IdUnidadOrganizativaCorporativa]),
    CONSTRAINT [RV_ConfiguracionUnidadOrganizativa_UnicaFila]
        CHECK ([IdConfiguracionUnidadOrganizativa] = 1)
);

CREATE TABLE [organizacion].[EmpresaReferencia]
(
    [IdEmpresaReferencia] INT IDENTITY(1,1) NOT NULL,
    [IdEmpresaCorporativa] UNIQUEIDENTIFIER NOT NULL,
    [IdUnidadOrganizativaCorporativa] UNIQUEIDENTIFIER NOT NULL,
    [CodigoEmpresa] NVARCHAR(30) NOT NULL,
    [RazonSocial] NVARCHAR(200) NOT NULL,
    [EstaActiva] BIT NOT NULL CONSTRAINT [VP_EmpresaReferencia_EstaActiva] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_EmpresaReferencia_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_EmpresaReferencia] PRIMARY KEY CLUSTERED ([IdEmpresaReferencia]),
    CONSTRAINT [CU_EmpresaReferencia_IdEmpresaCorporativa] UNIQUE ([IdEmpresaCorporativa]),
    CONSTRAINT [CU_EmpresaReferencia_CodigoEmpresa] UNIQUE ([CodigoEmpresa]),
    CONSTRAINT [CE_EmpresaReferencia_ConfiguracionUnidadOrganizativa]
        FOREIGN KEY ([IdUnidadOrganizativaCorporativa])
        REFERENCES [organizacion].[ConfiguracionUnidadOrganizativa] ([IdUnidadOrganizativaCorporativa]),
    CONSTRAINT [RV_EmpresaReferencia_CodigoNoVacio]
        CHECK (LEN(LTRIM(RTRIM([CodigoEmpresa]))) > 0),
    CONSTRAINT [RV_EmpresaReferencia_RazonSocialNoVacia]
        CHECK (LEN(LTRIM(RTRIM([RazonSocial]))) > 0)
);

CREATE TABLE [organizacion].[Sede]
(
    [IdSede] INT IDENTITY(1,1) NOT NULL,
    [IdSedePublico] UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT [VP_Sede_IdSedePublico] DEFAULT (NEWSEQUENTIALID()),
    [IdEmpresaReferencia] INT NOT NULL,
    [CodigoSede] NVARCHAR(30) NOT NULL,
    [NombreSede] NVARCHAR(150) NOT NULL,
    [Direccion] NVARCHAR(300) NULL,
    [EstaActiva] BIT NOT NULL CONSTRAINT [VP_Sede_EstaActiva] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_Sede_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_Sede] PRIMARY KEY CLUSTERED ([IdSede]),
    CONSTRAINT [CU_Sede_IdSedePublico] UNIQUE ([IdSedePublico]),
    CONSTRAINT [CU_Sede_EmpresaIdSede] UNIQUE ([IdEmpresaReferencia], [IdSede]),
    CONSTRAINT [CU_Sede_EmpresaCodigo] UNIQUE ([IdEmpresaReferencia], [CodigoSede]),
    CONSTRAINT [CE_Sede_EmpresaReferencia]
        FOREIGN KEY ([IdEmpresaReferencia]) REFERENCES [organizacion].[EmpresaReferencia] ([IdEmpresaReferencia]),
    CONSTRAINT [RV_Sede_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoSede]))) > 0),
    CONSTRAINT [RV_Sede_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreSede]))) > 0)
);

CREATE TABLE [organizacion].[Area]
(
    [IdArea] INT IDENTITY(1,1) NOT NULL,
    [IdEmpresaReferencia] INT NOT NULL,
    [CodigoArea] NVARCHAR(30) NOT NULL,
    [NombreArea] NVARCHAR(150) NOT NULL,
    [Descripcion] NVARCHAR(500) NULL,
    [EstaActiva] BIT NOT NULL CONSTRAINT [VP_Area_EstaActiva] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_Area_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_Area] PRIMARY KEY CLUSTERED ([IdArea]),
    CONSTRAINT [CU_Area_EmpresaIdArea] UNIQUE ([IdEmpresaReferencia], [IdArea]),
    CONSTRAINT [CU_Area_EmpresaCodigo] UNIQUE ([IdEmpresaReferencia], [CodigoArea]),
    CONSTRAINT [CE_Area_EmpresaReferencia]
        FOREIGN KEY ([IdEmpresaReferencia]) REFERENCES [organizacion].[EmpresaReferencia] ([IdEmpresaReferencia]),
    CONSTRAINT [RV_Area_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoArea]))) > 0),
    CONSTRAINT [RV_Area_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreArea]))) > 0)
);

CREATE TABLE [organizacion].[Cargo]
(
    [IdCargo] INT IDENTITY(1,1) NOT NULL,
    [IdEmpresaReferencia] INT NOT NULL,
    [CodigoCargo] NVARCHAR(30) NOT NULL,
    [NombreCargo] NVARCHAR(150) NOT NULL,
    [Descripcion] NVARCHAR(500) NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_Cargo_EstaActivo] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_Cargo_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_Cargo] PRIMARY KEY CLUSTERED ([IdCargo]),
    CONSTRAINT [CU_Cargo_EmpresaIdCargo] UNIQUE ([IdEmpresaReferencia], [IdCargo]),
    CONSTRAINT [CU_Cargo_EmpresaCodigo] UNIQUE ([IdEmpresaReferencia], [CodigoCargo]),
    CONSTRAINT [CE_Cargo_EmpresaReferencia]
        FOREIGN KEY ([IdEmpresaReferencia]) REFERENCES [organizacion].[EmpresaReferencia] ([IdEmpresaReferencia]),
    CONSTRAINT [RV_Cargo_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoCargo]))) > 0),
    CONSTRAINT [RV_Cargo_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreCargo]))) > 0)
);

CREATE TABLE [organizacion].[CargoSAP]
(
    [IdCargoSAP] INT IDENTITY(1,1) NOT NULL,
    [IdEmpresaReferencia] INT NOT NULL,
    [IdCargo] INT NOT NULL,
    [CodigoCargoSAP] NVARCHAR(50) NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_CargoSAP_EstaActivo] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_CargoSAP_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_CargoSAP] PRIMARY KEY CLUSTERED ([IdCargoSAP]),
    CONSTRAINT [CU_CargoSAP_EmpresaIdCargoSAP] UNIQUE ([IdEmpresaReferencia], [IdCargoSAP]),
    CONSTRAINT [CU_CargoSAP_EmpresaCodigoSAP] UNIQUE ([IdEmpresaReferencia], [CodigoCargoSAP]),
    CONSTRAINT [CE_CargoSAP_EmpresaReferencia]
        FOREIGN KEY ([IdEmpresaReferencia])
        REFERENCES [organizacion].[EmpresaReferencia] ([IdEmpresaReferencia]),
    CONSTRAINT [CE_CargoSAP_Cargo]
        FOREIGN KEY ([IdEmpresaReferencia], [IdCargo])
        REFERENCES [organizacion].[Cargo] ([IdEmpresaReferencia], [IdCargo]),
    CONSTRAINT [RV_CargoSAP_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoCargoSAP]))) > 0)
);

CREATE INDEX [IN_CargoSAP_Cargo] ON [organizacion].[CargoSAP] ([IdCargo]);

CREATE TABLE [organizacion].[CargoJefatura]
(
    [IdCargoJefatura] BIGINT IDENTITY(1,1) NOT NULL,
    [IdEmpresaReferencia] INT NOT NULL,
    [IdCargoSubordinado] INT NOT NULL,
    [IdCargoJefe] INT NOT NULL,
    [FechaInicio] DATE NOT NULL,
    [FechaFin] DATE NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_CargoJefatura_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_CargoJefatura] PRIMARY KEY CLUSTERED ([IdCargoJefatura]),
    CONSTRAINT [CE_CargoJefatura_EmpresaReferencia]
        FOREIGN KEY ([IdEmpresaReferencia])
        REFERENCES [organizacion].[EmpresaReferencia] ([IdEmpresaReferencia]),
    CONSTRAINT [CE_CargoJefatura_CargoSubordinado]
        FOREIGN KEY ([IdEmpresaReferencia], [IdCargoSubordinado])
        REFERENCES [organizacion].[Cargo] ([IdEmpresaReferencia], [IdCargo]),
    CONSTRAINT [CE_CargoJefatura_CargoJefe]
        FOREIGN KEY ([IdEmpresaReferencia], [IdCargoJefe])
        REFERENCES [organizacion].[Cargo] ([IdEmpresaReferencia], [IdCargo]),
    CONSTRAINT [RV_CargoJefatura_CargosDistintos] CHECK ([IdCargoSubordinado] <> [IdCargoJefe]),
    CONSTRAINT [RV_CargoJefatura_Vigencia] CHECK ([FechaFin] IS NULL OR [FechaFin] > [FechaInicio])
);

CREATE UNIQUE INDEX [IN_CargoJefatura_SubordinadoAbierto]
    ON [organizacion].[CargoJefatura] ([IdEmpresaReferencia], [IdCargoSubordinado])
    WHERE [FechaFin] IS NULL;

CREATE INDEX [IN_CargoJefatura_JefeVigencia]
    ON [organizacion].[CargoJefatura] ([IdEmpresaReferencia], [IdCargoJefe], [FechaInicio], [FechaFin])
    INCLUDE ([IdCargoSubordinado]);

COMMIT TRANSACTION;
GO

-- DOWN
-- La reversión se ejecuta centralizadamente en
-- db/reversiones/revertir_nucleo_unidad_organizativa_completo.sql, en orden de dependencias.
