-- Migración: 001_crear_esquemas_unidad_organizativa
-- Fecha: 2026-09-24
-- Entidad(es) afectada(s): schemas rrhh, organizacion
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Crear los espacios de nombres de la instancia hija por UO.

-- UP
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF SCHEMA_ID(N'rrhh') IS NULL
    EXEC(N'CREATE SCHEMA [rrhh] AUTHORIZATION [dbo]');

IF SCHEMA_ID(N'organizacion') IS NULL
    EXEC(N'CREATE SCHEMA [organizacion] AUTHORIZATION [dbo]');

COMMIT TRANSACTION;
GO

-- DOWN
-- La reversión se ejecuta centralizadamente en
-- db/reversiones/revertir_nucleo_unidad_organizativa_completo.sql, después de
-- eliminar las tablas dependientes.
