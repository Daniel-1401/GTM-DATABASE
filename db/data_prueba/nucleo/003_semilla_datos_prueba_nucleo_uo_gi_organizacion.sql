-- Semilla de datos de prueba: instancia hija UO GI.
-- Instancia hija: @GSBEDEV01/GI.
-- Instancia corporativa de referencia: @GSDBDEV01/CO.
-- Motor objetivo: Microsoft SQL Server 2017.
-- Fuente de áreas: db/csv_data/areas.csv.
-- Esta semilla solo crea configuración UO, empresa referencia, áreas y sede.
-- Las demás tablas se cargarán en una semilla posterior.

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @IdConfiguracionUnidadOrganizativa TINYINT = 1;
DECLARE @IdUnidadOrganizativaCorporativa UNIQUEIDENTIFIER = '951D0A81-2F8D-4360-9E02-62D0F1475B95';
DECLARE @IdEmpresaCorporativa UNIQUEIDENTIFIER = '958C9697-66DB-481C-854E-CC2310B27B28';

IF @IdUnidadOrganizativaCorporativa = '00000000-0000-0000-0000-000000000000'
    THROW 51000, N'Debe reemplazar el UUID de la unidad organizativa GI.', 1;

IF @IdEmpresaCorporativa = '00000000-0000-0000-0000-000000000000'
    THROW 51001, N'Debe reemplazar el UUID corporativo de la empresa GI.', 1;

DECLARE @Areas TABLE
(
    [CodigoArea] NVARCHAR(30) NOT NULL,
    [NombreArea] NVARCHAR(150) NOT NULL
);

INSERT INTO @Areas ([CodigoArea], [NombreArea])
VALUES
    (N'GI-AREA-1', N'ADMINISTRACION'),
    (N'GI-AREA-2', N'LOGISTICA'),
    (N'GI-AREA-3', N'ANALISIS Y ESTADISTICA'),
    (N'GI-AREA-4', N'AUDITORIA'),
    (N'GI-AREA-5', N'OPERACIONES'),
    (N'GI-AREA-6', N'CAMARAS'),
    (N'GI-AREA-7', N'CONTABILIDAD'),
    (N'GI-AREA-8', N'FINANZAS'),
    (N'GI-AREA-9', N'GERENCIA'),
    (N'GI-AREA-10', N'CUMPLIMIENTO'),
    (N'GI-AREA-11', N'LEGAL'),
    (N'GI-AREA-12', N'MARKETING'),
    (N'GI-AREA-13', N'RRHH'),
    (N'GI-AREA-14', N'TI');

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [organizacion].[ConfiguracionUnidadOrganizativa]
        WHERE [IdConfiguracionUnidadOrganizativa] = @IdConfiguracionUnidadOrganizativa
    )
    BEGIN
        INSERT INTO [organizacion].[ConfiguracionUnidadOrganizativa]
        (
            [IdConfiguracionUnidadOrganizativa],
            [IdUnidadOrganizativaCorporativa]
        )
        VALUES
        (
            @IdConfiguracionUnidadOrganizativa,
            @IdUnidadOrganizativaCorporativa
        );
    END;

    DECLARE @IdUnidadOrganizativaCorporativaConfigurada UNIQUEIDENTIFIER =
    (
        SELECT [IdUnidadOrganizativaCorporativa]
        FROM [organizacion].[ConfiguracionUnidadOrganizativa]
        WHERE [IdConfiguracionUnidadOrganizativa] = @IdConfiguracionUnidadOrganizativa
    );

    IF NOT EXISTS
    (
        SELECT 1
        FROM [organizacion].[EmpresaReferencia]
        WHERE [CodigoEmpresa] = N'GI'
    )
    BEGIN
        INSERT INTO [organizacion].[EmpresaReferencia]
        (
            [IdEmpresaCorporativa],
            [IdUnidadOrganizativaCorporativa],
            [CodigoEmpresa],
            [RazonSocial]
        )
        VALUES
        (
            @IdEmpresaCorporativa,
            @IdUnidadOrganizativaCorporativaConfigurada,
            N'GI',
            N'Golden Investment S.A.'
        );
    END;

    DECLARE @IdEmpresaReferencia INT =
    (
        SELECT [IdEmpresaReferencia]
        FROM [organizacion].[EmpresaReferencia]
        WHERE [CodigoEmpresa] = N'GI'
    );

    INSERT INTO [organizacion].[Area]
    (
        [IdEmpresaReferencia],
        [CodigoArea],
        [NombreArea]
    )
    SELECT
        @IdEmpresaReferencia,
        [area].[CodigoArea],
        [area].[NombreArea]
    FROM @Areas AS [area]
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [organizacion].[Area] AS [existente]
        WHERE [existente].[IdEmpresaReferencia] = @IdEmpresaReferencia
          AND [existente].[CodigoArea] = [area].[CodigoArea]
    );

    IF NOT EXISTS
    (
        SELECT 1
        FROM [organizacion].[Sede]
        WHERE [IdEmpresaReferencia] = @IdEmpresaReferencia
          AND [CodigoSede] = N'01'
    )
    BEGIN
        INSERT INTO [organizacion].[Sede]
        (
            [IdEmpresaReferencia],
            [CodigoSede],
            [NombreSede]
        )
        VALUES
        (
            @IdEmpresaReferencia,
            N'01',
            N'Golden Palace'
        );
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
