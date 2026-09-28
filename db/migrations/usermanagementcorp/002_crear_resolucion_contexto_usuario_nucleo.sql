-- Migración: 002_crear_resolucion_contexto_usuario_nucleo
-- Fecha: 2026-09-25
-- Entidad(es) afectada(s): auditoria.ErrorProcedimiento,
-- auditoria.usp_RegistrarErrorProcedimiento,
-- dbo.usp_ResolverContextoUsuarioNucleoPorAcceso
-- Referencia: docs-proyecto/usermanagementcorp/TABLAS_REFERENCIA_COLABORADOR.md
-- Motivo: resolver un usuario legacy activo por acceso exacto y su vínculo lógico al núcleo.

-- CREATE SCHEMA requiere su propio batch; no reutiliza ni oculta objetos homónimos.
IF SCHEMA_ID(N'auditoria') IS NULL
    EXEC(N'CREATE SCHEMA [auditoria] AUTHORIZATION [dbo];');
GO

-- UP: auditoría local exclusiva para el CATCH del procedure API nuevo.
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE [auditoria].[ErrorProcedimiento]
    (
        [IdErrorProcedimiento] BIGINT IDENTITY(1, 1) NOT NULL,
        [NombreProcedimiento] SYSNAME NOT NULL,
        [ProcedimientoError] NVARCHAR(128) NULL,
        [NumeroError] INT NOT NULL,
        [SeveridadError] INT NULL,
        [EstadoError] INT NULL,
        [LineaError] INT NULL,
        [DetalleInterno] NVARCHAR(2048) NULL,
        [FechaCreacion] DATETIME2(3) NOT NULL
            CONSTRAINT [VP_ErrorProcedimiento_FechaCreacion] DEFAULT (SYSDATETIME()),
        CONSTRAINT [CP_ErrorProcedimiento] PRIMARY KEY CLUSTERED ([IdErrorProcedimiento])
    );

    CREATE INDEX [IX_ErrorProcedimiento_FechaCreacion]
        ON [auditoria].[ErrorProcedimiento] ([FechaCreacion]);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- Procedure interno de mejor esfuerzo: no se expone al backend ni propaga errores.
CREATE PROCEDURE [auditoria].[usp_RegistrarErrorProcedimiento]
    @NombreProcedimiento SYSNAME,
    @ProcedimientoError NVARCHAR(128) = NULL,
    @NumeroError INT,
    @SeveridadError INT = NULL,
    @EstadoError INT = NULL,
    @LineaError INT = NULL,
    @DetalleInterno NVARCHAR(2048) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO [auditoria].[ErrorProcedimiento]
        (
            [NombreProcedimiento],
            [ProcedimientoError],
            [NumeroError],
            [SeveridadError],
            [EstadoError],
            [LineaError],
            [DetalleInterno]
        )
        VALUES
        (
            @NombreProcedimiento,
            @ProcedimientoError,
            @NumeroError,
            @SeveridadError,
            @EstadoError,
            @LineaError,
            @DetalleInterno
        );
    END TRY
    BEGIN CATCH
        RETURN;
    END CATCH;
END;
GO