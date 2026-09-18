-- Procedimiento: alimentacion.usp_ObtenerResumenPlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Obtener la cabecera y los conteos de menús y reservas de una planificación.
-- Ejecutar después de la migración 017.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ObtenerResumenPlanificacion]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdPlanificacion IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El identificador de planificación es obligatorio.';
        RETURN;
    END;

    BEGIN TRY
    ;WITH [PlanificacionObjetivo] AS
    (
        SELECT
            [Planificacion].[IdPlanificacion],
            [Planificacion].[IdentificadorPublico],
            [Planificacion].[Nombre],
            [Planificacion].[IdSede],
            [Planificacion].[FechaInicio],
            [Planificacion].[FechaFin],
            [Planificacion].[Estado],
            [Planificacion].[IdColaboradorModificacion],
            [Planificacion].[VersionRegistro],
            [Planificacion].[FechaCreacion],
            [Planificacion].[FechaModificacion]
        FROM [alimentacion].[Planificacion] AS [Planificacion]
        WHERE [Planificacion].[IdentificadorPublico] = @IdPlanificacion
          AND [Planificacion].[Estado] <> N'ELIMINADA'
    ),
    [MenusPorPlanificacion] AS
    (
        SELECT
            [Menu].[IdPlanificacion],
            COUNT_BIG(*) AS [CantidadMenusRegistrados],
            SUM(CASE WHEN [Menu].[EstaDisponible] = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS [CantidadMenusConfigurados],
            SUM(CASE WHEN [Menu].[EstaDisponible] = 0 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS [CantidadServiciosSinAtencion]
        FROM [alimentacion].[Menu] AS [Menu]
        INNER JOIN [PlanificacionObjetivo] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Menu].[IdPlanificacion]
        GROUP BY [Menu].[IdPlanificacion]
    ),
    [ReservasPorPlanificacion] AS
    (
        SELECT
            [Reserva].[IdPlanificacion],
            COUNT_BIG(*) AS [CantidadReservasRegistradas]
        FROM [alimentacion].[Reserva] AS [Reserva]
        INNER JOIN [PlanificacionObjetivo] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
        GROUP BY [Reserva].[IdPlanificacion]
    )
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
        [Planificacion].[IdColaboradorModificacion],
        [Planificacion].[VersionRegistro],
        ISNULL([MenusPorPlanificacion].[CantidadMenusRegistrados], 0) AS [CantidadMenusRegistrados],
        ISNULL([MenusPorPlanificacion].[CantidadMenusConfigurados], 0) AS [CantidadMenusCreados],
        ISNULL([MenusPorPlanificacion].[CantidadServiciosSinAtencion], 0) AS [CantidadServiciosSinAtencion],
        [Planificacion].[FechaCreacion],
        [Planificacion].[FechaModificacion],
        ISNULL([ReservasPorPlanificacion].[CantidadReservasRegistradas], 0) AS [CantidadReservasRegistradas]
    FROM [PlanificacionObjetivo] AS [Planificacion]
    INNER JOIN [organizacion].[Sede] AS [Sede]
        ON [Sede].[IdSede] = [Planificacion].[IdSede]
    LEFT JOIN [MenusPorPlanificacion] AS [MenusPorPlanificacion]
        ON [MenusPorPlanificacion].[IdPlanificacion] = [Planificacion].[IdPlanificacion]
    LEFT JOIN [ReservasPorPlanificacion] AS [ReservasPorPlanificacion]
        ON [ReservasPorPlanificacion].[IdPlanificacion] = [Planificacion].[IdPlanificacion];

    ;WITH [PlanificacionObjetivo] AS
    (
        SELECT [Planificacion].[IdPlanificacion]
        FROM [alimentacion].[Planificacion] AS [Planificacion]
        WHERE [Planificacion].[IdentificadorPublico] = @IdPlanificacion
          AND [Planificacion].[Estado] <> N'ELIMINADA'
    ),
    [MenusPorTipoServicio] AS
    (
        SELECT
            [Menu].[IdPlanificacion],
            [Menu].[TipoServicio],
            COUNT_BIG(*) AS [CantidadMenusRegistrados],
            SUM(CASE WHEN [Menu].[EstaDisponible] = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS [CantidadMenusConfigurados],
            SUM(CASE WHEN [Menu].[EstaDisponible] = 0 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS [CantidadServiciosSinAtencion]
        FROM [alimentacion].[Menu] AS [Menu]
        INNER JOIN [PlanificacionObjetivo] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Menu].[IdPlanificacion]
        GROUP BY [Menu].[IdPlanificacion], [Menu].[TipoServicio]
    ),
    [ReservasPorTipoServicio] AS
    (
        SELECT
            [Reserva].[IdPlanificacion],
            [Reserva].[TipoServicio],
            COUNT_BIG(*) AS [CantidadReservasRegistradas]
        FROM [alimentacion].[Reserva] AS [Reserva]
        INNER JOIN [PlanificacionObjetivo] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
        GROUP BY [Reserva].[IdPlanificacion], [Reserva].[TipoServicio]
    )
    SELECT
        [TipoServicio].[CodigoTipoServicio] AS [TipoServicio],
        [TipoServicio].[NombreTipoServicio] AS [NombreTipoServicio],
        [TipoServicio].[OrdenPresentacion],
        ISNULL([MenusPorTipoServicio].[CantidadMenusRegistrados], 0) AS [CantidadMenusRegistrados],
        ISNULL([MenusPorTipoServicio].[CantidadMenusConfigurados], 0) AS [CantidadMenusConfigurados],
        ISNULL([MenusPorTipoServicio].[CantidadServiciosSinAtencion], 0) AS [CantidadServiciosSinAtencion],
        ISNULL([ReservasPorTipoServicio].[CantidadReservasRegistradas], 0) AS [CantidadReservasRegistradas]
    FROM [PlanificacionObjetivo] AS [Planificacion]
    INNER JOIN [alimentacion].[TipoServicio] AS [TipoServicio]
        ON [TipoServicio].[EstaActivo] = 1
    LEFT JOIN [MenusPorTipoServicio] AS [MenusPorTipoServicio]
        ON [MenusPorTipoServicio].[IdPlanificacion] = [Planificacion].[IdPlanificacion]
       AND [MenusPorTipoServicio].[TipoServicio] = [TipoServicio].[CodigoTipoServicio]
    LEFT JOIN [ReservasPorTipoServicio] AS [ReservasPorTipoServicio]
        ON [ReservasPorTipoServicio].[IdPlanificacion] = [Planificacion].[IdPlanificacion]
       AND [ReservasPorTipoServicio].[TipoServicio] = [TipoServicio].[CodigoTipoServicio]
    ORDER BY [TipoServicio].[OrdenPresentacion], [TipoServicio].[CodigoTipoServicio];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ObtenerResumenPlanificacion',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO
