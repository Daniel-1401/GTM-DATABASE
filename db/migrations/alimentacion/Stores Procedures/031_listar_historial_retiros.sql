-- Procedimiento: alimentacion.usp_ListarHistorialRetiros
-- Motivo: listar reservas y su resultado de retiro, paginado o para exportacion.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarHistorialRetiros]
    @NombreColaborador NVARCHAR(200) = NULL,
    @TipoServicio NVARCHAR(20) = NULL,
    @EstadoRetiro NVARCHAR(20) = NULL,
    @IdSede INT = NULL,
    @Fecha DATE = NULL,
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @Exportar BIT = 0,
    @NumeroPagina INT = 1,
    @TamanoPagina INT = 20,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;
    SET @NombreColaborador = NULLIF(LTRIM(RTRIM(@NombreColaborador)), N'');

    DECLARE @PatronNombreColaborador NVARCHAR(402);

    IF @NombreColaborador IS NOT NULL
    BEGIN
        SET @PatronNombreColaborador = REPLACE(@NombreColaborador, N'\', N'\\');
        SET @PatronNombreColaborador = REPLACE(@PatronNombreColaborador, N'%', N'\%');
        SET @PatronNombreColaborador = REPLACE(@PatronNombreColaborador, N'_', N'\_');
        SET @PatronNombreColaborador = REPLACE(@PatronNombreColaborador, N'[', N'\[');
        SET @PatronNombreColaborador = N'%' + @PatronNombreColaborador + N'%';
    END;

    IF @IdSede IS NOT NULL AND @IdSede <= 0
       OR @NumeroPagina < 1 OR @TamanoPagina NOT BETWEEN 1 AND 100
       OR (@Fecha IS NOT NULL AND (@FechaDesde IS NOT NULL OR @FechaHasta IS NOT NULL))
       OR (@FechaDesde IS NOT NULL AND @FechaHasta IS NOT NULL AND @FechaDesde > @FechaHasta)
       OR (@TipoServicio IS NOT NULL AND @TipoServicio NOT IN (N'DESAYUNO', N'ALMUERZO', N'CENA'))
       OR (@EstadoRetiro IS NOT NULL AND @EstadoRetiro NOT IN (N'ENTREGADO', N'CANCELADO', N'SIN_ENTREGAR'))
    BEGIN
        SET @Codigo = N'INVALID_FILTER';
        SET @Mensaje = N'Los filtros de historial no son validos.';
        RETURN;
    END;

    BEGIN TRY
        ;WITH [Historial] AS
        (
            SELECT
                [Reserva].[IdentificadorPublico] AS [IdReserva],
                [Reserva].[IdReserva] AS [IdReservaInterno],
                [Entrega].[IdentificadorPublico] AS [IdEntrega],
                [Reserva].[FechaServicio],
                [Reserva].[TipoServicio],
                [Reserva].[Estado] AS [EstadoReserva],
                CASE
                    WHEN [Entrega].[IdEntrega] IS NOT NULL THEN N'ENTREGADO'
                    WHEN [Reserva].[Estado] = N'CANCELADA' THEN N'CANCELADO'
                    ELSE N'SIN_ENTREGAR'
                END AS [EstadoRetiro],
                [Entrega].[FechaEntrega],
                [Entrega].[MecanismoLectura],
                [Sede].[IdSede],
                [Sede].[CodigoSede],
                [Sede].[NombreSede],
                [Reserva].[IdColaboradorCorporativo] AS [IdColaboradorCorporativo],
                [Colaborador].[NombreCompleto] AS [NombreColaborador],
                [Menu].[Nombre] AS [NombreMenu],
                [Menu].[ReferenciaImagen] AS [ReferenciaImagenMenu],
                [Reserva].[FechaCreacion]
            FROM [alimentacion].[Reserva] AS [Reserva]
            INNER JOIN [PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA].[organizacion].[Sede] AS [Sede]
                ON [Sede].[IdSede] = [Reserva].[IdSede]
            INNER JOIN [alimentacion].[Menu] AS [Menu]
                ON [Menu].[IdMenu] = [Reserva].[IdMenu]
               AND [Menu].[IdPlanificacion] = [Reserva].[IdPlanificacion]
               AND [Menu].[FechaServicio] = [Reserva].[FechaServicio]
               AND [Menu].[TipoServicio] = [Reserva].[TipoServicio]
            LEFT JOIN [alimentacion].[Entrega] AS [Entrega]
                ON [Entrega].[IdReserva] = [Reserva].[IdReserva]
            LEFT JOIN [GSBEDEV01\CO].[PERSONALMANEGEMENTCORP].[rrhh].[vw_ColaboradorConsulta] AS [Colaborador]
                ON [Colaborador].[IdColaboradorCorporativo] = [Reserva].[IdColaboradorCorporativo]
        ),
        [HistorialOperativo] AS
        (
            SELECT
                [Historial].*,
                ROW_NUMBER() OVER
                (
                    PARTITION BY [IdColaboradorCorporativo], [FechaServicio]
                    ORDER BY [FechaCreacion] DESC, [IdReservaInterno] DESC
                ) AS [NumeroReservaOperativa]
            FROM [Historial]
        )
        SELECT
            [IdReserva], [IdEntrega], [FechaServicio], [TipoServicio], [EstadoReserva], [EstadoRetiro],
            [FechaEntrega], [MecanismoLectura], [IdSede], [CodigoSede], [NombreSede],
            [IdColaboradorCorporativo], [NombreColaborador], [NombreMenu], [ReferenciaImagenMenu],
            COUNT_BIG(*) OVER () AS [TotalRegistros]
        FROM [HistorialOperativo]
        WHERE [NumeroReservaOperativa] = 1
          AND (@IdSede IS NULL OR [IdSede] = @IdSede)
          AND (@TipoServicio IS NULL OR [TipoServicio] = @TipoServicio)
          AND (@Fecha IS NULL OR [FechaServicio] = @Fecha)
          AND (@FechaDesde IS NULL OR [FechaServicio] >= @FechaDesde)
          AND (@FechaHasta IS NULL OR [FechaServicio] <= @FechaHasta)
          AND
          (
              @PatronNombreColaborador IS NULL
              OR [NombreColaborador] COLLATE DATABASE_DEFAULT
                  LIKE @PatronNombreColaborador ESCAPE N'\'
          )
          AND (@EstadoRetiro IS NULL OR [EstadoRetiro] = @EstadoRetiro)
        ORDER BY [FechaServicio] DESC, [FechaEntrega] DESC, [IdReserva] DESC
        OFFSET CASE WHEN @Exportar = 1 THEN 0 ELSE (@NumeroPagina - 1) * @TamanoPagina END ROWS
        FETCH NEXT CASE WHEN @Exportar = 1 THEN 2147483647 ELSE @TamanoPagina END ROWS ONLY
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        DECLARE @NumeroError INT = ERROR_NUMBER(), @EstadoError INT = ERROR_STATE(), @LineaError INT = ERROR_LINE();
        DECLARE @DetalleError NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ListarHistorialRetiros', @NumeroError = @NumeroError,
            @EstadoError = @EstadoError, @LineaError = @LineaError, @DetalleInterno = @DetalleError;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO
