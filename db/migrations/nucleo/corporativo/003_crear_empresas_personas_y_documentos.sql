-- Creación: núcleo corporativo / 003_crear_empresas_personas_y_documentos
-- Motor objetivo: Microsoft SQL Server 2017
-- Alcance: estructura corporativa, identidad civil, documentos y colaborador corporativo.
-- Los datos laborales, SAP y de asignacion organizacional se crean en las
-- instancias de Unidad Organizativa; no pertenecen a esta instancia.

SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [organizacion].[UnidadOrganizativa]
(
    [IdUnidadOrganizativa] INT IDENTITY(1,1) NOT NULL,
    [IdUnidadOrganizativaCorporativa] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_UnidadOrganizativa_IdCorporativo] DEFAULT (NEWSEQUENTIALID()),
    [CodigoUnidadOrganizativa] NVARCHAR(30) NOT NULL,
    [NombreUnidadOrganizativa] NVARCHAR(150) NOT NULL,
    [EstaActiva] BIT NOT NULL CONSTRAINT [VP_UnidadOrganizativa_EstaActiva] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_UnidadOrganizativa_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_UnidadOrganizativa] PRIMARY KEY CLUSTERED ([IdUnidadOrganizativa]),
    CONSTRAINT [CU_UnidadOrganizativa_IdCorporativo] UNIQUE ([IdUnidadOrganizativaCorporativa]),
    CONSTRAINT [CU_UnidadOrganizativa_Codigo] UNIQUE ([CodigoUnidadOrganizativa]),
    CONSTRAINT [RV_UnidadOrganizativa_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoUnidadOrganizativa]))) > 0),
    CONSTRAINT [RV_UnidadOrganizativa_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreUnidadOrganizativa]))) > 0)
);

CREATE TABLE [organizacion].[Empresa]
(
    [IdEmpresa] INT IDENTITY(1,1) NOT NULL,
    [IdEmpresaCorporativa] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_Empresa_IdEmpresaCorporativa] DEFAULT (NEWSEQUENTIALID()),
    [IdUnidadOrganizativa] INT NOT NULL,
    [CodigoEmpresa] NVARCHAR(30) NOT NULL,
    [RazonSocial] NVARCHAR(200) NOT NULL,
    [NombreComercial] NVARCHAR(200) NULL,
    [NumeroIdentificacionTributaria] NVARCHAR(30) NULL,
    [EstaActiva] BIT NOT NULL CONSTRAINT [VP_Empresa_EstaActiva] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_Empresa_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_Empresa] PRIMARY KEY CLUSTERED ([IdEmpresa]),
    CONSTRAINT [CU_Empresa_IdEmpresaCorporativa] UNIQUE ([IdEmpresaCorporativa]),
    CONSTRAINT [CU_Empresa_Codigo] UNIQUE ([CodigoEmpresa]),
    CONSTRAINT [CE_Empresa_UnidadOrganizativa] FOREIGN KEY ([IdUnidadOrganizativa]) REFERENCES [organizacion].[UnidadOrganizativa] ([IdUnidadOrganizativa]),
    CONSTRAINT [RV_Empresa_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoEmpresa]))) > 0),
    CONSTRAINT [RV_Empresa_RazonSocialNoVacia] CHECK (LEN(LTRIM(RTRIM([RazonSocial]))) > 0)
);

CREATE TABLE [rrhh].[Persona]
(
    [IdPersona] BIGINT IDENTITY(1,1) NOT NULL,
    [IdPersonaCorporativa] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_Persona_IdPersonaCorporativa] DEFAULT (NEWSEQUENTIALID()),
    [Nombres] NVARCHAR(120) NOT NULL,
    [ApellidoPaterno] NVARCHAR(80) NOT NULL,
    [ApellidoMaterno] NVARCHAR(80) NULL,
    [FechaNacimiento] DATE NULL,
    [IdEstadoCivil] SMALLINT NULL,
    [IdGenero] SMALLINT NULL,
    [IdPaisNacionalidad] SMALLINT NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_Persona_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_Persona] PRIMARY KEY CLUSTERED ([IdPersona]),
    CONSTRAINT [CU_Persona_IdPersonaCorporativa] UNIQUE ([IdPersonaCorporativa]),
    CONSTRAINT [CE_Persona_EstadoCivil] FOREIGN KEY ([IdEstadoCivil]) REFERENCES [catalogo].[EstadoCivil] ([IdEstadoCivil]),
    CONSTRAINT [CE_Persona_Genero] FOREIGN KEY ([IdGenero]) REFERENCES [catalogo].[Genero] ([IdGenero]),
    CONSTRAINT [CE_Persona_PaisNacionalidad] FOREIGN KEY ([IdPaisNacionalidad]) REFERENCES [catalogo].[Pais] ([IdPais]),
    CONSTRAINT [RV_Persona_NombresNoVacios] CHECK (LEN(LTRIM(RTRIM([Nombres]))) > 0),
    CONSTRAINT [RV_Persona_ApellidoPaternoNoVacio] CHECK (LEN(LTRIM(RTRIM([ApellidoPaterno]))) > 0)
);

CREATE INDEX [IN_Empresa_UnidadOrganizativa]
    ON [organizacion].[Empresa] ([IdUnidadOrganizativa]);

CREATE TABLE [rrhh].[DocumentoPersona]
(
    [IdDocumentoPersona] BIGINT IDENTITY(1,1) NOT NULL,
    [IdPersona] BIGINT NOT NULL,
    [IdTipoDocumento] SMALLINT NOT NULL,
    [NumeroDocumento] NVARCHAR(50) NOT NULL,
    [IdPaisEmision] SMALLINT NULL,
    [EsPrincipal] BIT NOT NULL CONSTRAINT [VP_DocumentoPersona_EsPrincipal] DEFAULT (0),
    [FechaInicioVigencia] DATE NULL,
    [FechaFinVigencia] DATE NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_DocumentoPersona_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_DocumentoPersona] PRIMARY KEY CLUSTERED ([IdDocumentoPersona]),
    CONSTRAINT [CE_DocumentoPersona_Persona] FOREIGN KEY ([IdPersona]) REFERENCES [rrhh].[Persona] ([IdPersona]),
    CONSTRAINT [CE_DocumentoPersona_TipoDocumento] FOREIGN KEY ([IdTipoDocumento]) REFERENCES [catalogo].[TipoDocumento] ([IdTipoDocumento]),
    CONSTRAINT [CE_DocumentoPersona_PaisEmision] FOREIGN KEY ([IdPaisEmision]) REFERENCES [catalogo].[Pais] ([IdPais]),
    CONSTRAINT [RV_DocumentoPersona_NumeroNoVacio] CHECK (LEN(LTRIM(RTRIM([NumeroDocumento]))) > 0),
    CONSTRAINT [RV_DocumentoPersona_Vigencia] CHECK ([FechaFinVigencia] IS NULL OR [FechaInicioVigencia] IS NULL OR [FechaFinVigencia] > [FechaInicioVigencia])
);

CREATE UNIQUE INDEX [IN_DocumentoPersona_IdentidadUnica]
    ON [rrhh].[DocumentoPersona] ([IdTipoDocumento], [IdPaisEmision], [NumeroDocumento]);

CREATE UNIQUE INDEX [IN_DocumentoPersona_PrincipalAbierto]
    ON [rrhh].[DocumentoPersona] ([IdPersona])
    WHERE [EsPrincipal] = 1 AND [FechaFinVigencia] IS NULL;

CREATE TABLE [rrhh].[Colaborador]
(
    [IdColaborador] BIGINT IDENTITY(1,1) NOT NULL,
    [IdColaboradorCorporativo] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_Colaborador_IdColaboradorCorporativo] DEFAULT (NEWSEQUENTIALID()),
    [IdPersona] BIGINT NOT NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_Colaborador_FechaCreacion] DEFAULT (SYSDATETIME()),
    [FechaModificacion] DATETIME2(3) NULL,
    CONSTRAINT [CP_Colaborador] PRIMARY KEY CLUSTERED ([IdColaborador]),
    CONSTRAINT [CU_Colaborador_IdColaboradorCorporativo] UNIQUE ([IdColaboradorCorporativo]),
    CONSTRAINT [CU_Colaborador_Persona] UNIQUE ([IdPersona]),
    CONSTRAINT [CE_Colaborador_Persona] FOREIGN KEY ([IdPersona]) REFERENCES [rrhh].[Persona] ([IdPersona])
);

COMMIT TRANSACTION;
GO
