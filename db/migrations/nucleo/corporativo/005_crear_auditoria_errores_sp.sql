-- Migración: 005_crear_auditoria_errores_sp
-- Fecha: 2026-09-24
-- Entidad(es) afectada(s): auditoria.ErrorProcedimiento, auditoria.usp_RegistrarErrorProcedimiento
-- Referencia: STACK.md / contrato_resultados_y_errores.md
-- Motivo: registrar internamente errores inesperados de procedures API de CO.

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
    -- Procedure interno de auditoria: no forma parte del contrato API.
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
        -- La auditoria no debe reemplazar ni filtrar el contrato seguro de la API.
    END CATCH;
END;
GO

-- DOWN
-- La reversión controlada está centralizada en db/reversiones/revertir_nucleo_corporativo_completo.sql.
