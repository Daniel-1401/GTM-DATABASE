-- Procedimiento: alimentacion.usp_ObtenerResumenPlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Obtener la cabecera y el conteo global de menús de una planificación.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ObtenerResumenPlanificacion]
    @IdPlanificacion UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF @IdPlanificacion IS NULL
    BEGIN
        ;THROW 50100, N'El identificador de planificación es obligatorio.', 1;
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
        [Planificacion].[VersionRegistro],
        COUNT([Menu].[IdMenu]) AS [CantidadMenusRegistrados],
        SUM(CASE WHEN [Menu].[EstaDisponible] = 1 THEN 1 ELSE 0 END) AS [CantidadMenusCreados],
        SUM(CASE WHEN [Menu].[EstaDisponible] = 0 THEN 1 ELSE 0 END) AS [CantidadServiciosSinAtencion],
        [Planificacion].[FechaCreacionUtc],
        [Planificacion].[FechaModificacionUtc]
    FROM [alimentacion].[Planificacion] AS [Planificacion]
    INNER JOIN [organizacion].[Sede] AS [Sede]
        ON [Sede].[IdSede] = [Planificacion].[IdSede]
    LEFT JOIN [alimentacion].[Menu] AS [Menu]
        ON [Menu].[IdPlanificacion] = [Planificacion].[IdPlanificacion]
    WHERE [Planificacion].[IdentificadorPublico] = @IdPlanificacion
      AND [Planificacion].[Estado] <> N'ELIMINADA'
    GROUP BY
        [Planificacion].[IdentificadorPublico],
        [Planificacion].[Nombre],
        [Sede].[IdSede],
        [Sede].[CodigoSede],
        [Sede].[NombreSede],
        [Planificacion].[FechaInicio],
        [Planificacion].[FechaFin],
        [Planificacion].[Estado],
        [Planificacion].[VersionRegistro],
        [Planificacion].[FechaCreacionUtc],
        [Planificacion].[FechaModificacionUtc];
END;
GO
