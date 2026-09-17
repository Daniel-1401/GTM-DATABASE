-- Procedimiento: alimentacion.usp_EliminarPlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Retirar lógicamente una planificación en BORRADOR sin borrar su historial.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_EliminarPlanificacion]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdPlanificacion IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El identificador de planificación es obligatorio.';
        RETURN;
    END;
    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @FechaEliminacion DATETIME2(3);

    BEGIN TRY
        BEGIN TRANSACTION;

    SELECT
        @IdPlanificacionInterno = [IdPlanificacion],
        @EstadoPlanificacion = [Estado]
    FROM [alimentacion].[Planificacion] WITH (UPDLOCK, HOLDLOCK)
    WHERE [IdentificadorPublico] = @IdPlanificacion;

    IF @IdPlanificacionInterno IS NULL
    BEGIN
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @Codigo = N'PLAN_NOT_FOUND';
        SET @Mensaje = N'La planificación indicada no existe.';
        RETURN;
    END;

    IF @EstadoPlanificacion = N'ELIMINADA'
    BEGIN
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @Codigo = N'STATE_CONFLICT';
        SET @Mensaje = N'La planificación ya fue eliminada.';
        RETURN;
    END;

    IF @EstadoPlanificacion <> N'BORRADOR'
    BEGIN
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @Codigo = N'INVALID_PLAN_STATE';
        SET @Mensaje = N'La planificación no permite esta operación.';
        RETURN;
    END;

    SET @FechaEliminacion = SYSDATETIME();

    UPDATE [Componente]
    SET [EstaActivo] = 0
    FROM [alimentacion].[ComponenteMenu] AS [Componente]
    INNER JOIN [alimentacion].[Menu] AS [Menu]
        ON [Menu].[IdMenu] = [Componente].[IdMenu]
    WHERE [Menu].[IdPlanificacion] = @IdPlanificacionInterno
      AND [Componente].[EstaActivo] = 1;

    UPDATE [alimentacion].[Menu]
    SET
        [EstaActivo] = 0,
        [VersionRegistro] = [VersionRegistro] + 1,
        [FechaModificacion] = @FechaEliminacion
    WHERE [IdPlanificacion] = @IdPlanificacionInterno
      AND [EstaActivo] = 1;

    UPDATE [alimentacion].[Planificacion]
    SET
        [Estado] = N'ELIMINADA',
        [EstaActivo] = 0,
        [VersionRegistro] = [VersionRegistro] + 1,
        [FechaModificacion] = @FechaEliminacion
    WHERE [IdPlanificacion] = @IdPlanificacionInterno;

        COMMIT TRANSACTION;

        SET @Codigo = N'SUCCESS';
        SET @Mensaje = NULL;

        SELECT
            [IdentificadorPublico] AS [IdPlanificacion],
            [Estado],
            [EstaActivo],
            [VersionRegistro],
            [FechaModificacion]
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
            @NombreProcedimiento = N'alimentacion.usp_EliminarPlanificacion',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO

-- EXEC [alimentacion].[usp_EliminarPlanificacion]
--     @IdPlanificacion = '00000000-0000-0000-0000-000000000000';
