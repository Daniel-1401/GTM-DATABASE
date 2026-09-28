-- Procedimiento: alimentacion.usp_ValidarCodigoQRReserva
-- Referencias: migraciones alimentacion 009 a 012.
-- Motivo: validar un QR para entrega y crear o reutilizar su validacion
--         temporal para el operador y la sede autorizados.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ValidarCodigoQRReserva]
    @HashCodigoQR VARBINARY(64),
    @IdSede INT,
    @IdOperadorColaboradorCorporativo UNIQUEIDENTIFIER,
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

    IF @HashCodigoQR IS NULL OR DATALENGTH(@HashCodigoQR) = 0
       OR DATALENGTH(@HashCodigoQR) > 64 OR @IdSede IS NULL OR @IdSede <= 0
       OR @IdOperadorColaboradorCorporativo IS NULL OR @IdCorrelacion IS NULL
       OR @MetodoLectura IS NULL OR @MetodoLectura NOT IN (N'CAMARA', N'LECTOR_HID')
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'Los datos de validacion son obligatorios y validos.';
        RETURN;
    END;

    DECLARE @Ahora DATETIME2(3) = SYSDATETIME();
    DECLARE @FechaOficial DATE = CONVERT(DATE, @Ahora);
    DECLARE @IdReserva BIGINT;
    DECLARE @IdPlanificacion BIGINT;
    DECLARE @IdCodigoQR UNIQUEIDENTIFIER;
    DECLARE @IdReservaPublico UNIQUEIDENTIFIER;
    DECLARE @IdSedeReserva INT;
    DECLARE @FechaServicio DATE;
    DECLARE @TipoServicio NVARCHAR(20);
    DECLARE @EstadoReserva NVARCHAR(20);
    DECLARE @EstadoQR NVARCHAR(20);
    DECLARE @FechaVencimientoQR DATETIME2(3);
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @HoraInicio TIME(0);
    DECLARE @HoraFin TIME(0);
    DECLARE @ValidationId UNIQUEIDENTIFIER;
    DECLARE @FechaVencimientoValidacion DATETIME2(3);
    DECLARE @FechaConsumo DATETIME2(3);
    DECLARE @IdCodigoQRValidacion UNIQUEIDENTIFIER;
    DECLARE @IdReservaValidacion BIGINT;
    DECLARE @IdSedeValidacion INT;
    DECLARE @IdOperadorValidacion UNIQUEIDENTIFIER;
    DECLARE @IdMenu BIGINT;
    DECLARE @NombreMenu NVARCHAR(200);
    DECLARE @ReferenciaImagenMenu NVARCHAR(500);
    DECLARE @NuevaValidacion TABLE
    (
        [ValidationId] UNIQUEIDENTIFIER NOT NULL
    );

    BEGIN TRY
        -- Se obtiene el contexto sin bloquear para fijar el orden comun de
        -- bloqueos: planificacion, reserva, QR y validacion.
        SELECT @IdReserva = [CodigoQR].[IdReserva]
        FROM [alimentacion].[CodigoQR] AS [CodigoQR]
        WHERE [CodigoQR].[HashCodigo] = @HashCodigoQR;

        IF @IdReserva IS NULL
        BEGIN
            SET @Codigo = N'QR_NOT_FOUND';
            SET @Mensaje = N'El codigo QR indicado no existe.';
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
            @IdReservaPublico = [Reserva].[IdentificadorPublico],
            @IdMenu = [Reserva].[IdMenu],
            @IdSedeReserva = [Reserva].[IdSede],
            @FechaServicio = [Reserva].[FechaServicio],
            @TipoServicio = [Reserva].[TipoServicio],
            @EstadoReserva = [Reserva].[Estado]
        FROM [alimentacion].[Reserva] AS [Reserva] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Reserva].[IdReserva] = @IdReserva;

        SELECT
            @IdCodigoQR = [CodigoQR].[IdCodigoQR],
            @EstadoQR = [CodigoQR].[Estado],
            @FechaVencimientoQR = [CodigoQR].[FechaVencimiento]
        FROM [alimentacion].[CodigoQR] AS [CodigoQR] WITH (UPDLOCK, HOLDLOCK)
        WHERE [CodigoQR].[HashCodigo] = @HashCodigoQR
          AND [CodigoQR].[IdReserva] = @IdReserva;

        SELECT
            @ValidationId = [Validacion].[ValidationId],
            @IdCodigoQRValidacion = [Validacion].[IdCodigoQR],
            @IdReservaValidacion = [Validacion].[IdReserva],
            @IdSedeValidacion = [Validacion].[IdSede],
            @IdOperadorValidacion = [Validacion].[IdOperadorColaboradorCorporativo],
            @FechaVencimientoValidacion = [Validacion].[FechaVencimiento],
            @FechaConsumo = [Validacion].[FechaConsumo]
        FROM [alimentacion].[ValidacionEntrega] AS [Validacion] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Validacion].[IdCorrelacion] = @IdCorrelacion;

        IF @ValidationId IS NOT NULL
        BEGIN
            IF @IdCodigoQRValidacion <> @IdCodigoQR
               OR @IdReservaValidacion <> @IdReserva
               OR @IdSedeValidacion <> @IdSede
               OR @IdOperadorValidacion <> @IdOperadorColaboradorCorporativo
            BEGIN
                IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
                SET @Codigo = N'IDEMPOTENCY_CONFLICT';
                SET @Mensaje = N'La correlacion ya esta vinculada a otra validacion.';
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
        END;

        IF @IdSedeReserva <> @IdSede
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'SITE_FORBIDDEN';
            SET @Mensaje = N'El codigo QR no corresponde a la sede indicada.';
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
            SET @Mensaje = N'La reserva no puede validarse para entrega.';
            RETURN;
        END;

        SELECT TOP (1)
            @HoraInicio = [Ventana].[HoraInicio],
            @HoraFin = [Ventana].[HoraFin]
        FROM [alimentacion].[VentanaRetiroServicio] AS [Ventana] WITH (HOLDLOCK)
        WHERE [Ventana].[IdSede] = @IdSedeReserva
          AND [Ventana].[TipoServicio] = @TipoServicio
          AND [Ventana].[FechaInicioVigencia] <= @FechaServicio
          AND ([Ventana].[FechaFinVigencia] IS NULL OR [Ventana].[FechaFinVigencia] >= @FechaServicio)
        ORDER BY [Ventana].[FechaInicioVigencia] DESC, [Ventana].[IdVentanaRetiroServicio] DESC;

        IF @HoraInicio IS NULL OR @HoraFin IS NULL OR @HoraFin < @HoraInicio
           OR CONVERT(TIME(3), @Ahora) < @HoraInicio OR CONVERT(TIME(3), @Ahora) > @HoraFin
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'CONFIGURATION_UNAVAILABLE';
            SET @Mensaje = N'No existe una ventana de retiro valida para la reserva.';
            RETURN;
        END;

        IF @ValidationId IS NULL
        BEGIN
            SELECT TOP (1)
                @ValidationId = [Validacion].[ValidationId],
                @FechaVencimientoValidacion = [Validacion].[FechaVencimiento]
            FROM [alimentacion].[ValidacionEntrega] AS [Validacion] WITH (UPDLOCK, HOLDLOCK)
            WHERE [Validacion].[HashCodigo] = @HashCodigoQR
              AND [Validacion].[IdCodigoQR] = @IdCodigoQR
              AND [Validacion].[IdReserva] = @IdReserva
              AND [Validacion].[IdSede] = @IdSede
              AND [Validacion].[IdOperadorColaboradorCorporativo] = @IdOperadorColaboradorCorporativo
              AND [Validacion].[FechaConsumo] IS NULL
              AND [Validacion].[FechaVencimiento] > @Ahora
            ORDER BY [Validacion].[FechaCreacion] DESC;
        END;

        IF @ValidationId IS NULL
        BEGIN
            SET @FechaVencimientoValidacion = CASE
                WHEN DATEADD(MINUTE, 2, @Ahora) < @FechaVencimientoQR THEN DATEADD(MINUTE, 2, @Ahora)
                ELSE @FechaVencimientoQR
            END;

            INSERT INTO [alimentacion].[ValidacionEntrega]
            (
                [IdCodigoQR], [IdReserva], [IdOperadorColaboradorCorporativo],
                [IdSede], [MetodoLectura], [FechaCreacion], [FechaVencimiento],
                [IdCorrelacion], [HashCodigo]
            )
            OUTPUT inserted.[ValidationId] INTO @NuevaValidacion ([ValidationId])
            VALUES
            (
                @IdCodigoQR, @IdReserva, @IdOperadorColaboradorCorporativo,
                @IdSede, @MetodoLectura, @Ahora, @FechaVencimientoValidacion,
                @IdCorrelacion, @HashCodigoQR
            );

            SELECT @ValidationId = [ValidationId]
            FROM @NuevaValidacion;

            SET @Codigo = N'CREATED';
            SET @Mensaje = N'La validacion de entrega fue creada correctamente.';
        END
        ELSE
        BEGIN
            SET @Codigo = N'IDEMPOTENT_REPLAY';
            SET @Mensaje = N'Ya existe una validacion vigente para el retiro.';
        END;

        SELECT
            @NombreMenu = [Menu].[Nombre],
            @ReferenciaImagenMenu = [Menu].[ReferenciaImagen]
        FROM [alimentacion].[Menu] AS [Menu]
        WHERE [Menu].[IdMenu] = @IdMenu
          AND [Menu].[IdPlanificacion] = @IdPlanificacion
          AND [Menu].[FechaServicio] = @FechaServicio
          AND [Menu].[TipoServicio] = @TipoServicio;

        COMMIT TRANSACTION;

        SELECT
            @ValidationId AS [ValidationId],
            @IdReservaPublico AS [IdReserva],
            @FechaVencimientoValidacion AS [FechaVencimiento],
            @NombreMenu AS [NombreMenu],
            @TipoServicio AS [TipoServicio],
            @ReferenciaImagenMenu AS [ReferenciaImagenMenu];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroError INT = ERROR_NUMBER();
        DECLARE @EstadoError INT = ERROR_STATE();
        DECLARE @LineaError INT = ERROR_LINE();
        DECLARE @DetalleError NVARCHAR(2048) = ERROR_MESSAGE();

        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ValidarCodigoQRReserva',
            @NumeroError = @NumeroError,
            @EstadoError = @EstadoError,
            @LineaError = @LineaError,
            @DetalleInterno = @DetalleError;

        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO
