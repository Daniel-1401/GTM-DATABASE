-- Migración: 016_crear_auditoria_errores_sp
-- Entidad(es) afectada(s): auditoria, auditoria.ErrorProcedimiento
-- Motivo: Registrar de manera interna los errores inesperados de SP API.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF SCHEMA_ID(N'auditoria') IS NULL
    EXEC(N'CREATE SCHEMA [auditoria] AUTHORIZATION [dbo]');

CREATE TABLE [auditoria].[ErrorProcedimiento]
(
    [IdErrorProcedimiento] BIGINT IDENTITY(1,1) NOT NULL,
    [NombreProcedimiento] NVARCHAR(256) NOT NULL,
    [NumeroError] INT NULL,
    [EstadoError] INT NULL,
    [LineaError] INT NULL,
    [DetalleInterno] NVARCHAR(2048) NULL,
    [FechaCreacion] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_ErrorProcedimiento_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_ErrorProcedimiento] PRIMARY KEY CLUSTERED ([IdErrorProcedimiento])
);

CREATE INDEX [IN_ErrorProcedimiento_ProcedimientoFecha]
    ON [auditoria].[ErrorProcedimiento] ([NombreProcedimiento], [FechaCreacion] DESC);

COMMIT TRANSACTION;
GO

CREATE OR ALTER PROCEDURE [auditoria].[usp_RegistrarErrorProcedimiento]
    @NombreProcedimiento NVARCHAR(256),
    @NumeroError INT = NULL,
    @EstadoError INT = NULL,
    @LineaError INT = NULL,
    @DetalleInterno NVARCHAR(2048) = NULL
AS
BEGIN
    -- Procedimiento interno de auditoría: no es una API de backend.
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        INSERT INTO [auditoria].[ErrorProcedimiento]
        (
            [NombreProcedimiento], [NumeroError], [EstadoError], [LineaError], [DetalleInterno]
        )
        VALUES
        (
            @NombreProcedimiento, @NumeroError, @EstadoError, @LineaError, @DetalleInterno
        );
    END TRY
    BEGIN CATCH
        -- La auditoría no debe reemplazar ni filtrar el contrato seguro de la API.
    END CATCH;
END;
GO

-- DOWN
/*
DROP PROCEDURE IF EXISTS [auditoria].[usp_RegistrarErrorProcedimiento];
DROP TABLE IF EXISTS [auditoria].[ErrorProcedimiento];
IF SCHEMA_ID(N'auditoria') IS NOT NULL EXEC(N'DROP SCHEMA [auditoria]');
GO
*/
