-- Procedimiento: alimentacion.usp_ConfirmarEntregaQR
-- Motivo: consumir una validacion temporal vigente y confirmar la entrega.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ConfirmarEntregaQR]
    @ValidationId UNIQUEIDENTIFIER,
    @IdSede INT,
    @IdOperadorColaboradorCorporativo UNIQUEIDENTIFIER,
    @IdCorrelacion UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @ValidationId IS NULL OR @IdSede IS NULL OR @IdSede <= 0
       OR @IdOperadorColaboradorCorporativo IS NULL OR @IdCorrelacion IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'Los datos de confirmacion son obligatorios y validos.';
        RETURN;
    END;

    DECLARE @Ahora DATETIME2(3) = SYSDATETIME();
    DECLARE @FechaOficial DATE = CONVERT(DATE, @Ahora);
    DECLARE @IdReserva BIGINT;
    DECLARE @IdPlanificacion BIGINT;
    DECLARE @IdCodigoQR UNIQUEIDENTIFIER;
    DECLARE @IdSedeValidacion INT;
    DECLARE @IdOperadorValidacion UNIQUEIDENTIFIER;
    DECLARE @MetodoLectura NVARCHAR(20);
    DECLARE @FechaVencimientoValidacion DATETIME2(3);
    DECLARE @FechaConsumo DATETIME2(3);
    DECLARE @IdSedeReserva INT;
    DECLARE @FechaServicio DATE;
    DECLARE @TipoServicio NVARCHAR(20);
    DECLARE @EstadoReserva NVARCHAR(20);
    DECLARE @EstadoQR NVARCHAR(20);
    DECLARE @FechaVencimientoQR DATETIME2(3);
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @HoraInicio TIME(0);
    DECLARE @HoraFin TIME(0);
    DECLARE @IdEntregaExistente BIGINT;
    DECLARE @IdReservaEntregaExistente BIGINT;
    DECLARE @IdCodigoQREntregaExistente UNIQUEIDENTIFIER;
    DECLARE @IdOperadorEntregaExistente UNIQUEIDENTIFIER;
    DECLARE @IdEntrega BIGINT;
    DECLARE @IdEntregaPublico UNIQUEIDENTIFIER;

    BEGIN TRY
        -- Solo se usa para ubicar el contexto. La fila se relee con bloqueo
        -- despues de bloquear planificacion, reserva y QR.
        SELECT
            @IdReserva = [Validacion].[IdReserva],
            @IdCodigoQR = [Validacion].[IdCodigoQR]
        FROM [alimentacion].[ValidacionEntrega] AS [Validacion]
        WHERE [Validacion].[ValidationId] = @ValidationId;

        IF @IdReserva IS NULL
        BEGIN
            SET @Codigo = N'DELIVERY_VALIDATION_NOT_FOUND';
            SET @Mensaje = N'La validacion de entrega no existe.';
            RETURN;
        END;

        SELECT @IdPlanificacion = [Reserva].[IdPlanificacion]
        FROM [alimentacion].[Reserva] AS [Reserva]
        WHERE [Reserva].[IdReserva] = @IdReserva;

        BEGIN TRANSACTION;

        SELECT @EstadoPlanificacion = [Planificacion].[Estado]
        FROM [alimentacion].[Planificacion] AS [Planificacion] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Planificacion].[IdPlanificacion] = @IdPlanificacion;

        SELECT
            @IdSedeReserva = [Reserva].[IdSede],
            @FechaServicio = [Reserva].[FechaServicio],
            @TipoServicio = [Reserva].[TipoServicio],
            @EstadoReserva = [Reserva].[Estado]
        FROM [alimentacion].[Reserva] AS [Reserva] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Reserva].[IdReserva] = @IdReserva;

        SELECT
            @EstadoQR = [CodigoQR].[Estado],
            @FechaVencimientoQR = [CodigoQR].[FechaVencimiento]
        FROM [alimentacion].[CodigoQR] AS [CodigoQR] WITH (UPDLOCK, HOLDLOCK)
        WHERE [CodigoQR].[IdCodigoQR] = @IdCodigoQR
          AND [CodigoQR].[IdReserva] = @IdReserva;

        SELECT
            @IdCodigoQR = [Validacion].[IdCodigoQR],
            @IdSedeValidacion = [Validacion].[IdSede],
            @IdOperadorValidacion = [Validacion].[IdOperadorColaboradorCorporativo],
            @MetodoLectura = [Validacion].[MetodoLectura],
            @FechaVencimientoValidacion = [Validacion].[FechaVencimiento],
            @FechaConsumo = [Validacion].[FechaConsumo]
        FROM [alimentacion].[ValidacionEntrega] AS [Validacion] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Validacion].[ValidationId] = @ValidationId
          AND [Validacion].[IdReserva] = @IdReserva;

        IF @IdCodigoQR IS NULL
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'DELIVERY_VALIDATION_NOT_FOUND';
            SET @Mensaje = N'La validacion de entrega no existe.';
            RETURN;
        END;

        SELECT TOP (1)
            @IdEntregaExistente = [Entrega].[IdEntrega],
            @IdReservaEntregaExistente = [Entrega].[IdReserva],
            @IdCodigoQREntregaExistente = [Entrega].[IdCodigoQR],
            @IdOperadorEntregaExistente = [Entrega].[IdOperadorColaboradorCorporativo],
            @IdEntregaPublico = [Entrega].[IdentificadorPublico]
        FROM [alimentacion].[Entrega] AS [Entrega] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Entrega].[IdCorrelacion] = @IdCorrelacion;

        IF @IdSedeValidacion <> @IdSede OR @IdSedeReserva <> @IdSede
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'SITE_FORBIDDEN';
            SET @Mensaje = N'La validacion no corresponde a la sede indicada.';
            RETURN;
        END;

        IF @IdOperadorValidacion <> @IdOperadorColaboradorCorporativo
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'FORBIDDEN';
            SET @Mensaje = N'El operador no puede confirmar esta validacion.';
            RETURN;
        END;

        IF @IdEntregaExistente IS NOT NULL
        BEGIN
            IF @IdReservaEntregaExistente = @IdReserva
               AND @IdCodigoQREntregaExistente = @IdCodigoQR
               AND @IdOperadorEntregaExistente = @IdOperadorColaboradorCorporativo
            BEGIN
                COMMIT TRANSACTION;
                SET @Codigo = N'IDEMPOTENT_REPLAY';
                SET @Mensaje = N'La entrega ya habia sido confirmada.';
                SELECT @IdEntregaPublico AS [IdEntrega], @ValidationId AS [ValidationId],
                       N'ENTREGADA' AS [EstadoReserva], N'UTILIZADO' AS [EstadoQR];
                RETURN;
            END;

            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'IDEMPOTENCY_CONFLICT';
            SET @Mensaje = N'La correlacion ya esta vinculada a otra entrega.';
            RETURN;
        END;

        IF @FechaConsumo IS NOT NULL
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'La validacion ya fue consumida.';
            RETURN;
        END;
        IF @FechaVencimientoValidacion <= @Ahora
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'DELIVERY_VALIDATION_EXPIRED';
            SET @Mensaje = N'La validacion de entrega ya vencio.';
            RETURN;
        END;
        IF @EstadoQR = N'REVOCADO'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'QR_REVOKED';
            SET @Mensaje = N'El codigo QR fue revocado.';
            RETURN;
        END;
        IF @EstadoQR = N'UTILIZADO'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'QR_ALREADY_USED';
            SET @Mensaje = N'El codigo QR ya fue utilizado.';
            RETURN;
        END;
        IF @EstadoQR = N'VENCIDO' OR @FechaVencimientoQR <= @Ahora
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'QR_EXPIRED';
            SET @Mensaje = N'El codigo QR ya vencio.';
            RETURN;
        END;
        IF @EstadoQR <> N'VIGENTE' OR @EstadoReserva <> N'RESERVADA'
           OR @EstadoPlanificacion <> N'CONSOLIDADA' OR @FechaServicio <> @FechaOficial
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'La reserva no puede confirmarse desde su estado actual.';
            RETURN;
        END;

        SELECT TOP (1) @HoraInicio = [HoraInicio], @HoraFin = [HoraFin]
        FROM [alimentacion].[VentanaRetiroServicio] WITH (HOLDLOCK)
        WHERE [IdSede] = @IdSedeReserva AND [TipoServicio] = @TipoServicio
          AND [FechaInicioVigencia] <= @FechaServicio
          AND ([FechaFinVigencia] IS NULL OR [FechaFinVigencia] >= @FechaServicio)
        ORDER BY [FechaInicioVigencia] DESC, [IdVentanaRetiroServicio] DESC;

        IF @HoraInicio IS NULL OR @HoraFin IS NULL OR @HoraFin < @HoraInicio
           OR CONVERT(TIME(3), @Ahora) < @HoraInicio OR CONVERT(TIME(3), @Ahora) > @HoraFin
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'CONFIGURATION_UNAVAILABLE';
            SET @Mensaje = N'No existe una ventana de retiro valida para la reserva.';
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM [alimentacion].[Entrega] AS [Entrega] WITH (UPDLOCK, HOLDLOCK)
            WHERE [Entrega].[IdReserva] = @IdReserva
        )
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'ALREADY_DELIVERED';
            SET @Mensaje = N'La reserva ya fue entregada.';
            RETURN;
        END;

        UPDATE [alimentacion].[ValidacionEntrega]
        SET [FechaConsumo] = @Ahora
        WHERE [ValidationId] = @ValidationId
          AND [FechaConsumo] IS NULL
          AND [FechaVencimiento] > @Ahora;

        IF @@ROWCOUNT <> 1
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'La validacion ya no esta disponible.';
            RETURN;
        END;

        INSERT INTO [alimentacion].[Entrega]
        (
            [IdReserva], [IdCodigoQR], [IdOperadorColaboradorCorporativo], [IdPlanificacion],
            [IdSede], [FechaServicio], [TipoServicio], [MecanismoLectura], [FechaEntrega], [IdCorrelacion]
        )
        VALUES
        (
            @IdReserva, @IdCodigoQR, @IdOperadorColaboradorCorporativo, @IdPlanificacion,
            @IdSedeReserva, @FechaServicio, @TipoServicio, @MetodoLectura, @Ahora, @IdCorrelacion
        );
        SET @IdEntrega = SCOPE_IDENTITY();

        UPDATE [alimentacion].[CodigoQR]
        SET [Estado] = N'UTILIZADO', [FechaUso] = @Ahora
        WHERE [IdCodigoQR] = @IdCodigoQR AND [Estado] = N'VIGENTE';

        IF @@ROWCOUNT <> 1
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'El codigo QR ya no esta disponible.';
            RETURN;
        END;

        UPDATE [alimentacion].[Reserva]
        SET [Estado] = N'ENTREGADA', [FechaModificacion] = @Ahora
        WHERE [IdReserva] = @IdReserva AND [Estado] = N'RESERVADA';

        IF @@ROWCOUNT <> 1
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'La reserva ya no esta disponible.';
            RETURN;
        END;

        SELECT @IdEntregaPublico = [Entrega].[IdentificadorPublico]
        FROM [alimentacion].[Entrega] AS [Entrega]
        WHERE [Entrega].[IdEntrega] = @IdEntrega;

        COMMIT TRANSACTION;
        SET @Codigo = N'CREATED';
        SET @Mensaje = N'La entrega fue confirmada correctamente.';
        SELECT @IdEntregaPublico AS [IdEntrega], @ValidationId AS [ValidationId],
               N'ENTREGADA' AS [EstadoReserva], N'UTILIZADO' AS [EstadoQR];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroError INT = ERROR_NUMBER();
        DECLARE @EstadoError INT = ERROR_STATE();
        DECLARE @LineaError INT = ERROR_LINE();
        DECLARE @DetalleError NVARCHAR(2048) = ERROR_MESSAGE();

        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ConfirmarEntregaQR',
            @NumeroError = @NumeroError,
            @EstadoError = @EstadoError,
            @LineaError = @LineaError,
            @DetalleInterno = @DetalleError;

        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO
