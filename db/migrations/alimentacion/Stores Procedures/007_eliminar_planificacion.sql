-- Procedimiento: alimentacion.usp_EliminarPlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Retirar lógicamente una planificación en BORRADOR sin borrar su historial.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_EliminarPlanificacion]
    @IdPlanificacion UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @IdPlanificacion IS NULL
    BEGIN
        ;THROW 50250, N'El identificador de planificación es obligatorio.', 1;
    END;
    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @FechaEliminacionUtc DATETIME2(3);

    BEGIN TRANSACTION;

    SELECT
        @IdPlanificacionInterno = [IdPlanificacion],
        @EstadoPlanificacion = [Estado]
    FROM [alimentacion].[Planificacion] WITH (UPDLOCK, HOLDLOCK)
    WHERE [IdentificadorPublico] = @IdPlanificacion;

    IF @IdPlanificacionInterno IS NULL
    BEGIN
        ;THROW 50251, N'La planificación indicada no existe.', 1;
    END;

    IF @EstadoPlanificacion = N'ELIMINADA'
    BEGIN
        ;THROW 50252, N'La planificación ya fue eliminada.', 1;
    END;

    IF @EstadoPlanificacion <> N'BORRADOR'
    BEGIN
        ;THROW 50253, N'Solo se pueden eliminar planificaciones en BORRADOR.', 1;
    END;

    SET @FechaEliminacionUtc = SYSUTCDATETIME();

    UPDATE [Componente]
    SET [EstaActivo] = 0
    FROM [alimentacion].[ComponenteMenu] AS [Componente]
    INNER JOIN [alimentacion].[Menu] AS [Menu]
        ON [Menu].[IdMenu] = [Componente].[IdMenu]
    WHERE [Menu].[IdPlanificacion] = @IdPlanificacionInterno
      AND [Componente].[EstaActivo] = 1;

    UPDATE [alimentacion].[Menu]
    SET
        [EstaActivo] = 0,
        [VersionRegistro] = [VersionRegistro] + 1,
        [FechaModificacionUtc] = @FechaEliminacionUtc
    WHERE [IdPlanificacion] = @IdPlanificacionInterno
      AND [EstaActivo] = 1;

    UPDATE [alimentacion].[Planificacion]
    SET
        [Estado] = N'ELIMINADA',
        [EstaActivo] = 0,
        [VersionRegistro] = [VersionRegistro] + 1,
        [FechaModificacionUtc] = @FechaEliminacionUtc
    WHERE [IdPlanificacion] = @IdPlanificacionInterno;

    COMMIT TRANSACTION;

    SELECT
        [IdentificadorPublico] AS [IdPlanificacion],
        [Estado],
        [EstaActivo],
        [VersionRegistro],
        [FechaModificacionUtc]
    FROM [alimentacion].[Planificacion]
    WHERE [IdPlanificacion] = @IdPlanificacionInterno;
END;
GO

-- EXEC [alimentacion].[usp_EliminarPlanificacion]
--     @IdPlanificacion = '00000000-0000-0000-0000-000000000000';
