-- Procedimiento: alimentacion.usp_ValidarCodigoQRReserva
-- Referencias: migraciones alimentacion 009, 010 y 011; nucleo 003, 004 y 005.
-- Motivo: verificar sin mutaciones un QR de reserva en la sede de retiro y
--         devolver los datos de presentacion del colaborador y del menu.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ValidarCodigoQRReserva]
    @HashCodigoQR VARBINARY(64),
    @IdSede INT,
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
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El codigo QR y la sede son obligatorios y validos.';
        RETURN;
    END;

    DECLARE @Ahora DATETIME2(3) = SYSDATETIME();
    DECLARE @FechaOficial DATE = CONVERT(DATE, @Ahora);
    DECLARE @IdReserva BIGINT;
    DECLARE @IdSedeReserva INT;
    DECLARE @FechaServicio DATE;
    DECLARE @TipoServicio NVARCHAR(20);
    DECLARE @EstadoReserva NVARCHAR(20);
    DECLARE @EstadoQR NVARCHAR(20);
    DECLARE @FechaVencimiento DATETIME2(3);
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @HoraInicio TIME(0);
    DECLARE @HoraFin TIME(0);

    BEGIN TRY
        SELECT
            @IdReserva = [CodigoQR].[IdReserva],
            @IdSedeReserva = [Reserva].[IdSede],
            @FechaServicio = [Reserva].[FechaServicio],
            @TipoServicio = [Reserva].[TipoServicio],
            @EstadoReserva = [Reserva].[Estado],
            @EstadoQR = [CodigoQR].[Estado],
            @FechaVencimiento = [CodigoQR].[FechaVencimiento],
            @EstadoPlanificacion = [Planificacion].[Estado]
        FROM [alimentacion].[CodigoQR] AS [CodigoQR]
        INNER JOIN [alimentacion].[Reserva] AS [Reserva]
            ON [Reserva].[IdReserva] = [CodigoQR].[IdReserva]
        LEFT JOIN [alimentacion].[Planificacion] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
        WHERE [CodigoQR].[HashCodigo] = @HashCodigoQR;

        IF @IdReserva IS NULL
        BEGIN
            SET @Codigo = N'QR_NOT_FOUND';
            SET @Mensaje = N'El codigo QR indicado no existe.';
            RETURN;
        END;

        IF @IdSedeReserva <> @IdSede
        BEGIN
            SET @Codigo = N'SITE_FORBIDDEN';
            SET @Mensaje = N'El codigo QR no corresponde a la sede indicada.';
            RETURN;
        END;

        IF @EstadoQR = N'REVOCADO'
        BEGIN
            SET @Codigo = N'QR_REVOKED';
            SET @Mensaje = N'El codigo QR fue revocado.';
            RETURN;
        END;

        IF @EstadoQR = N'UTILIZADO'
        BEGIN
            SET @Codigo = N'QR_ALREADY_USED';
            SET @Mensaje = N'El codigo QR ya fue utilizado.';
            RETURN;
        END;

        IF @EstadoQR = N'VENCIDO' OR @FechaVencimiento <= @Ahora
        BEGIN
            SET @Codigo = N'QR_EXPIRED';
            SET @Mensaje = N'El codigo QR ya vencio.';
            RETURN;
        END;

        IF @EstadoQR <> N'VIGENTE'
        BEGIN
            SET @Codigo = N'QR_INVALID';
            SET @Mensaje = N'El codigo QR no es valido.';
            RETURN;
        END;

        IF @EstadoReserva = N'ENTREGADA'
        BEGIN
            SET @Codigo = N'ALREADY_DELIVERED';
            SET @Mensaje = N'La reserva ya fue entregada.';
            RETURN;
        END;

        IF @EstadoReserva <> N'RESERVADA'
        BEGIN
            SET @Codigo = N'STATE_CONFLICT';
            SET @Mensaje = N'La reserva no puede retirarse desde su estado actual.';
            RETURN;
        END;

        IF @EstadoPlanificacion IS NULL
        BEGIN
            SET @Codigo = N'PLAN_NOT_FOUND';
            SET @Mensaje = N'La planificacion de la reserva no existe.';
            RETURN;
        END;

        IF @EstadoPlanificacion <> N'CONSOLIDADA' OR @FechaServicio <> @FechaOficial
        BEGIN
            SET @Codigo = N'QR_INVALID';
            SET @Mensaje = N'El codigo QR no es valido para el retiro actual.';
            RETURN;
        END;

        SELECT TOP (1)
            @HoraInicio = [Ventana].[HoraInicio],
            @HoraFin = [Ventana].[HoraFin]
        FROM [alimentacion].[VentanaRetiroServicio] AS [Ventana]
        WHERE [Ventana].[IdSede] = @IdSedeReserva
          AND [Ventana].[TipoServicio] = @TipoServicio
          AND [Ventana].[FechaInicioVigencia] <= @FechaServicio
          AND ([Ventana].[FechaFinVigencia] IS NULL OR [Ventana].[FechaFinVigencia] >= @FechaServicio)
        ORDER BY [Ventana].[FechaInicioVigencia] DESC, [Ventana].[IdVentanaRetiroServicio] DESC;

        IF @HoraInicio IS NULL OR @HoraFin IS NULL
           OR @HoraFin < @HoraInicio
           OR CONVERT(TIME(3), @Ahora) < @HoraInicio
           OR CONVERT(TIME(3), @Ahora) > @HoraFin
        BEGIN
            SET @Codigo = N'CONFIGURATION_UNAVAILABLE';
            SET @Mensaje = N'No existe una ventana de retiro valida para la reserva.';
            RETURN;
        END;

        SELECT
            LTRIM(RTRIM(CONCAT([Persona].[Nombres], N' ', [Persona].[ApellidoPaterno],
                CASE WHEN [Persona].[ApellidoMaterno] IS NULL THEN N'' ELSE N' ' + [Persona].[ApellidoMaterno] END))) AS [NombreColaborador],
            [Colaborador].[CodigoSAP] AS [CodigoSAPColaborador],
            '[CargoVigente].[NombreCargo]' AS [CargoColaborador],
            CAST(NULL AS NVARCHAR(500)) AS [Avatar],
            [Menu].[Nombre] AS [NombreMenu],
            [Reserva].[TipoServicio] AS [TipoServicio],
            [Menu].[ReferenciaImagen] AS [ReferenciaImagenMenu]
        FROM [alimentacion].[Reserva] AS [Reserva]
        INNER JOIN [rrhh].[Colaborador] AS [Colaborador]
            ON [Colaborador].[IdColaborador] = [Reserva].[IdColaborador]
        INNER JOIN [rrhh].[Persona] AS [Persona]
            ON [Persona].[IdPersona] = [Colaborador].[IdPersona]
        INNER JOIN [alimentacion].[Menu] AS [Menu]
            ON [Menu].[IdMenu] = [Reserva].[IdMenu]
           AND [Menu].[IdPlanificacion] = [Reserva].[IdPlanificacion]
           AND [Menu].[FechaServicio] = [Reserva].[FechaServicio]
           AND [Menu].[TipoServicio] = [Reserva].[TipoServicio]
--         OUTER APPLY
--         (
--             SELECT TOP (1) [Cargo].[NombreCargo]
--             FROM [rrhh].[RelacionLaboral] AS [RelacionLaboral]
--             INNER JOIN [organizacion].[CargoSAP] AS [CargoSAP]
--                 ON [CargoSAP].[IdCargoSAP] = [RelacionLaboral].[IdCargoSAP]
--             INNER JOIN [organizacion].[Cargo] AS [Cargo]
--                 ON [Cargo].[IdCargo] = [CargoSAP].[IdCargo]
--             WHERE [RelacionLaboral].[IdColaborador] = [Reserva].[IdColaborador]
--               AND [RelacionLaboral].[IdSede] = [Reserva].[IdSede]
--               AND [RelacionLaboral].[FechaInicio] <= @FechaOficial
--               AND ([RelacionLaboral].[FechaFin] IS NULL OR [RelacionLaboral].[FechaFin] >= @FechaOficial)
--             ORDER BY [RelacionLaboral].[FechaInicio] DESC, [RelacionLaboral].[IdRelacionLaboral] DESC
--         ) AS [CargoVigente]
        WHERE [Reserva].[IdReserva] = @IdReserva;
    END TRY
    BEGIN CATCH
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
