-- Migracion: 005_crear_vistas_consulta
-- Motor objetivo: Microsoft SQL Server 2017
-- Alcance: contratos de lectura de la instancia hija de una unidad organizativa.
-- No expone identidad personal corporativa; esa informacion pertenece a CO.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [organizacion].[vw_SedeConsulta]
AS
SELECT
    [Configuracion].[IdUnidadOrganizativaCorporativa],
    [Empresa].[IdEmpresaReferencia],
    [Empresa].[IdEmpresaCorporativa],
    [Empresa].[CodigoEmpresa],
    [Empresa].[RazonSocial],
    [Empresa].[EstaActiva] AS [EstaActivaEmpresa],
    [Sede].[IdSede],
    [Sede].[IdSedePublico],
    [Sede].[CodigoSede],
    [Sede].[NombreSede],
    [Sede].[Direccion],
    [Sede].[EstaActiva] AS [EstaActivaSede]
FROM [organizacion].[ConfiguracionUnidadOrganizativa] AS [Configuracion]
INNER JOIN [organizacion].[EmpresaReferencia] AS [Empresa]
    ON [Empresa].[IdUnidadOrganizativaCorporativa] = [Configuracion].[IdUnidadOrganizativaCorporativa]
INNER JOIN [organizacion].[Sede] AS [Sede]
    ON [Sede].[IdEmpresaReferencia] = [Empresa].[IdEmpresaReferencia];
GO

CREATE OR ALTER VIEW [organizacion].[vw_EstructuraOrganizacionalConsulta]
AS
SELECT
    [Configuracion].[IdUnidadOrganizativaCorporativa],
    [Empresa].[IdEmpresaReferencia],
    [Empresa].[IdEmpresaCorporativa],
    [Empresa].[CodigoEmpresa],
    [Empresa].[RazonSocial],
    CAST(N'SEDE' AS NVARCHAR(20)) AS [TipoElemento],
    [Sede].[IdSede] AS [IdElemento],
    [Sede].[IdSedePublico],
    [Sede].[CodigoSede] AS [CodigoElemento],
    [Sede].[NombreSede] AS [NombreElemento],
    [Sede].[EstaActiva] AS [EstaActivo]
FROM [organizacion].[ConfiguracionUnidadOrganizativa] AS [Configuracion]
INNER JOIN [organizacion].[EmpresaReferencia] AS [Empresa]
    ON [Empresa].[IdUnidadOrganizativaCorporativa] = [Configuracion].[IdUnidadOrganizativaCorporativa]
INNER JOIN [organizacion].[Sede] AS [Sede]
    ON [Sede].[IdEmpresaReferencia] = [Empresa].[IdEmpresaReferencia]

UNION ALL

SELECT
    [Configuracion].[IdUnidadOrganizativaCorporativa],
    [Empresa].[IdEmpresaReferencia],
    [Empresa].[IdEmpresaCorporativa],
    [Empresa].[CodigoEmpresa],
    [Empresa].[RazonSocial],
    CAST(N'AREA' AS NVARCHAR(20)) AS [TipoElemento],
    [Area].[IdArea] AS [IdElemento],
    CAST(NULL AS UNIQUEIDENTIFIER) AS [IdSedePublico],
    [Area].[CodigoArea] AS [CodigoElemento],
    [Area].[NombreArea] AS [NombreElemento],
    [Area].[EstaActiva] AS [EstaActivo]
FROM [organizacion].[ConfiguracionUnidadOrganizativa] AS [Configuracion]
INNER JOIN [organizacion].[EmpresaReferencia] AS [Empresa]
    ON [Empresa].[IdUnidadOrganizativaCorporativa] = [Configuracion].[IdUnidadOrganizativaCorporativa]
INNER JOIN [organizacion].[Area] AS [Area]
    ON [Area].[IdEmpresaReferencia] = [Empresa].[IdEmpresaReferencia]

UNION ALL

SELECT
    [Configuracion].[IdUnidadOrganizativaCorporativa],
    [Empresa].[IdEmpresaReferencia],
    [Empresa].[IdEmpresaCorporativa],
    [Empresa].[CodigoEmpresa],
    [Empresa].[RazonSocial],
    CAST(N'CARGO' AS NVARCHAR(20)) AS [TipoElemento],
    [Cargo].[IdCargo] AS [IdElemento],
    CAST(NULL AS UNIQUEIDENTIFIER) AS [IdSedePublico],
    [Cargo].[CodigoCargo] AS [CodigoElemento],
    [Cargo].[NombreCargo] AS [NombreElemento],
    [Cargo].[EstaActivo] AS [EstaActivo]
FROM [organizacion].[ConfiguracionUnidadOrganizativa] AS [Configuracion]
INNER JOIN [organizacion].[EmpresaReferencia] AS [Empresa]
    ON [Empresa].[IdUnidadOrganizativaCorporativa] = [Configuracion].[IdUnidadOrganizativaCorporativa]
INNER JOIN [organizacion].[Cargo] AS [Cargo]
    ON [Cargo].[IdEmpresaReferencia] = [Empresa].[IdEmpresaReferencia]

UNION ALL

SELECT
    [Configuracion].[IdUnidadOrganizativaCorporativa],
    [Empresa].[IdEmpresaReferencia],
    [Empresa].[IdEmpresaCorporativa],
    [Empresa].[CodigoEmpresa],
    [Empresa].[RazonSocial],
    CAST(N'CARGO_SAP' AS NVARCHAR(20)) AS [TipoElemento],
    [CargoSAP].[IdCargoSAP] AS [IdElemento],
    CAST(NULL AS UNIQUEIDENTIFIER) AS [IdSedePublico],
    [CargoSAP].[CodigoCargoSAP] AS [CodigoElemento],
    [Cargo].[NombreCargo] AS [NombreElemento],
    [CargoSAP].[EstaActivo] AS [EstaActivo]
FROM [organizacion].[ConfiguracionUnidadOrganizativa] AS [Configuracion]
INNER JOIN [organizacion].[EmpresaReferencia] AS [Empresa]
    ON [Empresa].[IdUnidadOrganizativaCorporativa] = [Configuracion].[IdUnidadOrganizativaCorporativa]
INNER JOIN [organizacion].[CargoSAP] AS [CargoSAP]
    ON [CargoSAP].[IdEmpresaReferencia] = [Empresa].[IdEmpresaReferencia]
INNER JOIN [organizacion].[Cargo] AS [Cargo]
    ON [Cargo].[IdEmpresaReferencia] = [CargoSAP].[IdEmpresaReferencia]
   AND [Cargo].[IdCargo] = [CargoSAP].[IdCargo];
GO

CREATE OR ALTER VIEW [organizacion].[vw_JerarquiaCargoConsulta]
AS
SELECT
    [Configuracion].[IdUnidadOrganizativaCorporativa],
    [Empresa].[IdEmpresaReferencia],
    [Empresa].[IdEmpresaCorporativa],
    [Empresa].[CodigoEmpresa],
    [Empresa].[RazonSocial],
    [Jefatura].[IdCargoJefatura],
    [Jefatura].[IdCargoSubordinado],
    [CargoSubordinado].[CodigoCargo] AS [CodigoCargoSubordinado],
    [CargoSubordinado].[NombreCargo] AS [NombreCargoSubordinado],
    [Jefatura].[IdCargoJefe],
    [CargoJefe].[CodigoCargo] AS [CodigoCargoJefe],
    [CargoJefe].[NombreCargo] AS [NombreCargoJefe],
    [Jefatura].[FechaInicio],
    [Jefatura].[FechaFin]
FROM [organizacion].[ConfiguracionUnidadOrganizativa] AS [Configuracion]
INNER JOIN [organizacion].[EmpresaReferencia] AS [Empresa]
    ON [Empresa].[IdUnidadOrganizativaCorporativa] = [Configuracion].[IdUnidadOrganizativaCorporativa]
INNER JOIN [organizacion].[CargoJefatura] AS [Jefatura]
    ON [Jefatura].[IdEmpresaReferencia] = [Empresa].[IdEmpresaReferencia]
INNER JOIN [organizacion].[Cargo] AS [CargoSubordinado]
    ON [CargoSubordinado].[IdEmpresaReferencia] = [Jefatura].[IdEmpresaReferencia]
   AND [CargoSubordinado].[IdCargo] = [Jefatura].[IdCargoSubordinado]
INNER JOIN [organizacion].[Cargo] AS [CargoJefe]
    ON [CargoJefe].[IdEmpresaReferencia] = [Jefatura].[IdEmpresaReferencia]
   AND [CargoJefe].[IdCargo] = [Jefatura].[IdCargoJefe];
GO

CREATE OR ALTER VIEW [rrhh].[vw_ContextoOrganizacionalColaborador]
AS
SELECT
    [Configuracion].[IdUnidadOrganizativaCorporativa],
    [Asignacion].[IdAsignacionOrganizacionalCorporativa],
    [Asignacion].[IdRelacionLaboralCorporativa],
    [Asignacion].[IdColaboradorCorporativo],
    [Asignacion].[IdUnidadOrganizativaOrigenCorporativa],
    [Asignacion].[IdEmpresaEmpleadoraCorporativa],
    [Asignacion].[EstaActiva] AS [EstaActivaAsignacion],
    [EmpresaContexto].[IdEmpresaReferencia] AS [IdEmpresaReferenciaContexto],
    [EmpresaContexto].[IdEmpresaCorporativa] AS [IdEmpresaCorporativaContexto],
    [EmpresaContexto].[CodigoEmpresa] AS [CodigoEmpresaContexto],
    [EmpresaContexto].[RazonSocial] AS [RazonSocialContexto],
    [EmpresaContexto].[EstaActiva] AS [EstaActivaEmpresaContexto],
    [Sede].[IdSede],
    [Sede].[IdSedePublico],
    [Sede].[CodigoSede],
    [Sede].[NombreSede],
    [Sede].[EstaActiva] AS [EstaActivaSede],
    [Area].[IdArea],
    [Area].[CodigoArea],
    [Area].[NombreArea],
    [Area].[EstaActiva] AS [EstaActivaArea],
    [RelacionLaboral].[IdRelacionLaboral] AS [IdRelacionLaboralLocal],
    [RelacionLaboral].[IdEmpresaReferencia] AS [IdEmpresaReferenciaRelacionLaboral],
    [RelacionLaboral].[CodigoColaboradorSAP],
    [RelacionLaboral].[EstaActiva] AS [EstaActivaRelacionLaboral],
    [RelacionLaboral].[FechaIngreso],
    [RelacionLaboral].[FechaCese],
    [CargoSAP].[IdCargoSAP],
    [CargoSAP].[CodigoCargoSAP],
    [CargoSAP].[EstaActivo] AS [EstaActivoCargoSAP],
    [Cargo].[IdCargo],
    [Cargo].[CodigoCargo],
    [Cargo].[NombreCargo],
    [Cargo].[EstaActivo] AS [EstaActivoCargo]
FROM [organizacion].[ConfiguracionUnidadOrganizativa] AS [Configuracion]
INNER JOIN [organizacion].[EmpresaReferencia] AS [EmpresaContexto]
    ON [EmpresaContexto].[IdUnidadOrganizativaCorporativa] = [Configuracion].[IdUnidadOrganizativaCorporativa]
INNER JOIN [rrhh].[AsignacionOrganizacional] AS [Asignacion]
    ON [Asignacion].[IdEmpresaReferencia] = [EmpresaContexto].[IdEmpresaReferencia]
INNER JOIN [organizacion].[Sede] AS [Sede]
    ON [Sede].[IdEmpresaReferencia] = [Asignacion].[IdEmpresaReferencia]
   AND [Sede].[IdSede] = [Asignacion].[IdSede]
INNER JOIN [organizacion].[Area] AS [Area]
    ON [Area].[IdEmpresaReferencia] = [Asignacion].[IdEmpresaReferencia]
   AND [Area].[IdArea] = [Asignacion].[IdArea]
LEFT JOIN [rrhh].[RelacionLaboral] AS [RelacionLaboral]
    ON [RelacionLaboral].[IdRelacionLaboralCorporativa] = [Asignacion].[IdRelacionLaboralCorporativa]
LEFT JOIN [organizacion].[CargoSAP] AS [CargoSAP]
    ON [CargoSAP].[IdEmpresaReferencia] = [RelacionLaboral].[IdEmpresaReferencia]
   AND [CargoSAP].[IdCargoSAP] = [RelacionLaboral].[IdCargoSAP]
LEFT JOIN [organizacion].[Cargo] AS [Cargo]
    ON [Cargo].[IdEmpresaReferencia] = [CargoSAP].[IdEmpresaReferencia]
   AND [Cargo].[IdCargo] = [CargoSAP].[IdCargo];
GO
