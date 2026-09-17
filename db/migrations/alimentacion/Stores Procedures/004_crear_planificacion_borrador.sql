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
    @FechaFin DATE,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    SET @Nombre = NULLIF(LTRIM(RTRIM(@Nombre)), N'');

    IF @IdSede IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'La sede es obligatoria.';
        RETURN;
    END;

    IF @Nombre IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El nombre de la planificación es obligatorio.';
        RETURN;
    END;

    IF @IdColaboradorRegistro IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El colaborador que registra la planificación es obligatorio.';
        RETURN;
    END;

    IF @FechaInicio IS NULL OR @FechaFin IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'Las fechas de inicio y fin son obligatorias.';
        RETURN;
    END;

    IF @FechaFin < @FechaInicio
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'La fecha de fin no puede ser anterior a la fecha de inicio.';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM [organizacion].[Sede] WHERE [IdSede] = @IdSede)
    BEGIN
        SET @Codigo = N'NOT_FOUND';
        SET @Mensaje = N'La sede indicada no existe.';
        RETURN;
    END;
    DECLARE @IdPlanificacionInterno BIGINT;

    BEGIN TRY
        BEGIN TRANSACTION;

    INSERT INTO [alimentacion].[Planificacion] ([IdSede], [IdColaboradorRegistro], [Nombre], [FechaInicio], [FechaFin])
    VALUES (@IdSede, @IdColaboradorRegistro, @Nombre, @FechaInicio, @FechaFin);

    SET @IdPlanificacionInterno = CONVERT(BIGINT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SET @Codigo = N'CREATED';
        SET @Mensaje = NULL;

        SELECT
            [IdentificadorPublico] AS [IdPlanificacion], [IdSede], [Nombre],
            [FechaInicio], [FechaFin], [Estado], [EstaActivo], [IdColaboradorRegistro], [VersionRegistro], [FechaCreacion]
        FROM [alimentacion].[Planificacion]
        WHERE [IdPlanificacion] = @IdPlanificacionInterno;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_CrearPlanificacionBorrador',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO

-- EXEC [alimentacion].[usp_CrearPlanificacionBorrador]
--     @IdSede = 1, @IdColaboradorRegistro = 1, @Nombre = N'Menú septiembre 2026',
--     @FechaInicio = '2026-09-01', @FechaFin = '2026-09-30';
