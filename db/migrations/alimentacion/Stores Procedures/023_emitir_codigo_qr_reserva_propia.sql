-- Procedimiento: alimentacion.usp_EmitirCodigoQRReservaPropia
-- Referencias: migraciones alimentacion 009, 010, 011 y 012; nucleo 003 y 004.
-- Motivo: emitir o reemitir un QR opaco para una reserva propia consolidada.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_EmitirCodigoQRReservaPropia]
    @IdColaborador BIGINT,
    @IdReserva UNIQUEIDENTIFIER,
    @HashCodigo VARBINARY(64),
    @IdCorrelacion UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdColaborador IS NULL OR @IdColaborador <= 0 OR @IdReserva IS NULL OR @HashCodigo IS NULL
       OR DATALENGTH(@HashCodigo) = 0 OR DATALENGTH(@HashCodigo) > 64
       OR @IdCorrelacion IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'Los datos de emision son obligatorios y validos.';
        RETURN;
    END;

    select @IdColaborador = IdColaborador
    from [rrhh].[Colaborador]
    where UsuarioId = @IdColaborador;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [rrhh].[Colaborador] AS [Colaborador]
        WHERE [Colaborador].[IdColaborador] = @IdColaborador
    )
    BEGIN
        SET @Codigo = N'NOT_FOUND';
        SET @Mensaje = N'El colaborador indicado no existe.';
        RETURN;
    END;

    DECLARE @IdReservaInicial BIGINT;
    DECLARE @IdPlanificacionInicial BIGINT;
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

    DECLARE @Ahora DATETIME2(3) = SYSDATETIME();
    DECLARE @FechaVencimiento DATETIME2(3) = DATEADD(MINUTE, 5, @Ahora);

    DECLARE @IdReservaInterno BIGINT;
    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @IdSede INT;
    DECLARE @FechaServicio DATE;
    DECLARE @TipoServicio NVARCHAR(20);
    DECLARE @IdColaboradorReserva BIGINT;
    DECLARE @EstadoReserva NVARCHAR(20);
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @HoraInicio TIME(0);
    DECLARE @HoraFin TIME(0);
    DECLARE @IdCodigoQR UNIQUEIDENTIFIER;
    DECLARE @FechaEmision DATETIME2(3);
    DECLARE @EstadoQR NVARCHAR(20);
    DECLARE @FechaVencimientoResultado DATETIME2(3);
    DECLARE @Resultado TABLE
    (
        [IdCodigoQR] UNIQUEIDENTIFIER NOT NULL,
        [IdReserva] UNIQUEIDENTIFIER NOT NULL,
        [Estado] NVARCHAR(20) NOT NULL,
        [FechaEmision] DATETIME2(3) NOT NULL,
        [FechaVencimiento] DATETIME2(3) NOT NULL,
        [VigenciaMinutos] INT NOT NULL
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        -- El orden Planificacion -> Reserva coincide con las mutaciones de reservas.
        SELECT @EstadoPlanificacion = [Planificacion].[Estado]
        FROM [alimentacion].[Planificacion] AS [Planificacion] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Planificacion].[IdPlanificacion] = @IdPlanificacionInicial;

        SELECT
            @IdReservaInterno = [Reserva].[IdReserva],
            @IdPlanificacionInterno = [Reserva].[IdPlanificacion],
            @IdSede = [Reserva].[IdSede],
            @FechaServicio = [Reserva].[FechaServicio],
            @TipoServicio = [Reserva].[TipoServicio],
            @IdColaboradorReserva = [Reserva].[IdColaborador],
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

        IF @IdColaboradorReserva <> @IdColaborador
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'NOT_OWNER';
            SET @Mensaje = N'La reserva no pertenece al colaborador indicado.';
            RETURN;
        END;

        -- IdCorrelacion no tiene unicidad fisica: el rango bloqueado cubre replay y conflicto.
        SELECT TOP (1)
            @IdCodigoQR = [CodigoQR].[IdCodigoQR],
            @EstadoQR = [CodigoQR].[Estado],
            @FechaEmision = [CodigoQR].[FechaEmision],
            @FechaVencimientoResultado = [CodigoQR].[FechaVencimiento]
        FROM [alimentacion].[CodigoQR] AS [CodigoQR] WITH (UPDLOCK, HOLDLOCK)
        WHERE [CodigoQR].[IdCorrelacion] = @IdCorrelacion;

        IF @IdCodigoQR IS NOT NULL
        BEGIN
            IF EXISTS
            (
                SELECT 1
                FROM [alimentacion].[CodigoQR] AS [CodigoQR]
                WHERE [CodigoQR].[IdCodigoQR] = @IdCodigoQR
                  AND [CodigoQR].[IdReserva] = @IdReservaInterno
            )
            BEGIN
                IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
                SET @Codigo = N'IDEMPOTENT_REPLAY';
                SET @Mensaje = N'La emision ya habia sido procesada.';
                SELECT @IdCodigoQR AS [IdCodigoQR], @IdReserva AS [IdReserva],
                       @EstadoQR AS [Estado], @FechaEmision AS [FechaEmision],
                       @FechaVencimientoResultado AS [FechaVencimiento],
                       DATEDIFF(MINUTE, @FechaEmision, @FechaVencimientoResultado) AS [VigenciaMinutos];
                RETURN;
            END;

            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'CONFLICT';
            SET @Mensaje = N'La correlacion ya esta vinculada a otra reserva.';
            RETURN;
        END;

        IF @EstadoReserva <> N'RESERVADA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'La reserva no puede recibir un QR desde su estado actual.';
            RETURN;
        END;

        IF @EstadoPlanificacion IS NULL
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'PLAN_NOT_FOUND';
            SET @Mensaje = N'La planificacion de la reserva no existe.';
            RETURN;
        END
        ELSE IF @EstadoPlanificacion <> N'CONSOLIDADA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'INVALID_PLAN_STATE';
            SET @Mensaje = N'La planificacion no esta consolidada para emitir el QR.';
            RETURN;
        END;

        IF @FechaServicio <> CONVERT(DATE, @Ahora)
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'La reserva no corresponde a la fecha oficial.';
            RETURN;
        END;

        SELECT TOP (1)
            @HoraInicio = [Ventana].[HoraInicio],
            @HoraFin = [Ventana].[HoraFin]
        FROM [alimentacion].[VentanaRetiroServicio] AS [Ventana] WITH (HOLDLOCK)
        WHERE [Ventana].[IdSede] = @IdSede
          AND [Ventana].[TipoServicio] = @TipoServicio
          AND [Ventana].[FechaInicioVigencia] <= @FechaServicio
          AND ([Ventana].[FechaFinVigencia] IS NULL OR [Ventana].[FechaFinVigencia] >= @FechaServicio)
        ORDER BY [Ventana].[FechaInicioVigencia] DESC, [Ventana].[IdVentanaRetiroServicio] DESC;

        IF @HoraInicio IS NULL OR @HoraFin IS NULL
           OR @HoraFin < @HoraInicio
           OR CONVERT(TIME(3), @Ahora) < @HoraInicio
           OR CONVERT(TIME(3), @Ahora) > @HoraFin
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'CONFIGURATION_UNAVAILABLE';
            SET @Mensaje = N'No existe una ventana de retiro valida para la emision.';
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM [alimentacion].[CodigoQR] AS [CodigoQR] WITH (UPDLOCK, HOLDLOCK)
            WHERE [CodigoQR].[IdReserva] = @IdReservaInterno
              AND [CodigoQR].[Estado] = N'VIGENTE'
        )
        BEGIN
            UPDATE [alimentacion].[CodigoQR]
            SET [Estado] = N'REVOCADO',
                [FechaRevocacion] = @Ahora,
                [MotivoRevocacion] = N'REEMISION'
            WHERE [IdReserva] = @IdReservaInterno
              AND [Estado] = N'VIGENTE';
        END;

        INSERT INTO [alimentacion].[CodigoQR]
        (
            [IdReserva], [HashCodigo], [Estado], [FechaEmision],
            [FechaVencimiento], [IdCorrelacion]
        )
        OUTPUT inserted.[IdCodigoQR], @IdReserva, inserted.[Estado],
               inserted.[FechaEmision], inserted.[FechaVencimiento],
               DATEDIFF(MINUTE, inserted.[FechaEmision], inserted.[FechaVencimiento])
        INTO @Resultado
        VALUES
        (@IdReservaInterno, @HashCodigo, N'VIGENTE', @Ahora, @FechaVencimiento, @IdCorrelacion);

        COMMIT TRANSACTION;
        SET @Codigo = N'CREATED';
        SET @Mensaje = N'El QR fue emitido correctamente.';
        SELECT [IdCodigoQR], [IdReserva], [Estado], [FechaEmision], [FechaVencimiento], [VigenciaMinutos]
        FROM @Resultado;
    END TRY
    BEGIN CATCH
        DECLARE @NumeroError INT = ERROR_NUMBER();
        DECLARE @EstadoError INT = ERROR_STATE();
        DECLARE @LineaError INT = ERROR_LINE();
        DECLARE @DetalleError NVARCHAR(2048) = ERROR_MESSAGE();
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        IF @NumeroError IN (2601, 2627)
        BEGIN
            SELECT TOP (1)
                @IdCodigoQR = [CodigoQR].[IdCodigoQR],
                @EstadoQR = [CodigoQR].[Estado],
                @FechaEmision = [CodigoQR].[FechaEmision],
                @FechaVencimientoResultado = [CodigoQR].[FechaVencimiento]
            FROM [alimentacion].[CodigoQR] AS [CodigoQR]
            WHERE [CodigoQR].[IdCorrelacion] = @IdCorrelacion;

            IF @IdCodigoQR IS NOT NULL AND EXISTS
            (
                SELECT 1 FROM [alimentacion].[CodigoQR]
                WHERE [IdCodigoQR] = @IdCodigoQR AND [IdReserva] = @IdReservaInicial
            )
            BEGIN
                SET @Codigo = N'IDEMPOTENT_REPLAY';
                SET @Mensaje = N'La emision ya habia sido procesada.';
                SELECT @IdCodigoQR AS [IdCodigoQR], @IdReserva AS [IdReserva],
                       @EstadoQR AS [Estado], @FechaEmision AS [FechaEmision],
                       @FechaVencimientoResultado AS [FechaVencimiento],
                       DATEDIFF(MINUTE, @FechaEmision, @FechaVencimientoResultado) AS [VigenciaMinutos];
                RETURN;
            END;

            SET @Codigo = N'CONFLICT';
            SET @Mensaje = N'La emision entra en conflicto con un QR existente.';
            RETURN;
        END;

        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_EmitirCodigoQRReservaPropia',
            @NumeroError = @NumeroError, @EstadoError = @EstadoError,
            @LineaError = @LineaError, @DetalleInterno = @DetalleError;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO
