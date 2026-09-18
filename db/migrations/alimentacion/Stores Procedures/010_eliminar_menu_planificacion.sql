-- Procedimiento: alimentacion.usp_EliminarMenuPlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Eliminar un menú de una planificación mientras esta se encuentra en BORRADOR.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_EliminarMenuPlanificacion]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @IdMenu UNIQUEIDENTIFIER,
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

    IF @IdMenu IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El identificador de menú es obligatorio.';
        RETURN;
    END;

    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @IdMenuInterno BIGINT;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @FechaServicio DATE;
    DECLARE @TipoServicio NVARCHAR(20);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @IdPlanificacionInterno = [Planificacion].[IdPlanificacion],
            @EstadoPlanificacion = [Planificacion].[Estado]
        FROM [alimentacion].[Planificacion] AS [Planificacion] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Planificacion].[IdentificadorPublico] = @IdPlanificacion;

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
            SET @Mensaje = N'La planificación no permite eliminar menús.';
            RETURN;
        END;

        SELECT
            @IdMenuInterno = [Menu].[IdMenu],
            @FechaServicio = [Menu].[FechaServicio],
            @TipoServicio = [Menu].[TipoServicio]
        FROM [alimentacion].[Menu] AS [Menu] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Menu].[IdentificadorPublico] = @IdMenu
          AND [Menu].[IdPlanificacion] = @IdPlanificacionInterno;

        IF @IdMenuInterno IS NULL
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'MENU_NOT_FOUND';
            SET @Mensaje = N'El menú indicado no existe en la planificación.';
            RETURN;
        END;

        DELETE FROM [alimentacion].[Menu]
        WHERE [IdMenu] = @IdMenuInterno;

        COMMIT TRANSACTION;

        SET @Codigo = N'SUCCESS';
        SET @Mensaje = NULL;

        SELECT
            @IdMenu AS [IdMenu],
            @IdPlanificacion AS [IdPlanificacion],
            @FechaServicio AS [FechaServicio],
            @TipoServicio AS [TipoServicio];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_EliminarMenuPlanificacion',
            @NumeroError = @NumeroErrorCapturado,
            @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado,
            @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO

-- DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
-- EXEC [alimentacion].[usp_EliminarMenuPlanificacion]
--     @IdPlanificacion = '00000000-0000-0000-0000-000000000000',
--     @IdMenu = '00000000-0000-0000-0000-000000000000',
--     @Codigo = @Codigo OUTPUT,
--     @Mensaje = @Mensaje OUTPUT;
