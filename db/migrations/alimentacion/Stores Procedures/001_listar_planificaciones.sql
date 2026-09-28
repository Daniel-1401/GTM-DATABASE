-- Procedimiento: alimentacion.usp_ListarPlanificaciones
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Exponer el listado maestro paginado de cabeceras de planificación.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarPlanificaciones]
    @IdSede INT = NULL,
    @Estado NVARCHAR(25) = NULL,
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @TerminoBusqueda NVARCHAR(200) = NULL,
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

    SET @TerminoBusqueda = NULLIF(LTRIM(RTRIM(@TerminoBusqueda)), N'');

    IF (@NumeroPagina < 1)
    BEGIN
        SET @Codigo = N'INVALID_FILTER';
        SET @Mensaje = N'El número de página debe ser mayor o igual a uno.';
        RETURN;
    END;

    IF (@TamanoPagina NOT BETWEEN 1 AND 100)
    BEGIN
        SET @Codigo = N'INVALID_FILTER';
        SET @Mensaje = N'El tamaño de página debe estar entre uno y cien.';
        RETURN;
    END;

    IF @Estado IS NOT NULL
       AND @Estado NOT IN (N'BORRADOR', N'PUBLICADA_ABIERTA', N'PUBLICADA_CERRADA', N'CONSOLIDADA')
    BEGIN
        SET @Codigo = N'INVALID_FILTER';
        SET @Mensaje = N'El estado de planificación no es válido.';
        RETURN;
    END;

    IF @FechaDesde IS NOT NULL
       AND @FechaHasta IS NOT NULL
       AND @FechaDesde > @FechaHasta
    BEGIN
        SET @Codigo = N'INVALID_FILTER';
        SET @Mensaje = N'La fecha desde no puede ser posterior a la fecha hasta.';
        RETURN;
    END;

    BEGIN TRY
    SELECT
        [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
        [Planificacion].[Nombre],
        [Sede].[IdSede],
        [Sede].[CodigoSede],
        [Sede].[NombreSede],
        [Planificacion].[FechaInicio],
        [Planificacion].[FechaFin],
        DATEDIFF(DAY, [Planificacion].[FechaInicio], [Planificacion].[FechaFin]) + 1 AS [CantidadDias],
        [Planificacion].[Estado],
        [Planificacion].[EstaActivo],
        [Planificacion].[IdColaboradorRegistroCorporativo],
        [Planificacion].[IdColaboradorModificacionCorporativo],
        [Planificacion].[VersionRegistro],
        [Planificacion].[FechaCreacion],
        [Planificacion].[FechaModificacion],
        COUNT_BIG(*) OVER () AS [TotalRegistros]
    FROM [alimentacion].[Planificacion] AS [Planificacion]
    INNER JOIN [PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA].[organizacion].[Sede] AS [Sede]
        ON [Sede].[IdSede] = [Planificacion].[IdSede]
    WHERE (@IdSede IS NULL OR [Planificacion].[IdSede] = @IdSede)
      AND [Planificacion].[EstaActivo] = 1
      AND (@Estado IS NULL OR [Planificacion].[Estado] = @Estado)
      -- El período solicitado incluye las planificaciones que se superponen parcialmente con él.
      AND (@FechaDesde IS NULL OR [Planificacion].[FechaFin] >= @FechaDesde)
      AND (@FechaHasta IS NULL OR [Planificacion].[FechaInicio] <= @FechaHasta)
      AND (@TerminoBusqueda IS NULL OR [Planificacion].[Nombre] LIKE N'%' + @TerminoBusqueda + N'%')
    ORDER BY
        [Planificacion].[FechaInicio] DESC,
        [Planificacion].[FechaFin] DESC,
        [Planificacion].[Nombre] ASC,
        [Planificacion].[IdPlanificacion] DESC
    OFFSET (@NumeroPagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY
    OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ListarPlanificaciones',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO

-- Ejemplo:
-- DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
-- EXEC [alimentacion].[usp_ListarPlanificaciones]
--     @IdSede = 1,
--     @Estado = N'PUBLICADA_ABIERTA',
--     @FechaDesde = '2026-09-01',
--     @FechaHasta = '2026-09-30',
--     @TerminoBusqueda = N'setiembre',
--     @NumeroPagina = 1,
--     @TamanoPagina = 20,
--     @Codigo = @Codigo OUTPUT,
--     @Mensaje = @Mensaje OUTPUT;
-- SELECT @Codigo AS [Codigo], @Mensaje AS [Mensaje];
