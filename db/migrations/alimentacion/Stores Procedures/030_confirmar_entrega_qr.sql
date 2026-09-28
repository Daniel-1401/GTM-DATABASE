-- Procedimiento: alimentacion.usp_ConfirmarEntregaQR
-- Motivo: confirmar una entrega presencial normal despues de la validacion QR.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ConfirmarEntregaQR]
    @HashCodigoQR VARBINARY(64),
    @IdSede INT,
    @IdOperadorColaborador BIGINT,
    @MetodoLectura NVARCHAR(20),
    @IdCorrelacion UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @HashCodigoQR IS NULL OR DATALENGTH(@HashCodigoQR) = 0 OR @IdSede IS NULL OR @IdSede <= 0
       OR @IdOperadorColaborador IS NULL OR @IdOperadorColaborador <= 0 OR @IdCorrelacion IS NULL
       OR @MetodoLectura IS NULL OR @MetodoLectura NOT IN (N'CAMARA', N'LECTOR_HID')
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
    DECLARE @IdSedeReserva INT;
    DECLARE @FechaServicio DATE;
    DECLARE @TipoServicio NVARCHAR(20);
    DECLARE @EstadoReserva NVARCHAR(20);
    DECLARE @EstadoQR NVARCHAR(20);
    DECLARE @FechaVencimiento DATETIME2(3);
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @HoraInicio TIME(0);
    DECLARE @HoraFin TIME(0);
    DECLARE @IdEntregaExistente BIGINT;
    DECLARE @IdReservaEntregaExistente BIGINT;
    DECLARE @IdCodigoQREntregaExistente UNIQUEIDENTIFIER;
    DECLARE @IdEntrega BIGINT;
    DECLARE @IdEntregaPublico UNIQUEIDENTIFIER;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1 FROM [rrhh].[Colaborador] WITH (UPDLOCK, HOLDLOCK)
            WHERE [IdColaborador] = @IdOperadorColaborador
        )
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'NOT_FOUND';
            SET @Mensaje = N'El operador indicado no existe.';
            RETURN;
        END;

        -- Ubica el contexto antes de fijar el orden de bloqueo planificacion, reserva y QR.
        SELECT @IdReserva = [CodigoQR].[IdReserva]
        FROM [alimentacion].[CodigoQR] AS [CodigoQR]
        WHERE [CodigoQR].[HashCodigo] = @HashCodigoQR;

        IF @IdReserva IS NULL
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'QR_NOT_FOUND';
            SET @Mensaje = N'El codigo QR indicado no existe.';
            RETURN;
        END;

        SELECT @IdPlanificacion = [Reserva].[IdPlanificacion]
        FROM [alimentacion].[Reserva] AS [Reserva]
        WHERE [Reserva].[IdReserva] = @IdReserva;

        SELECT @EstadoPlanificacion = [Planificacion].[Estado]
        FROM [alimentacion].[Planificacion] AS [Planificacion] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Planificacion].[IdPlanificacion] = @IdPlanificacion;

        SELECT
            @IdSedeReserva = [Reserva].[IdSede], @FechaServicio = [Reserva].[FechaServicio],
            @TipoServicio = [Reserva].[TipoServicio], @EstadoReserva = [Reserva].[Estado]
        FROM [alimentacion].[Reserva] AS [Reserva] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Reserva].[IdReserva] = @IdReserva;

        SELECT
            @IdCodigoQR = [CodigoQR].[IdCodigoQR], @EstadoQR = [CodigoQR].[Estado],
            @FechaVencimiento = [CodigoQR].[FechaVencimiento]
        FROM [alimentacion].[CodigoQR] AS [CodigoQR] WITH (UPDLOCK, HOLDLOCK)
        WHERE [CodigoQR].[HashCodigo] = @HashCodigoQR AND [CodigoQR].[IdReserva] = @IdReserva;

        SELECT TOP (1)
            @IdEntregaExistente = [Entrega].[IdEntrega],
            @IdReservaEntregaExistente = [Entrega].[IdReserva],
            @IdCodigoQREntregaExistente = [Entrega].[IdCodigoQR],
            @IdEntregaPublico = [Entrega].[IdentificadorPublico]
        FROM [alimentacion].[Entrega] AS [Entrega] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Entrega].[IdCorrelacion] = @IdCorrelacion;

        IF @IdEntregaExistente IS NOT NULL
        BEGIN
            IF @IdReservaEntregaExistente = @IdReserva AND @IdCodigoQREntregaExistente = @IdCodigoQR
            BEGIN
                COMMIT TRANSACTION;
                SET @Codigo = N'IDEMPOTENT_REPLAY';
                SET @Mensaje = N'La entrega ya habia sido confirmada.';
                SELECT @IdEntregaPublico AS [IdEntrega], N'ENTREGADA' AS [EstadoReserva],
                       N'UTILIZADO' AS [EstadoQR];
                RETURN;
            END;
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'IDEMPOTENCY_CONFLICT';
            SET @Mensaje = N'La correlacion ya esta vinculada a otra entrega.';
            RETURN;
        END;

        IF @IdSedeReserva <> @IdSede
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'SITE_FORBIDDEN'; SET @Mensaje = N'El codigo QR no corresponde a la sede indicada.'; RETURN;
        END;
        IF @EstadoQR = N'REVOCADO'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'QR_REVOKED'; SET @Mensaje = N'El codigo QR fue revocado.'; RETURN;
        END;
        IF @EstadoQR = N'UTILIZADO'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'QR_ALREADY_USED'; SET @Mensaje = N'El codigo QR ya fue utilizado.'; RETURN;
        END;
        IF @EstadoQR = N'VENCIDO' OR @FechaVencimiento <= @Ahora
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'QR_EXPIRED'; SET @Mensaje = N'El codigo QR ya vencio.'; RETURN;
        END;
        IF @EstadoQR <> N'VIGENTE' OR @EstadoReserva <> N'RESERVADA'
           OR @EstadoPlanificacion <> N'CONSOLIDADA' OR @FechaServicio <> @FechaOficial
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT'; SET @Mensaje = N'La reserva no puede confirmarse desde su estado actual.'; RETURN;
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
            SET @Codigo = N'CONFIGURATION_UNAVAILABLE'; SET @Mensaje = N'No existe una ventana de retiro valida para la reserva.'; RETURN;
        END;

        IF EXISTS (SELECT 1 FROM [alimentacion].[Entrega] WITH (UPDLOCK, HOLDLOCK) WHERE [IdReserva] = @IdReserva)
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'ALREADY_DELIVERED'; SET @Mensaje = N'La reserva ya fue entregada.'; RETURN;
        END;

        INSERT INTO [alimentacion].[Entrega]
            ([IdReserva], [IdCodigoQR], [IdOperadorColaborador], [IdPlanificacion], [IdSede], [FechaServicio], [TipoServicio], [MecanismoLectura], [FechaEntrega], [IdCorrelacion])
        VALUES
            (@IdReserva, @IdCodigoQR, @IdOperadorColaborador, @IdPlanificacion, @IdSedeReserva, @FechaServicio, @TipoServicio, @MetodoLectura, @Ahora, @IdCorrelacion);
        SET @IdEntrega = SCOPE_IDENTITY();

        UPDATE [alimentacion].[CodigoQR] SET [Estado] = N'UTILIZADO', [FechaUso] = @Ahora
        WHERE [IdCodigoQR] = @IdCodigoQR AND [Estado] = N'VIGENTE';
        UPDATE [alimentacion].[Reserva] SET [Estado] = N'ENTREGADA', [FechaModificacion] = @Ahora
        WHERE [IdReserva] = @IdReserva AND [Estado] = N'RESERVADA';

        SELECT @IdEntregaPublico = [IdentificadorPublico] FROM [alimentacion].[Entrega] WHERE [IdEntrega] = @IdEntrega;
        COMMIT TRANSACTION;
        SET @Codigo = N'CREATED'; SET @Mensaje = N'La entrega fue confirmada correctamente.';
        SELECT @IdEntregaPublico AS [IdEntrega], N'ENTREGADA' AS [EstadoReserva], N'UTILIZADO' AS [EstadoQR];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroError INT = ERROR_NUMBER(), @EstadoError INT = ERROR_STATE(), @LineaError INT = ERROR_LINE();
        DECLARE @DetalleError NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ConfirmarEntregaQR', @NumeroError = @NumeroError,
            @EstadoError = @EstadoError, @LineaError = @LineaError, @DetalleInterno = @DetalleError;
        SET @Codigo = N'INTERNAL_ERROR'; SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO
