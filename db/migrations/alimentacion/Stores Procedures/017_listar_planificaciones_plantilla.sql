-- Procedimiento: alimentacion.usp_ListarPlanificacionesPlantilla
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Exponer a sistemas consumidores el listado simple de planificaciones.
-- Ejecutar después de la migración 017.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarPlanificacionesPlantilla]
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    BEGIN TRY
        SELECT
            [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
            [Planificacion].[Nombre],
            [Planificacion].[FechaInicio],
            [Planificacion].[FechaFin]
        FROM [alimentacion].[Planificacion] AS [Planificacion]
        WHERE [Planificacion].[EstaActivo] = 1
          AND [Planificacion].[Estado] = N'CONSOLIDADA'
        ORDER BY
            [Planificacion].[FechaInicio] DESC,
            [Planificacion].[FechaFin] DESC,
            [Planificacion].[Nombre] ASC,
            [Planificacion].[IdPlanificacion] DESC;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ListarPlanificacionesPlantilla',
            @NumeroError = @NumeroErrorCapturado,
            @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado,
            @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO

/*
    DECLARE @Codigo NVARCHAR(50),
            @Mensaje NVARCHAR(500);
    EXEC [alimentacion].[usp_ListarPlanificacionesPlantilla] @Codigo, @Mensaje;

 */