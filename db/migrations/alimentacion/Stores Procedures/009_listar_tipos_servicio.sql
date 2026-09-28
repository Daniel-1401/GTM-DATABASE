-- Procedimiento: alimentacion.usp_ListarTiposServicio
-- Referencia: db/migrations/alimentacion/009_crear_schema_y_configuracion_alimentacion.sql
-- Motivo: Exponer al frontend los tipos de servicio vigentes para menú.
-- Ejecutar después de la migración 009.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarTiposServicio]
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
            [TipoServicio].[CodigoTipoServicio] AS [Codigo],
            [TipoServicio].[NombreTipoServicio] AS [Nombre],
            [TipoServicio].[OrdenPresentacion]
        FROM [alimentacion].[TipoServicio] AS [TipoServicio]
        WHERE [TipoServicio].[EstaActivo] = 1
        ORDER BY [TipoServicio].[OrdenPresentacion], [TipoServicio].[CodigoTipoServicio];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ListarTiposServicio',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO
