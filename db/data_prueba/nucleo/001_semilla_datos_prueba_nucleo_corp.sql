-- Semilla de datos de prueba: núcleo CORP.
-- Motor objetivo: Microsoft SQL Server 2017.
-- Ejecutar únicamente después de las migraciones del núcleo corporativo.
-- Esta semilla no crea datos de personas, colaboradores, SAP ni de una instancia UO.
-- La semilla de la instancia UO GI se entregará en un archivo separado.
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @UoGi UNIQUEIDENTIFIER = '951D0A81-2F8D-4360-9E02-62D0F1475B95';
DECLARE @UoNc UNIQUEIDENTIFIER = '6F31364A-E6A5-48FD-9BB7-6C4FAF6B2AA4';
DECLARE @EmpresaGoldenPalace UNIQUEIDENTIFIER = '958C9697-66DB-481C-854E-CC2310B27B28';
DECLARE @EmpresaNewportCapital UNIQUEIDENTIFIER = '9220341B-9615-4CB5-9925-AD9BFB10E601';

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO [catalogo].[Genero] ([CodigoGenero], [NombreGenero])
    SELECT [CodigoGenero], [NombreGenero]
    FROM (VALUES
        (N'F', N'Femenino'),
        (N'M', N'Masculino')
    ) AS [Semilla] ([CodigoGenero], [NombreGenero])
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [catalogo].[Genero] AS [Existente]
        WHERE [Existente].[CodigoGenero] = [Semilla].[CodigoGenero]
    );

    INSERT INTO [catalogo].[EstadoCivil] ([CodigoEstadoCivil], [NombreEstadoCivil])
    SELECT [CodigoEstadoCivil], [NombreEstadoCivil]
    FROM (VALUES
        (N'SOLTERO', N'Soltero'),
        (N'CASADO', N'Casado'),
        (N'DIVORCIADO', N'Divorciado'),
        (N'VIUDO', N'Viudo'),
        (N'CONVIVIENTE', N'Conviviente')
    ) AS [Semilla] ([CodigoEstadoCivil], [NombreEstadoCivil])
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [catalogo].[EstadoCivil] AS [Existente]
        WHERE [Existente].[CodigoEstadoCivil] = [Semilla].[CodigoEstadoCivil]
    );

    INSERT INTO [catalogo].[Pais] ([CodigoPais], [NombrePais])
    SELECT 'PE', N'Perú'
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [catalogo].[Pais] AS [Existente]
        WHERE [Existente].[CodigoPais] = 'PE'
    );

    INSERT INTO [catalogo].[TipoDocumento] ([CodigoTipoDocumento], [NombreTipoDocumento])
    SELECT [CodigoTipoDocumento], [NombreTipoDocumento]
    FROM (VALUES
        (N'DNI', N'Documento Nacional de Identidad'),
        (N'CE', N'Carné de Extranjería'),
        (N'PASAPORTE', N'Pasaporte')
    ) AS [Semilla] ([CodigoTipoDocumento], [NombreTipoDocumento])
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [catalogo].[TipoDocumento] AS [Existente]
        WHERE [Existente].[CodigoTipoDocumento] = [Semilla].[CodigoTipoDocumento]
    );

    INSERT INTO [organizacion].[UnidadOrganizativa]
    (
        [IdUnidadOrganizativaCorporativa],
        [CodigoUnidadOrganizativa],
        [NombreUnidadOrganizativa]
    )
    SELECT [IdUnidadOrganizativaCorporativa], [CodigoUnidadOrganizativa], [NombreUnidadOrganizativa]
    FROM (VALUES
        (@UoGi, N'GI', N'GI'),
        (@UoNc, N'NC', N'NC')
    ) AS [Semilla]
    (
        [IdUnidadOrganizativaCorporativa],
        [CodigoUnidadOrganizativa],
        [NombreUnidadOrganizativa]
    )
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [organizacion].[UnidadOrganizativa] AS [Existente]
        WHERE [Existente].[CodigoUnidadOrganizativa] = [Semilla].[CodigoUnidadOrganizativa]
    );

    DECLARE @IdUoGi INT =
    (
        SELECT [IdUnidadOrganizativa]
        FROM [organizacion].[UnidadOrganizativa]
        WHERE [CodigoUnidadOrganizativa] = N'GI'
    );
    DECLARE @IdUoNc INT =
    (
        SELECT [IdUnidadOrganizativa]
        FROM [organizacion].[UnidadOrganizativa]
        WHERE [CodigoUnidadOrganizativa] = N'NC'
    );

    INSERT INTO [organizacion].[Empresa]
    (
        [IdEmpresaCorporativa],
        [IdUnidadOrganizativa],
        [CodigoEmpresa],
        [RazonSocial]
    )
    SELECT [IdEmpresaCorporativa], [IdUnidadOrganizativa], [CodigoEmpresa], [RazonSocial]
    FROM (VALUES
        (@EmpresaGoldenPalace, @IdUoGi, N'GI', N'Golden Investment S.A.'),
        (@EmpresaNewportCapital, @IdUoNc, N'NC', N'Newport Capital S.A.C.')
    ) AS [Semilla]
    (
        [IdEmpresaCorporativa],
        [IdUnidadOrganizativa],
        [CodigoEmpresa],
        [RazonSocial]
    )
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [organizacion].[Empresa] AS [Existente]
        WHERE [Existente].[CodigoEmpresa] = [Semilla].[CodigoEmpresa]
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
