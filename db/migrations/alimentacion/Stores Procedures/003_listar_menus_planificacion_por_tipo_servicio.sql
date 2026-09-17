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
    @TipoServicio NVARCHAR(20),
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

    SET @TipoServicio = UPPER(NULLIF(LTRIM(RTRIM(@TipoServicio)), N''));

    IF @TipoServicio IS NULL
       OR @TipoServicio NOT IN (N'DESAYUNO', N'ALMUERZO', N'CENA')
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El tipo de servicio no es válido.';
        RETURN;
    END;

    BEGIN TRY
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
        [Menu].[FechaCreacion],
        [Menu].[FechaModificacion]
    FROM [FechasPeriodo]
    LEFT JOIN [alimentacion].[Menu] AS [Menu]
        ON [Menu].[IdPlanificacion] = [FechasPeriodo].[IdPlanificacion]
       AND [Menu].[FechaServicio] = [FechasPeriodo].[FechaServicio]
       AND [Menu].[TipoServicio] = @TipoServicio
    ORDER BY [FechasPeriodo].[FechaServicio]
    OPTION (MAXRECURSION 0, RECOMPILE);
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ListarMenusPlanificacionPorTipoServicio',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO
