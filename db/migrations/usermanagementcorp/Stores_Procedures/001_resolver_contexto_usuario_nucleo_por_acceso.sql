-- Procedimiento: dbo.usp_ResolverContextoUsuarioNucleoPorAcceso
-- Referencia: migrations/usermanagementcorp/002_crear_resolucion_contexto_usuario_nucleo.sql
-- Motivo: resolver un usuario legacy activo por acceso exacto o UsuarioId y su vinculo logico al nucleo.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[usp_ResolverContextoUsuarioNucleoPorAcceso]
    @UsuarioAcceso VARCHAR(100) = NULL,
    @UsuarioId INT = NULL,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    /**
      DECLARE @UsuarioAcceso VARCHAR(100) = 'CAVALOS',
              @UsuarioId INT = NULL,
              @Codigo NVARCHAR(50),
              @Mensaje NVARCHAR(500);
      EXEC [dbo].[usp_ResolverContextoUsuarioNucleoPorAcceso]
          @UsuarioAcceso = @UsuarioAcceso,
          @UsuarioId = @UsuarioId,
          @Codigo = @Codigo OUTPUT,
          @Mensaje = @Mensaje OUTPUT;

     */

    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    BEGIN TRY
        DECLARE @TieneUsuarioAcceso BIT =
            CASE WHEN NULLIF(LTRIM(RTRIM(@UsuarioAcceso)), '') IS NULL THEN 0 ELSE 1 END;

        IF @TieneUsuarioAcceso = 0 AND @UsuarioId IS NULL
        BEGIN
            SET @Codigo = N'BAD_REQUEST';
            SET @Mensaje = N'UsuarioAcceso o UsuarioId es obligatorio.';
            RETURN;
        END;

        IF @UsuarioId IS NOT NULL AND @UsuarioId <= 0
        BEGIN
            SET @Codigo = N'BAD_REQUEST';
            SET @Mensaje = N'UsuarioId debe ser mayor que cero.';
            RETURN;
        END;

        DECLARE @CantidadUsuario BIGINT;
        DECLARE @EsActivoUsuario BIT;

        SELECT @CantidadUsuario = COUNT_BIG(1)
        FROM [dbo].[Usuario] AS [u]
        WHERE (@UsuarioId IS NULL OR [u].[UsuarioId] = @UsuarioId)
          AND (@TieneUsuarioAcceso = 0 OR [u].[UsuarioAcceso] = @UsuarioAcceso);

        IF @CantidadUsuario = 0
        BEGIN
            SET @Codigo = N'NOT_FOUND';
            SET @Mensaje = N'El usuario no fue encontrado.';
            RETURN;
        END;

        IF @CantidadUsuario > 1
        BEGIN
            SET @Codigo = N'CONFLICT';
            SET @Mensaje = N'La identidad de usuario es ambigua.';
            RETURN;
        END;

        SELECT @EsActivoUsuario = [u].[EsActivoUsuario]
        FROM [dbo].[Usuario] AS [u]
        WHERE (@UsuarioId IS NULL OR [u].[UsuarioId] = @UsuarioId)
          AND (@TieneUsuarioAcceso = 0 OR [u].[UsuarioAcceso] = @UsuarioAcceso);

        IF ISNULL(@EsActivoUsuario, 0) = 0
        BEGIN
            SET @Codigo = N'FORBIDDEN';
            SET @Mensaje = N'El usuario no está activo.';
            RETURN;
        END;

        SELECT
            [u].[UsuarioId],
            [u].[CodigoColaborador],
            [u].[UsuarioAcceso],
            [u].[Correo],
            [u].[EsActivoUsuario],
            [r].[IdUsuarioCorporativo],
            [r].[IdColaboradorCorporativo],
            CAST(CASE WHEN [r].[UsuarioId] IS NULL THEN 0 ELSE 1 END AS BIT) AS [TieneVinculoNucleo],
            [r].[EstaActiva] AS [EstaActivoVinculo]
        FROM [dbo].[Usuario] AS [u]
        LEFT JOIN [dbo].[UsuarioReferenciaColaborador] AS [r]
            ON [r].[UsuarioId] = [u].[UsuarioId]
        WHERE (@UsuarioId IS NULL OR [u].[UsuarioId] = @UsuarioId)
          AND (@TieneUsuarioAcceso = 0 OR [u].[UsuarioAcceso] = @UsuarioAcceso);
    END TRY
    BEGIN CATCH
        DECLARE @NumeroError INT = ERROR_NUMBER();
        DECLARE @SeveridadError INT = ERROR_SEVERITY();
        DECLARE @EstadoError INT = ERROR_STATE();
        DECLARE @LineaError INT = ERROR_LINE();
        DECLARE @ProcedimientoError NVARCHAR(128) = ERROR_PROCEDURE();
        DECLARE @DetalleInterno NVARCHAR(2048) = CONVERT(NVARCHAR(2048), ERROR_MESSAGE());

        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        BEGIN TRY
            EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
                @NombreProcedimiento = N'dbo.usp_ResolverContextoUsuarioNucleoPorAcceso',
                @ProcedimientoError = @ProcedimientoError,
                @NumeroError = @NumeroError,
                @SeveridadError = @SeveridadError,
                @EstadoError = @EstadoError,
                @LineaError = @LineaError,
                @DetalleInterno = @DetalleInterno;
        END TRY
        BEGIN CATCH
            -- La auditoría no puede modificar la respuesta segura del API.
            DECLARE @NumeroErrorAuditoria INT = ERROR_NUMBER();
        END CATCH;

        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO
