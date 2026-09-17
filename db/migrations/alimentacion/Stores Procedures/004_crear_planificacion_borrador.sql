-- Procedimiento: alimentacion.usp_CrearPlanificacionBorrador
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Crear la cabecera de una planificación en BORRADOR antes de registrar sus menús.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_CrearPlanificacionBorrador]
    @IdSede INT,
    @IdColaboradorRegistro BIGINT,
    @Nombre NVARCHAR(200),
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Nombre = NULLIF(LTRIM(RTRIM(@Nombre)), N'');

    IF @IdSede IS NULL
    BEGIN
        ;THROW 50200, N'La sede es obligatoria.', 1;
    END;

    IF @Nombre IS NULL
    BEGIN
        ;THROW 50201, N'El nombre de la planificación es obligatorio.', 1;
    END;

    IF @IdColaboradorRegistro IS NULL
    BEGIN
        ;THROW 50205, N'El colaborador que registra la planificacion es obligatorio.', 1;
    END;

    IF @FechaInicio IS NULL OR @FechaFin IS NULL
    BEGIN
        ;THROW 50202, N'Las fechas de inicio y fin son obligatorias.', 1;
    END;

    IF @FechaFin < @FechaInicio
    BEGIN
        ;THROW 50203, N'La fecha de fin no puede ser anterior a la fecha de inicio.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM [organizacion].[Sede] WHERE [IdSede] = @IdSede)
    BEGIN
        ;THROW 50204, N'La sede indicada no existe.', 1;
    END;
    IF NOT EXISTS (SELECT 1 FROM [rrhh].[Colaborador] WHERE [IdColaborador] = @IdColaboradorRegistro)
    BEGIN
        ;THROW 50206, N'El colaborador que registra la planificacion no existe.', 1;
    END;

    DECLARE @IdPlanificacionInterno BIGINT;

    BEGIN TRANSACTION;

    INSERT INTO [alimentacion].[Planificacion] ([IdSede], [IdColaboradorRegistro], [Nombre], [FechaInicio], [FechaFin])
    VALUES (@IdSede, @IdColaboradorRegistro, @Nombre, @FechaInicio, @FechaFin);

    SET @IdPlanificacionInterno = CONVERT(BIGINT, SCOPE_IDENTITY());

    COMMIT TRANSACTION;

    SELECT
        [IdentificadorPublico] AS [IdPlanificacion], [IdSede], [Nombre],
        [FechaInicio], [FechaFin], [Estado], [EstaActivo], [IdColaboradorRegistro], [VersionRegistro], [FechaCreacionUtc]
    FROM [alimentacion].[Planificacion]
    WHERE [IdPlanificacion] = @IdPlanificacionInterno;
END;
GO

-- EXEC [alimentacion].[usp_CrearPlanificacionBorrador]
--     @IdSede = 1, @IdColaboradorRegistro = 1, @Nombre = N'Menú septiembre 2026',
--     @FechaInicio = '2026-09-01', @FechaFin = '2026-09-30';
