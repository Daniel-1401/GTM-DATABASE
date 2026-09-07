-- Migración: 003_crear_personas_colaboradores_e_identidad_microsoft
-- Fecha: 2026-09-04T08:00:21-05:00
-- Entidad(es) afectada(s): rrhh.Persona, rrhh.DocumentoPersona, rrhh.Colaborador, integracion.CuentaMicrosoftCorporativa
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Materializar la identidad civil, el registro laboral central y la referencia externa Microsoft sin modelar usuarios ni permisos.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [rrhh].[Persona]
(
    [IdPersona] BIGINT IDENTITY(1,1) NOT NULL,
    [Nombres] NVARCHAR(120) NOT NULL,
    [ApellidoPaterno] NVARCHAR(80) NOT NULL,
    [ApellidoMaterno] NVARCHAR(80) NULL,
    [FechaNacimiento] DATE NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_Persona_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_Persona] PRIMARY KEY CLUSTERED ([IdPersona]),
    CONSTRAINT [RV_Persona_NombresNoVacios] CHECK (LEN(LTRIM(RTRIM([Nombres]))) > 0),
    CONSTRAINT [RV_Persona_ApellidoPaternoNoVacio] CHECK (LEN(LTRIM(RTRIM([ApellidoPaterno]))) > 0)
);

CREATE TABLE [rrhh].[Colaborador]
(
    [IdColaborador] BIGINT IDENTITY(1,1) NOT NULL,
    [IdentificadorPublico] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_Colaborador_IdentificadorPublico] DEFAULT (NEWSEQUENTIALID()),
    [IdPersona] BIGINT NOT NULL,
    [CodigoSAP] NVARCHAR(30) NOT NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_Colaborador_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_Colaborador] PRIMARY KEY CLUSTERED ([IdColaborador]),
    CONSTRAINT [CU_Colaborador_IdentificadorPublico] UNIQUE ([IdentificadorPublico]),
    CONSTRAINT [CU_Colaborador_Persona] UNIQUE ([IdPersona]),
    CONSTRAINT [CU_Colaborador_CodigoSAP] UNIQUE ([CodigoSAP]),
    CONSTRAINT [CE_Colaborador_Persona] FOREIGN KEY ([IdPersona]) REFERENCES [rrhh].[Persona] ([IdPersona]),
    CONSTRAINT [RV_Colaborador_CodigoSAPNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoSAP]))) > 0)
);

CREATE TABLE [rrhh].[DocumentoPersona]
(
    [IdDocumentoPersona] BIGINT IDENTITY(1,1) NOT NULL,
    [IdPersona] BIGINT NOT NULL,
    [IdTipoDocumento] SMALLINT NOT NULL,
    [NumeroDocumento] NVARCHAR(50) NOT NULL,
    [CodigoPaisEmision] NCHAR(2) NULL,
    [EsPrincipal] BIT NOT NULL CONSTRAINT [VP_DocumentoPersona_EsPrincipal] DEFAULT (0),
    [FechaInicioVigencia] DATE NULL,
    [FechaFinVigencia] DATE NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_DocumentoPersona_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_DocumentoPersona] PRIMARY KEY CLUSTERED ([IdDocumentoPersona]),
    CONSTRAINT [CE_DocumentoPersona_Persona] FOREIGN KEY ([IdPersona]) REFERENCES [rrhh].[Persona] ([IdPersona]),
    CONSTRAINT [CE_DocumentoPersona_TipoDocumento] FOREIGN KEY ([IdTipoDocumento]) REFERENCES [catalogo].[TipoDocumento] ([IdTipoDocumento]),
    CONSTRAINT [RV_DocumentoPersona_NumeroNoVacio] CHECK (LEN(LTRIM(RTRIM([NumeroDocumento]))) > 0),
    CONSTRAINT [RV_DocumentoPersona_Vigencia] CHECK ([FechaFinVigencia] IS NULL OR [FechaInicioVigencia] IS NULL OR [FechaFinVigencia] > [FechaInicioVigencia])
);

CREATE INDEX [IN_DocumentoPersona_Busqueda]
    ON [rrhh].[DocumentoPersona] ([IdTipoDocumento], [CodigoPaisEmision], [NumeroDocumento]);

CREATE UNIQUE INDEX [IN_DocumentoPersona_PrincipalAbierto]
    ON [rrhh].[DocumentoPersona] ([IdPersona])
    WHERE [EsPrincipal] = 1 AND [FechaFinVigencia] IS NULL;

CREATE TABLE [integracion].[CuentaMicrosoftCorporativa]
(
    [IdCuentaMicrosoftCorporativa] BIGINT IDENTITY(1,1) NOT NULL,
    [IdColaborador] BIGINT NOT NULL,
    [IdentificadorObjetoMicrosoft] NVARCHAR(100) NULL,
    [NombrePrincipalUsuarioMicrosoft] NVARCHAR(320) NULL,
    [CorreoCorporativo] NVARCHAR(320) NULL,
    [FechaInicioVigencia] DATE NOT NULL,
    [FechaFinVigencia] DATE NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_CuentaMicrosoftCorporativa_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_CuentaMicrosoftCorporativa] PRIMARY KEY CLUSTERED ([IdCuentaMicrosoftCorporativa]),
    CONSTRAINT [CE_CuentaMicrosoftCorporativa_Colaborador] FOREIGN KEY ([IdColaborador]) REFERENCES [rrhh].[Colaborador] ([IdColaborador]),
    CONSTRAINT [RV_CuentaMicrosoftCorporativa_Identificador] CHECK
    (
        NULLIF(LTRIM(RTRIM([IdentificadorObjetoMicrosoft])), N'') IS NOT NULL
        OR NULLIF(LTRIM(RTRIM([NombrePrincipalUsuarioMicrosoft])), N'') IS NOT NULL
        OR NULLIF(LTRIM(RTRIM([CorreoCorporativo])), N'') IS NOT NULL
    ),
    CONSTRAINT [RV_CuentaMicrosoftCorporativa_Vigencia] CHECK ([FechaFinVigencia] IS NULL OR [FechaFinVigencia] > [FechaInicioVigencia])
);

CREATE UNIQUE INDEX [IN_CuentaMicrosoftCorporativa_Abierta]
    ON [integracion].[CuentaMicrosoftCorporativa] ([IdColaborador])
    WHERE [FechaFinVigencia] IS NULL;

CREATE INDEX [IN_CuentaMicrosoftCorporativa_ColaboradorVigencia]
    ON [integracion].[CuentaMicrosoftCorporativa] ([IdColaborador], [FechaInicioVigencia], [FechaFinVigencia]);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. El orden preserva las claves externas.
/*
DROP TABLE IF EXISTS [integracion].[CuentaMicrosoftCorporativa];
DROP TABLE IF EXISTS [rrhh].[DocumentoPersona];
DROP TABLE IF EXISTS [rrhh].[Colaborador];
DROP TABLE IF EXISTS [rrhh].[Persona];
GO
*/
