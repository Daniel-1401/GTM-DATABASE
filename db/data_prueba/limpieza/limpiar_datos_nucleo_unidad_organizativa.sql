-- Limpieza acotada del escenario determinista de prueba de una instancia hija UO.
-- No elimina datos ajenos ni resecuencia identidades. No ejecutar contra producción.
-- Marcadores: corresponden a la futura semilla de la instancia UO GI.

SET XACT_ABORT ON;
SET NOCOUNT ON;

DECLARE @Uo UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @EmpresaGolden UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';
DECLARE @EmpresaOperaciones UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333333';
DECLARE @RelacionAna UNIQUEIDENTIFIER = '88888888-8888-8888-8888-888888888888';
DECLARE @RelacionBruno UNIQUEIDENTIFIER = '99999999-9999-9999-9999-999999999999';
DECLARE @AsignacionAna UNIQUEIDENTIFIER = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
DECLARE @AsignacionBruno UNIQUEIDENTIFIER = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
DECLARE @Postulante UNIQUEIDENTIFIER = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

IF OBJECT_ID(N'[rrhh].[VigenciaHorario]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[RelacionLaboral]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[AsignacionOrganizacional]', N'U') IS NULL
   OR OBJECT_ID(N'[rrhh].[HorarioLaboral]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[ConfiguracionUnidadOrganizativa]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[EmpresaReferencia]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Sede]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Area]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Cargo]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[CargoSAP]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[CargoJefatura]', N'U') IS NULL
   OR OBJECT_ID(N'[seleccion].[Postulante]', N'U') IS NULL
   OR OBJECT_ID(N'[seleccion].[ArchivoPostulante]', N'U') IS NULL
   OR OBJECT_ID(N'[seleccion].[HistorialEstadoPostulante]', N'U') IS NULL
    THROW 51091, N'La base no corresponde a una instancia hija de unidad organizativa.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE [Historial]
    FROM [seleccion].[HistorialEstadoPostulante] AS [Historial]
    INNER JOIN [seleccion].[Postulante] AS [Postulante]
        ON [Postulante].[IdPostulante] = [Historial].[IdPostulante]
    WHERE [Postulante].[IdentificadorPublico] = @Postulante;

    DELETE [Archivo]
    FROM [seleccion].[ArchivoPostulante] AS [Archivo]
    INNER JOIN [seleccion].[Postulante] AS [Postulante]
        ON [Postulante].[IdPostulante] = [Archivo].[IdPostulante]
    WHERE [Postulante].[IdentificadorPublico] = @Postulante;

    DELETE FROM [seleccion].[Postulante]
    WHERE [IdentificadorPublico] = @Postulante;

    DELETE [Vigencia]
    FROM [rrhh].[VigenciaHorario] AS [Vigencia]
    INNER JOIN [rrhh].[RelacionLaboral] AS [Relacion]
        ON [Relacion].[IdRelacionLaboral] = [Vigencia].[IdRelacionLaboral]
    WHERE [Relacion].[IdRelacionLaboralCorporativa] IN (@RelacionAna, @RelacionBruno);

    DELETE FROM [rrhh].[AsignacionOrganizacional]
    WHERE [IdAsignacionOrganizacionalCorporativa] IN (@AsignacionAna, @AsignacionBruno);

    DELETE FROM [rrhh].[RelacionLaboral]
    WHERE [IdRelacionLaboralCorporativa] IN (@RelacionAna, @RelacionBruno);

    DECLARE @IdGolden INT =
        (SELECT [IdEmpresaReferencia] FROM [organizacion].[EmpresaReferencia] WHERE [IdEmpresaCorporativa] = @EmpresaGolden);
    DECLARE @IdOperaciones INT =
        (SELECT [IdEmpresaReferencia] FROM [organizacion].[EmpresaReferencia] WHERE [IdEmpresaCorporativa] = @EmpresaOperaciones);

    DELETE [Jefatura]
    FROM [organizacion].[CargoJefatura] AS [Jefatura]
    INNER JOIN [organizacion].[Cargo] AS [Subordinado]
        ON [Subordinado].[IdCargo] = [Jefatura].[IdCargoSubordinado]
       AND [Subordinado].[IdEmpresaReferencia] = [Jefatura].[IdEmpresaReferencia]
    INNER JOIN [organizacion].[Cargo] AS [Jefe]
        ON [Jefe].[IdCargo] = [Jefatura].[IdCargoJefe]
       AND [Jefe].[IdEmpresaReferencia] = [Jefatura].[IdEmpresaReferencia]
    WHERE [Jefatura].[IdEmpresaReferencia] = @IdGolden
      AND [Subordinado].[CodigoCargo] = N'ANL-TI'
      AND [Jefe].[CodigoCargo] = N'JEF-TI'
      AND [Jefatura].[FechaInicio] = '2020-01-01'
      AND [Jefatura].[FechaFin] IS NULL;

    DELETE FROM [organizacion].[CargoSAP]
    WHERE ([IdEmpresaReferencia] = @IdGolden AND [CodigoCargoSAP] = N'SAP-ANL-TI')
       OR ([IdEmpresaReferencia] = @IdOperaciones AND [CodigoCargoSAP] = N'SAP-SUP-OPS');

    DELETE FROM [rrhh].[HorarioLaboral]
    WHERE ([IdEmpresaReferencia] = @IdGolden AND [CodigoHorarioGTM] = N'HOR-ADM')
       OR ([IdEmpresaReferencia] = @IdOperaciones AND [CodigoHorarioGTM] = N'HOR-OPS');

    DELETE FROM [organizacion].[Cargo]
    WHERE ([IdEmpresaReferencia] = @IdGolden AND [CodigoCargo] IN (N'ANL-TI', N'JEF-TI'))
       OR ([IdEmpresaReferencia] = @IdOperaciones AND [CodigoCargo] = N'SUP-OPS');

    DELETE FROM [organizacion].[Area]
    WHERE ([IdEmpresaReferencia] = @IdGolden AND [CodigoArea] = N'TI')
       OR ([IdEmpresaReferencia] = @IdOperaciones AND [CodigoArea] = N'OPS');

    DELETE FROM [organizacion].[Sede]
    WHERE [IdEmpresaReferencia] IN (@IdGolden, @IdOperaciones)
      AND [CodigoSede] = N'SED-PRUEBA';

    DELETE FROM [organizacion].[EmpresaReferencia]
    WHERE [IdEmpresaCorporativa] IN (@EmpresaGolden, @EmpresaOperaciones);

    IF EXISTS
    (
        SELECT 1
        FROM [organizacion].[EmpresaReferencia]
        WHERE [IdUnidadOrganizativaCorporativa] = @Uo
    )
        THROW 51092, N'La configuración de prueba tiene empresas ajenas; se revierte la limpieza para preservar datos.', 1;

    DELETE FROM [organizacion].[ConfiguracionUnidadOrganizativa]
    WHERE [IdUnidadOrganizativaCorporativa] = @Uo;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
