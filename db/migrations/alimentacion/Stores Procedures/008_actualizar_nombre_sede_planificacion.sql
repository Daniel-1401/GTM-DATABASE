-- Procedimiento: alimentacion.usp_ActualizarNombreSedePlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Editar el nombre y la sede de una planificación mientras se encuentra en BORRADOR.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ActualizarNombreSedePlanificacion]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @IdSede INT,
    @Nombre NVARCHAR(200),
    @IdColaboradorModificacion BIGINT,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;
    SET @Nombre = NULLIF(LTRIM(RTRIM(@Nombre)), N'');

    IF @IdPlanificacion IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El identificador de planificación es obligatorio.';
        RETURN;
    END;

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

    IF @IdColaboradorModificacion IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El colaborador que realiza la modificación es obligatorio.';
        RETURN;
    END;

    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @FechaModificacion DATETIME2(3);

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

        IF NOT EXISTS
        (
            SELECT 1
            FROM [rrhh].[Colaborador]
            WHERE [IdColaborador] = @IdColaboradorModificacion
        )
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'NOT_FOUND';
            SET @Mensaje = N'El colaborador que realiza la modificación no existe.';
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM [organizacion].[Sede]
            WHERE [IdSede] = @IdSede
              AND [EstaActiva] = 1
        )
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'NOT_FOUND';
            SET @Mensaje = N'La sede indicada no existe o está inactiva.';
            RETURN;
        END;

        SET @FechaModificacion = SYSDATETIME();

        UPDATE [alimentacion].[Planificacion]
        SET
            [IdSede] = @IdSede,
            [Nombre] = @Nombre,
            [IdColaboradorModificacion] = @IdColaboradorModificacion,
            [VersionRegistro] = [VersionRegistro] + 1,
            [FechaModificacion] = @FechaModificacion
        WHERE [IdPlanificacion] = @IdPlanificacionInterno;

        COMMIT TRANSACTION;

        SET @Codigo = N'UPDATED';
        SET @Mensaje = NULL;

        SELECT
            [IdentificadorPublico] AS [IdPlanificacion],
            [IdSede],
            [Nombre],
            [IdColaboradorModificacion],
            [Estado],
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
            @NombreProcedimiento = N'alimentacion.usp_ActualizarNombreSedePlanificacion',
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
-- EXEC [alimentacion].[usp_ActualizarNombreSedePlanificacion]
--     @IdPlanificacion = '00000000-0000-0000-0000-000000000000',
--     @IdSede = 1,
--     @Nombre = N'Menú septiembre 2026',
--     @IdColaboradorModificacion = 1,
--     @Codigo = @Codigo OUTPUT,
--     @Mensaje = @Mensaje OUTPUT;
