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
    @TamanoPagina INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SET @TerminoBusqueda = NULLIF(LTRIM(RTRIM(@TerminoBusqueda)), N'');

    IF (@NumeroPagina < 1)
    BEGIN
        ;THROW 50001, N'El número de página debe ser mayor o igual a uno.', 1;
    END;

    IF (@TamanoPagina NOT BETWEEN 1 AND 100)
    BEGIN
        ;THROW 50002, N'El tamaño de página debe estar entre uno y cien.', 1;
    END;

    IF @Estado IS NOT NULL
       AND @Estado NOT IN (N'BORRADOR', N'PUBLICADA_ABIERTA', N'PUBLICADA_CERRADA', N'CONSOLIDADA')
    BEGIN
        ;THROW 50003, N'El estado de planificación no es válido.', 1;
    END;

    IF @FechaDesde IS NOT NULL
       AND @FechaHasta IS NOT NULL
       AND @FechaDesde > @FechaHasta
    BEGIN
        ;THROW 50004, N'La fecha desde no puede ser posterior a la fecha hasta.', 1;
    END;

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
        [Planificacion].[IdColaboradorRegistro],
        [Planificacion].[VersionRegistro],
        [Planificacion].[FechaCreacionUtc],
        [Planificacion].[FechaModificacionUtc],
        COUNT_BIG(*) OVER () AS [TotalRegistros]
    FROM [alimentacion].[Planificacion] AS [Planificacion]
    INNER JOIN [organizacion].[Sede] AS [Sede]
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
END;
GO

-- Ejemplo:
-- EXEC [alimentacion].[usp_ListarPlanificaciones]
--     @IdSede = 1,
--     @Estado = N'PUBLICADA_ABIERTA',
--     @FechaDesde = '2026-09-01',
--     @FechaHasta = '2026-09-30',
--     @TerminoBusqueda = N'setiembre',
--     @NumeroPagina = 1,
--     @TamanoPagina = 20;
