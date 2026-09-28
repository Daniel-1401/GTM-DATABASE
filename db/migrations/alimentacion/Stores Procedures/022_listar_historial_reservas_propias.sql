-- Procedimiento: alimentacion.usp_ListarHistorialReservasPropias
-- Referencias: migraciones 010, 011 y 012 del modulo Alimentacion.
-- Motivo: consultar el historial de reservas propias anterior a la fecha actual.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarHistorialReservasPropias]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @NumeroPagina INT,
    @TamanoPagina INT,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdColaboradorCorporativo IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El colaborador es obligatorio.';
        RETURN;
    END;

    IF @NumeroPagina IS NULL OR @TamanoPagina IS NULL
       OR @NumeroPagina < 1
       OR @TamanoPagina < 1
       OR @TamanoPagina > 100
    BEGIN
        SET @Codigo = N'INVALID_FILTER';
        SET @Mensaje = N'La pagina debe ser mayor o igual a 1 y el tamano debe estar entre 1 y 100.';
        RETURN;
    END;

    BEGIN TRY
        -- La fecha se toma del servidor para separar el historial de las
        -- reservas activas que el colaborador aun puede consultar o cancelar.
        DECLARE @FechaOficial DATE = CONVERT(DATE, SYSDATETIME());

        SELECT
            [Reserva].[IdentificadorPublico] AS [IdReserva],
            [Menu].[IdentificadorPublico] AS [IdMenu],
            [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
            [Reserva].[IdSede] AS [IdSede],
            [Sede].[IdSedePublico] AS [IdSedePublico],
            [Sede].[NombreSede],
            [Reserva].[FechaServicio],
            [Reserva].[TipoServicio],
            [Planificacion].[Nombre] AS [NombrePlanificacion],
            [Menu].[Nombre] AS [NombreMenu],
            [Menu].[Descripcion] AS [DescripcionMenu],
            [Menu].[ReferenciaImagen] AS [ReferenciaImagenMenu],
            [Reserva].[Estado] AS [EstadoReserva],
            [Reserva].[FechaCreacion] AS [FechaCreacionReserva],
            [Reserva].[FechaModificacion] AS [FechaModificacionReserva],
            CASE
                WHEN [Reserva].[Estado] = N'ENTREGADA' THEN [Entrega].[IdentificadorPublico]
                ELSE NULL
            END AS [IdEntrega],
            CASE
                WHEN [Reserva].[Estado] = N'ENTREGADA' THEN [Entrega].[FechaEntrega]
                ELSE NULL
            END AS [FechaEntrega]
        FROM [alimentacion].[Reserva] AS [Reserva]
        INNER JOIN [alimentacion].[Menu] AS [Menu]
            ON [Menu].[IdMenu] = [Reserva].[IdMenu]
           AND [Menu].[IdPlanificacion] = [Reserva].[IdPlanificacion]
           AND [Menu].[FechaServicio] = [Reserva].[FechaServicio]
           AND [Menu].[TipoServicio] = [Reserva].[TipoServicio]
        INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
           AND [Planificacion].[IdSede] = [Reserva].[IdSede]
        INNER JOIN [PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA].[organizacion].[Sede] AS [Sede]
            ON [Sede].[IdSede] = [Reserva].[IdSede]
        LEFT JOIN [alimentacion].[Entrega] AS [Entrega]
            ON [Entrega].[IdReserva] = [Reserva].[IdReserva]
        WHERE [Reserva].[IdColaboradorCorporativo] = @IdColaboradorCorporativo
          AND [Reserva].[FechaServicio] < @FechaOficial
          AND [Reserva].[Estado] IN (N'ENTREGADA', N'NO_RECOGIDA', N'CANCELADA')
        ORDER BY
            [Reserva].[FechaServicio] DESC,
            [Reserva].[IdentificadorPublico] DESC
        OFFSET
            (CONVERT(BIGINT, @NumeroPagina) - 1) * CONVERT(BIGINT, @TamanoPagina)
            ROWS
        FETCH NEXT CONVERT(BIGINT, @TamanoPagina) ROWS ONLY;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ListarHistorialReservasPropias',
            @NumeroError = @NumeroErrorCapturado,
            @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado,
            @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO
