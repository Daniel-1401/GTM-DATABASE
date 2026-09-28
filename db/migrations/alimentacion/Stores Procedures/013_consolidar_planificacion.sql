-- Procedimiento: alimentacion.usp_ConsolidarPlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Consolidar de forma irreversible las reservas activas de una planificación cerrada.
-- Ejecutar después de las migraciones 010 y 011.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ConsolidarPlanificacion]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @IdActorColaboradorCorporativo UNIQUEIDENTIFIER,
    @IdCorrelacion UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdPlanificacion IS NULL OR @IdActorColaboradorCorporativo IS NULL OR @IdCorrelacion IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'La planificación, el actor y la correlación son obligatorios.';
        RETURN;
    END;

    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @IdConsolidacionExistente BIGINT;
    DECLARE @IdConsolidacionPlanificacion BIGINT;
    DECLARE @FechaConsolidacion DATETIME2(3);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @IdConsolidacionExistente = [ConsolidacionPlanificacion].[IdConsolidacionPlanificacion]
        FROM [alimentacion].[ConsolidacionPlanificacion] AS [ConsolidacionPlanificacion] WITH (UPDLOCK, HOLDLOCK)
        WHERE [ConsolidacionPlanificacion].[IdCorrelacion] = @IdCorrelacion;

        IF @IdConsolidacionExistente IS NOT NULL
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'CORRELATION_CONFLICT';
            SET @Mensaje = N'La correlación indicada ya fue utilizada.';
            RETURN;
        END;

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

        IF @EstadoPlanificacion <> N'PUBLICADA_CERRADA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'INVALID_PLAN_STATE';
            SET @Mensaje = N'La planificación debe estar publicada y cerrada para consolidarse.';
            RETURN;
        END;

        SET @FechaConsolidacion = SYSDATETIME();

        INSERT INTO [alimentacion].[ConsolidacionPlanificacion]
        (
            [IdPlanificacion], [IdActorColaboradorCorporativo], [EstadoAnterior], [VersionPlanificacion],
            [FechaConsolidacion], [IdCorrelacion]
        )
        SELECT
            @IdPlanificacionInterno, @IdActorColaboradorCorporativo, N'PUBLICADA_CERRADA',
            [Planificacion].[VersionRegistro], @FechaConsolidacion, @IdCorrelacion
        FROM [alimentacion].[Planificacion] AS [Planificacion]
        WHERE [Planificacion].[IdPlanificacion] = @IdPlanificacionInterno;

        SET @IdConsolidacionPlanificacion = CONVERT(BIGINT, SCOPE_IDENTITY());

        INSERT INTO [alimentacion].[CantidadConsolidadaMenu]
        (
            [IdConsolidacionPlanificacion], [IdPlanificacion], [IdMenu], [CantidadReservas]
        )
        SELECT
            @IdConsolidacionPlanificacion,
            @IdPlanificacionInterno,
            [Menu].[IdMenu],
            COUNT([Reserva].[IdReserva])
        FROM [alimentacion].[Menu] AS [Menu] WITH (UPDLOCK, HOLDLOCK)
        LEFT JOIN [alimentacion].[Reserva] AS [Reserva] WITH (UPDLOCK, HOLDLOCK)
            ON [Reserva].[IdPlanificacion] = [Menu].[IdPlanificacion]
           AND [Reserva].[IdMenu] = [Menu].[IdMenu]
           AND [Reserva].[Estado] = N'RESERVADA'
        WHERE [Menu].[IdPlanificacion] = @IdPlanificacionInterno
          AND [Menu].[EstaActivo] = 1
        GROUP BY [Menu].[IdMenu];

        UPDATE [alimentacion].[Planificacion]
        SET
            [Estado] = N'CONSOLIDADA',
            [IdColaboradorModificacionCorporativo] = @IdActorColaboradorCorporativo,
            [VersionRegistro] = [VersionRegistro] + 1,
            [FechaModificacion] = @FechaConsolidacion
        WHERE [IdPlanificacion] = @IdPlanificacionInterno;

        COMMIT TRANSACTION;

        SET @Codigo = N'CONSOLIDATED';

        SELECT
            [Consolidacion].[IdConsolidacionPlanificacion],
            [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
            [Consolidacion].[IdActorColaboradorCorporativo],
            [Consolidacion].[EstadoAnterior],
            [Consolidacion].[VersionPlanificacion],
            [Consolidacion].[FechaConsolidacion],
            [Consolidacion].[IdCorrelacion],
            [Planificacion].[Estado] AS [EstadoPlanificacion],
            [Planificacion].[VersionRegistro] AS [VersionPlanificacionActual]
        FROM [alimentacion].[ConsolidacionPlanificacion] AS [Consolidacion]
        INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Consolidacion].[IdPlanificacion]
        WHERE [Consolidacion].[IdConsolidacionPlanificacion] = @IdConsolidacionPlanificacion;

        SELECT
            [Menu].[IdentificadorPublico] AS [IdMenu],
            [Menu].[FechaServicio], [Menu].[TipoServicio], [Menu].[EstaDisponible],
            [CantidadConsolidadaMenu].[CantidadReservas]
        FROM [alimentacion].[CantidadConsolidadaMenu] AS [CantidadConsolidadaMenu]
        INNER JOIN [alimentacion].[Menu] AS [Menu]
            ON [Menu].[IdMenu] = [CantidadConsolidadaMenu].[IdMenu]
           AND [Menu].[IdPlanificacion] = [CantidadConsolidadaMenu].[IdPlanificacion]
        WHERE [CantidadConsolidadaMenu].[IdConsolidacionPlanificacion] = @IdConsolidacionPlanificacion
        ORDER BY [Menu].[FechaServicio], [Menu].[TipoServicio];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ConsolidarPlanificacion',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO
