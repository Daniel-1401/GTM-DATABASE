-- Procedimiento: alimentacion.usp_ObtenerResumenPlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Obtener la cabecera y el conteo global de menús de una planificación.
-- Ejecutar después de la migración 010.

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
        COUNT([Menu].[IdMenu]) AS [CantidadMenusRegistrados],
        SUM(CASE WHEN [Menu].[EstaDisponible] = 1 THEN 1 ELSE 0 END) AS [CantidadMenusCreados],
        SUM(CASE WHEN [Menu].[EstaDisponible] = 0 THEN 1 ELSE 0 END) AS [CantidadServiciosSinAtencion],
        [Planificacion].[FechaCreacion],
        [Planificacion].[FechaModificacion]
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
        [Planificacion].[IdColaboradorModificacion],
        [Planificacion].[VersionRegistro],
        [Planificacion].[FechaCreacion],
        [Planificacion].[FechaModificacion];
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
