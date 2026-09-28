-- Procedimiento: alimentacion.usp_CerrarPlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Cerrar la recepción de reservas de una planificación publicada.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_CerrarPlanificacion]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @IdColaboradorModificacionCorporativo UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdPlanificacion IS NULL OR @IdColaboradorModificacionCorporativo IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'La planificación y el actor corporativo que cierra son obligatorios.';
        RETURN;
    END;

    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @FechaModificacion DATETIME2(3);

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

        IF @EstadoPlanificacion <> N'PUBLICADA_ABIERTA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'INVALID_PLAN_STATE';
            SET @Mensaje = N'La planificación no tiene reservas abiertas para cerrar.';
            RETURN;
        END;

        SET @FechaModificacion = SYSDATETIME();

        UPDATE [alimentacion].[Planificacion]
        SET
            [Estado] = N'PUBLICADA_CERRADA',
            [IdColaboradorModificacionCorporativo] = @IdColaboradorModificacionCorporativo,
            [VersionRegistro] = [VersionRegistro] + 1,
            [FechaModificacion] = @FechaModificacion
        WHERE [IdPlanificacion] = @IdPlanificacionInterno;

        COMMIT TRANSACTION;

        SET @Codigo = N'CLOSED';

        SELECT
            [IdentificadorPublico] AS [IdPlanificacion],
            [Estado], [IdColaboradorModificacionCorporativo], [VersionRegistro], [FechaModificacion]
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
            @NombreProcedimiento = N'alimentacion.usp_CerrarPlanificacion',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO
