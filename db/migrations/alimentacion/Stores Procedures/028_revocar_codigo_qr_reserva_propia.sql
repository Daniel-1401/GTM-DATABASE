-- Procedimiento: alimentacion.usp_RevocarCodigoQRReservaPropia
-- Referencias: migraciones alimentacion 011 y nucleo 003.
-- Motivo: revocar de forma atomica un QR vigente asociado a una reserva propia.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_RevocarCodigoQRReservaPropia]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @IdCodigoQR UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdColaboradorCorporativo IS NULL OR @IdCodigoQR IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El colaborador y el codigo QR son obligatorios.';
        RETURN;
    END;

    DECLARE @IdReservaInicial BIGINT;

    SELECT @IdReservaInicial = [CodigoQR].[IdReserva]
    FROM [alimentacion].[CodigoQR] AS [CodigoQR]
    WHERE [CodigoQR].[IdCodigoQR] = @IdCodigoQR;

    IF @IdReservaInicial IS NULL
    BEGIN
        SET @Codigo = N'QR_NOT_FOUND';
        SET @Mensaje = N'El codigo QR indicado no existe.';
        RETURN;
    END;

    DECLARE @IdReservaInterno BIGINT;
    DECLARE @IdColaboradorReservaCorporativo UNIQUEIDENTIFIER;
    DECLARE @EstadoQR NVARCHAR(20);
    DECLARE @FechaRevocacion DATETIME2(3);
    DECLARE @MotivoRevocacion NVARCHAR(100) = N'REVOCACION_USUARIO';
    DECLARE @Resultado TABLE
    (
        [IdCodigoQR] UNIQUEIDENTIFIER NOT NULL,
        [IdReserva] UNIQUEIDENTIFIER NOT NULL,
        [Estado] NVARCHAR(20) NOT NULL,
        [FechaRevocacion] DATETIME2(3) NOT NULL,
        [MotivoRevocacion] NVARCHAR(100) NOT NULL
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Reserva se bloquea antes que CodigoQR, igual que las demas mutaciones de QR.
        SELECT
            @IdReservaInterno = [Reserva].[IdReserva],
            @IdColaboradorReservaCorporativo = [Reserva].[IdColaboradorCorporativo]
        FROM [alimentacion].[Reserva] AS [Reserva] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Reserva].[IdReserva] = @IdReservaInicial;

        IF @IdReservaInterno IS NULL
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'RESERVATION_NOT_FOUND';
            SET @Mensaje = N'La reserva asociada al codigo QR no existe.';
            RETURN;
        END;

        IF @IdColaboradorReservaCorporativo <> @IdColaboradorCorporativo
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'NOT_OWNER';
            SET @Mensaje = N'El codigo QR no pertenece al colaborador indicado.';
            RETURN;
        END;

        SELECT
            @EstadoQR = [CodigoQR].[Estado],
            @FechaRevocacion = [CodigoQR].[FechaRevocacion]
        FROM [alimentacion].[CodigoQR] AS [CodigoQR] WITH (UPDLOCK, HOLDLOCK)
        WHERE [CodigoQR].[IdCodigoQR] = @IdCodigoQR
          AND [CodigoQR].[IdReserva] = @IdReservaInterno;

        IF @EstadoQR IS NULL
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'QR_NOT_FOUND';
            SET @Mensaje = N'El codigo QR indicado no existe.';
            RETURN;
        END;

        IF @EstadoQR = N'REVOCADO'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'IDEMPOTENT_REPLAY';
            SET @Mensaje = N'El codigo QR ya estaba revocado.';
            SELECT
                @IdCodigoQR AS [IdCodigoQR],
                [Reserva].[IdentificadorPublico] AS [IdReserva],
                @EstadoQR AS [Estado],
                @FechaRevocacion AS [FechaRevocacion],
                [CodigoQR].[MotivoRevocacion]
            FROM [alimentacion].[CodigoQR] AS [CodigoQR]
            INNER JOIN [alimentacion].[Reserva] AS [Reserva]
                ON [Reserva].[IdReserva] = [CodigoQR].[IdReserva]
            WHERE [CodigoQR].[IdCodigoQR] = @IdCodigoQR;
            RETURN;
        END;

        IF @EstadoQR = N'VENCIDO'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'QR_EXPIRED';
            SET @Mensaje = N'El codigo QR ya vencio y no puede revocarse.';
            RETURN;
        END;

        IF @EstadoQR = N'UTILIZADO'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'QR_ALREADY_USED';
            SET @Mensaje = N'El codigo QR ya fue utilizado y no puede revocarse.';
            RETURN;
        END;

        IF @EstadoQR <> N'VIGENTE'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'El codigo QR no puede revocarse desde su estado actual.';
            RETURN;
        END;

        SET @FechaRevocacion = SYSDATETIME();

        UPDATE [alimentacion].[CodigoQR]
        SET [Estado] = N'REVOCADO',
            [FechaRevocacion] = @FechaRevocacion,
            [MotivoRevocacion] = @MotivoRevocacion
        OUTPUT inserted.[IdCodigoQR], [Reserva].[IdentificadorPublico], inserted.[Estado],
               inserted.[FechaRevocacion], inserted.[MotivoRevocacion]
        INTO @Resultado
        FROM [alimentacion].[CodigoQR] AS [CodigoQR]
        INNER JOIN [alimentacion].[Reserva] AS [Reserva]
            ON [Reserva].[IdReserva] = [CodigoQR].[IdReserva]
        WHERE [CodigoQR].[IdCodigoQR] = @IdCodigoQR
          AND [CodigoQR].[IdReserva] = @IdReservaInterno
          AND [CodigoQR].[Estado] = N'VIGENTE';

        IF @@ROWCOUNT = 0
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'El codigo QR cambio de estado y no puede revocarse.';
            RETURN;
        END;

        COMMIT TRANSACTION;

        SET @Codigo = N'UPDATED';
        SET @Mensaje = N'El codigo QR fue revocado correctamente.';
        SELECT [IdCodigoQR], [IdReserva], [Estado], [FechaRevocacion], [MotivoRevocacion]
        FROM @Resultado;
    END TRY
    BEGIN CATCH
        DECLARE @NumeroError INT = ERROR_NUMBER();
        DECLARE @EstadoError INT = ERROR_STATE();
        DECLARE @LineaError INT = ERROR_LINE();
        DECLARE @DetalleError NVARCHAR(2048) = ERROR_MESSAGE();
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_RevocarCodigoQRReservaPropia',
            @NumeroError = @NumeroError, @EstadoError = @EstadoError,
            @LineaError = @LineaError, @DetalleInterno = @DetalleError;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO
