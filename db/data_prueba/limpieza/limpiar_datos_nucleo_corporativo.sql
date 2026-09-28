-- Limpieza de datos de prueba del núcleo corporativo (CO).
-- No ejecutar contra producción.

SET XACT_ABORT ON;
SET NOCOUNT ON;

IF OBJECT_ID(N'[rrhh].[DocumentoPersona]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[Persona]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[Colaborador]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Empresa]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[UnidadOrganizativa]', N'U') IS NULL
   OR OBJECT_ID(N'[catalogo].[Pais]', N'U') IS NULL
   OR OBJECT_ID(N'[integracion].[PersonalSAPStaging]', N'U') IS NULL
    THROW 51090, N'La base no corresponde al núcleo corporativo de CO.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM [integracion].[PersonalSAPStaging]
    WHERE [IdEventoOrigen] = 'dddddddd-dddd-dddd-dddd-dddddddddddd';

    DELETE [Documento]
    FROM [rrhh].[DocumentoPersona] AS [Documento]
    INNER JOIN [rrhh].[Persona] AS [Persona]
        ON [Persona].[IdPersona] = [Documento].[IdPersona]
    WHERE [Persona].[IdPersonaCorporativa] IN
    (
        '44444444-4444-4444-4444-444444444444',
        '55555555-5555-5555-5555-555555555555'
    );

    DELETE FROM [rrhh].[Colaborador]
    WHERE [IdColaboradorCorporativo] IN
    (
        '66666666-6666-6666-6666-666666666666',
        '77777777-7777-7777-7777-777777777777'
    );

    DELETE FROM [rrhh].[Persona]
    WHERE [IdPersonaCorporativa] IN
    (
        '44444444-4444-4444-4444-444444444444',
        '55555555-5555-5555-5555-555555555555'
    );

    DELETE FROM [organizacion].[Empresa]
    WHERE [IdEmpresaCorporativa] IN
    (
        '22222222-2222-2222-2222-222222222222',
        '33333333-3333-3333-3333-333333333333'
    );

    DELETE FROM [organizacion].[UnidadOrganizativa]
    WHERE [IdUnidadOrganizativaCorporativa] = '11111111-1111-1111-1111-111111111111';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
