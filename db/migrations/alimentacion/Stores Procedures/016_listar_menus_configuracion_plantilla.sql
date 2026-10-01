-- Procedimiento: alimentacion.usp_ListarMenusConfiguracionPlantilla
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Listar los menús configurados de una planificación y sus reservas.
-- Ejecutar después de las migraciones 011 y 017.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarMenusConfiguracionPlantilla]
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
            SELECT [Planificacion].[IdPlanificacion]
            FROM [alimentacion].[Planificacion] AS [Planificacion]
            WHERE [Planificacion].[IdentificadorPublico] = @IdPlanificacion
              AND [Planificacion].[Estado] <> N'ELIMINADA'
        ),
        [MenusObjetivo] AS
        (
            SELECT
                [Menu].[IdMenu],
                [Menu].[IdPlanificacion],
                [Menu].[FechaServicio],
                [Menu].[TipoServicio],
                [Menu].[IdentificadorPublico],
                [Menu].[Nombre]
            FROM [alimentacion].[Menu] AS [Menu]
            INNER JOIN [PlanificacionObjetivo] AS [Planificacion]
                ON [Planificacion].[IdPlanificacion] = [Menu].[IdPlanificacion]
        ),
        [ReservasPorMenu] AS
        (
            SELECT
                [Reserva].[IdPlanificacion],
                [Reserva].[IdMenu],
                COUNT_BIG(*) AS [CantidadReservas]
            FROM [alimentacion].[Reserva] AS [Reserva]
            INNER JOIN [MenusObjetivo] AS [Menu]
                ON [Menu].[IdPlanificacion] = [Reserva].[IdPlanificacion]
               AND [Menu].[IdMenu] = [Reserva].[IdMenu]
            WHERE [Reserva].[Estado] = N'RESERVADA'
            GROUP BY [Reserva].[IdPlanificacion], [Reserva].[IdMenu]
        )
        SELECT
            [Menu].[FechaServicio], [Menu].[TipoServicio],
            [Menu].[IdentificadorPublico] AS [IdMenu], [Menu].[Nombre] AS [NombreMenu],
            ISNULL([ReservasPorMenu].[CantidadReservas], 0) AS [CantidadReservas]
        FROM [MenusObjetivo] AS [Menu]
        LEFT JOIN [ReservasPorMenu] AS [ReservasPorMenu]
            ON [ReservasPorMenu].[IdPlanificacion] = [Menu].[IdPlanificacion]
           AND [ReservasPorMenu].[IdMenu] = [Menu].[IdMenu]
        ORDER BY [Menu].[FechaServicio], [Menu].[TipoServicio], [Menu].[IdMenu];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ListarMenusConfiguracionPlantilla',
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
    DECLARE @IdPlanificacion UNIQUEIDENTIFIER = '2D2F75E9-E2B2-F111-B1C0-0050568F0125'
    EXEC [alimentacion].[usp_ListarMenusConfiguracionPlantilla] @IdPlanificacion, @Codigo, @Mensaje;

 */
