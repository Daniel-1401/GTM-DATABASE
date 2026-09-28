-- Procedimiento: alimentacion.usp_CancelarReservaPropia
-- Referencias: migraciones 010 y 011; procedimientos 012 y 013.
-- Motivo: cancelar una reserva propia activa sin eliminarla ni reactivarla.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_CancelarReservaPropia]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @IdReserva UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdColaboradorCorporativo IS NULL OR @IdReserva IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'La identidad corporativa del colaborador y la reserva son obligatorios.';
        RETURN;
    END;

    DECLARE @IdReservaInterno BIGINT;
    DECLARE @IdReservaInicial BIGINT;
    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @IdPlanificacionInicial BIGINT;
    DECLARE @EstadoReserva NVARCHAR(20);
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @IdColaboradorReservaCorporativo UNIQUEIDENTIFIER;
    DECLARE @FechaModificacion DATETIME2(3);

    SELECT
        @IdReservaInicial = [Reserva].[IdReserva],
        @IdPlanificacionInicial = [Reserva].[IdPlanificacion]
    FROM [alimentacion].[Reserva] AS [Reserva]
    WHERE [Reserva].[IdentificadorPublico] = @IdReserva;

    IF @IdReservaInicial IS NULL
    BEGIN
        SET @Codigo = N'RESERVATION_NOT_FOUND';
        SET @Mensaje = N'La reserva indicada no existe.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- El orden Planificacion -> Reserva coincide con cierre y consolidacion.
        SELECT
            @EstadoPlanificacion = [Planificacion].[Estado]
        FROM [alimentacion].[Planificacion] AS [Planificacion] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Planificacion].[IdPlanificacion] = @IdPlanificacionInicial;

        SELECT
            @IdReservaInterno = [Reserva].[IdReserva],
            @IdPlanificacionInterno = [Reserva].[IdPlanificacion],
            @IdColaboradorReservaCorporativo = [Reserva].[IdColaboradorCorporativo],
            @EstadoReserva = [Reserva].[Estado]
        FROM [alimentacion].[Reserva] AS [Reserva] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Reserva].[IdentificadorPublico] = @IdReserva;

        IF @IdReservaInterno IS NULL
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'RESERVATION_NOT_FOUND';
            SET @Mensaje = N'La reserva indicada no existe.';
            RETURN;
        END;

        IF @IdColaboradorReservaCorporativo <> @IdColaboradorCorporativo
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'NOT_OWNER';
            SET @Mensaje = N'La reserva no pertenece al colaborador indicado.';
            RETURN;
        END;

        IF @EstadoReserva = N'CANCELADA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'IDEMPOTENT_REPLAY';
            SET @Mensaje = N'La reserva ya estaba cancelada.';

            SELECT
                [Reserva].[IdentificadorPublico] AS [IdReserva],
                [Menu].[IdentificadorPublico] AS [IdMenu],
                [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
                [Reserva].[IdSede],
                [Reserva].[FechaServicio],
                [Reserva].[TipoServicio],
                [Reserva].[Estado],
                [Reserva].[FechaCreacion],
                [Reserva].[FechaModificacion]
            FROM [alimentacion].[Reserva] AS [Reserva]
            INNER JOIN [alimentacion].[Menu] AS [Menu]
                ON [Menu].[IdMenu] = [Reserva].[IdMenu]
               AND [Menu].[IdPlanificacion] = [Reserva].[IdPlanificacion]
               AND [Menu].[FechaServicio] = [Reserva].[FechaServicio]
               AND [Menu].[TipoServicio] = [Reserva].[TipoServicio]
            INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
                ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
            WHERE [Reserva].[IdReserva] = @IdReservaInterno;
            RETURN;
        END;

        IF @EstadoReserva IN (N'ENTREGADA', N'NO_RECOGIDA')
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'La reserva se encuentra en un estado terminal y no puede cancelarse.';
            RETURN;
        END;

        IF @EstadoReserva <> N'RESERVADA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'La reserva no puede cancelarse desde su estado actual.';
            RETURN;
        END;

        IF @EstadoPlanificacion = N'PUBLICADA_CERRADA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'RESERVATIONS_CLOSED';
            SET @Mensaje = N'La planificación ya no acepta cambios de reservas.';
            RETURN;
        END;

        IF @EstadoPlanificacion = N'CONSOLIDADA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'PLAN_CONSOLIDATED';
            SET @Mensaje = N'La planificación ya fue consolidada.';
            RETURN;
        END;

        IF @EstadoPlanificacion <> N'PUBLICADA_ABIERTA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'INVALID_PLAN_STATE';
            SET @Mensaje = N'La planificación no está abierta para cancelar reservas.';
            RETURN;
        END;

        SET @FechaModificacion = SYSDATETIME();

        UPDATE [alimentacion].[Reserva]
        SET
            [Estado] = N'CANCELADA',
            [FechaModificacion] = @FechaModificacion
        WHERE [IdReserva] = @IdReservaInterno
          AND [Estado] = N'RESERVADA';

        IF @@ROWCOUNT = 0
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'La reserva cambió de estado y no puede cancelarse.';
            RETURN;
        END;

        COMMIT TRANSACTION;

        SET @Codigo = N'UPDATED';

        SELECT
            [Reserva].[IdentificadorPublico] AS [IdReserva],
            [Menu].[IdentificadorPublico] AS [IdMenu],
            [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
            [Reserva].[IdSede],
            [Reserva].[FechaServicio],
            [Reserva].[TipoServicio],
            [Reserva].[Estado],
            [Reserva].[FechaCreacion],
            [Reserva].[FechaModificacion]
        FROM [alimentacion].[Reserva] AS [Reserva]
        INNER JOIN [alimentacion].[Menu] AS [Menu]
            ON [Menu].[IdMenu] = [Reserva].[IdMenu]
           AND [Menu].[IdPlanificacion] = [Reserva].[IdPlanificacion]
           AND [Menu].[FechaServicio] = [Reserva].[FechaServicio]
           AND [Menu].[TipoServicio] = [Reserva].[TipoServicio]
        INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
        WHERE [Reserva].[IdReserva] = @IdReservaInterno;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_CancelarReservaPropia',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO
