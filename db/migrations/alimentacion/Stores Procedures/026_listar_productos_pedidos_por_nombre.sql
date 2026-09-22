-- Procedimiento: alimentacion.usp_ListarProductosPedidosPorNombre
-- Referencia: Base de datos externa [PEDIDOS], tabla [ayb].[Producto].
-- Motivo: Exponer los productos para su selección al crear un menú de planificación.
-- Requisito operativo: la cuenta de ejecución debe tener permiso SELECT sobre
--                      [PEDIDOS].[ayb].[Producto].

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarProductosPedidosPorNombre]
    @Nombre NVARCHAR(500),
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    SET @Nombre = NULLIF(LTRIM(RTRIM(@Nombre)), N'');

    IF @Nombre IS NULL
    BEGIN
        SET @Codigo = N'INVALID_FILTER';
        SET @Mensaje = N'El filtro de nombre es obligatorio.';
        RETURN;
    END;

    DECLARE @PatronNombre NVARCHAR(2000);

    SET @PatronNombre = REPLACE(@Nombre, N'\', N'\\');
    SET @PatronNombre = REPLACE(@PatronNombre, N'%', N'\%');
    SET @PatronNombre = REPLACE(@PatronNombre, N'_', N'\_');
    SET @PatronNombre = REPLACE(@PatronNombre, N'[', N'\[');

    BEGIN TRY
        SELECT
            [Producto].[ProductoID] AS [IdProducto],
            [Producto].[Nombre],
            [Producto].[Descripcion]
        FROM [PEDIDOS].[ayb].[Producto] AS [Producto]
        WHERE [Producto].[Nombre] LIKE N'%' + @PatronNombre + N'%' ESCAPE N'\'
        ORDER BY [Producto].[Nombre], [Producto].[ProductoID];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ListarProductosPedidosPorNombre',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO

/*
    DECLARE @Nombre NVARCHAR(500) = 'caf',
            @Codigo NVARCHAR(50),
            @Mensaje NVARCHAR(500);
    EXEC [alimentacion].[usp_ListarProductosPedidosPorNombre] @Nombre, @Codigo, @Mensaje;

 */