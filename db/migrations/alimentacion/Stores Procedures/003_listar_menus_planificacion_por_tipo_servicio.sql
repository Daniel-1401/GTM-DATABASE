-- Procedimiento: alimentacion.usp_ListarMenusPlanificacionPorTipoServicio
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Listar todos los días de una planificación para un tipo de servicio,
--         incluyendo los días que aún no tienen una fila de menú.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarMenusPlanificacionPorTipoServicio]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @TipoServicio NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @IdPlanificacion IS NULL
    BEGIN
        ;THROW 50100, N'El identificador de planificación es obligatorio.', 1;
    END;

    SET @TipoServicio = UPPER(NULLIF(LTRIM(RTRIM(@TipoServicio)), N''));

    IF @TipoServicio IS NULL
       OR @TipoServicio NOT IN (N'DESAYUNO', N'ALMUERZO', N'CENA')
    BEGIN
        ;THROW 50101, N'El tipo de servicio debe ser DESAYUNO, ALMUERZO o CENA.', 1;
    END;

    ;WITH [PeriodoPlanificacion] AS
    (
        SELECT
            [Planificacion].[IdPlanificacion],
            [Planificacion].[FechaInicio],
            [Planificacion].[FechaFin]
        FROM [alimentacion].[Planificacion] AS [Planificacion]
        WHERE [Planificacion].[IdentificadorPublico] = @IdPlanificacion
          AND [Planificacion].[Estado] <> N'ELIMINADA'
    ),
    [FechasPeriodo] AS
    (
        SELECT
            [PeriodoPlanificacion].[IdPlanificacion],
            [PeriodoPlanificacion].[FechaInicio] AS [FechaServicio],
            [PeriodoPlanificacion].[FechaFin]
        FROM [PeriodoPlanificacion]

        UNION ALL

        SELECT
            [FechasPeriodo].[IdPlanificacion],
            DATEADD(DAY, 1, [FechasPeriodo].[FechaServicio]),
            [FechasPeriodo].[FechaFin]
        FROM [FechasPeriodo]
        WHERE [FechasPeriodo].[FechaServicio] < [FechasPeriodo].[FechaFin]
    )
    SELECT
        [FechasPeriodo].[FechaServicio],
        @TipoServicio AS [TipoServicio],
        CONVERT(BIT, CASE WHEN [Menu].[IdMenu] IS NULL THEN 0 ELSE 1 END) AS [TieneMenu],
        [Menu].[IdentificadorPublico] AS [IdMenu],
        [Menu].[EstaDisponible],
        [Menu].[EstaActivo],
        [Menu].[IdColaboradorRegistro],
        [Menu].[Nombre],
        [Menu].[Descripcion],
        [Menu].[ReferenciaImagen],
        [Menu].[VersionRegistro],
        [Menu].[FechaCreacionUtc],
        [Menu].[FechaModificacionUtc]
    FROM [FechasPeriodo]
    LEFT JOIN [alimentacion].[Menu] AS [Menu]
        ON [Menu].[IdPlanificacion] = [FechasPeriodo].[IdPlanificacion]
       AND [Menu].[FechaServicio] = [FechasPeriodo].[FechaServicio]
       AND [Menu].[TipoServicio] = @TipoServicio
    ORDER BY [FechasPeriodo].[FechaServicio]
    OPTION (MAXRECURSION 0, RECOMPILE);
END;
GO
