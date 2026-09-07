-- Migración: 001_crear_esquemas_nucleo
-- Fecha: 2026-09-04T08:00:21-05:00
-- Entidad(es) afectada(s): catalogo, rrhh, organizacion, integracion
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Separar los dominios lógicos del núcleo GTM sin crear una base de datos ni tocar objetos externos.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF SCHEMA_ID(N'catalogo') IS NULL
    EXEC(N'CREATE SCHEMA [catalogo] AUTHORIZATION [dbo]');

IF SCHEMA_ID(N'rrhh') IS NULL
    EXEC(N'CREATE SCHEMA [rrhh] AUTHORIZATION [dbo]');

IF SCHEMA_ID(N'organizacion') IS NULL
    EXEC(N'CREATE SCHEMA [organizacion] AUTHORIZATION [dbo]');

IF SCHEMA_ID(N'integracion') IS NULL
    EXEC(N'CREATE SCHEMA [integracion] AUTHORIZATION [dbo]');

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. Ejecutar únicamente después de revertir 008 a 002.
/*
IF SCHEMA_ID(N'integracion') IS NOT NULL EXEC(N'DROP SCHEMA [integracion]');
IF SCHEMA_ID(N'organizacion') IS NOT NULL EXEC(N'DROP SCHEMA [organizacion]');
IF SCHEMA_ID(N'rrhh') IS NOT NULL EXEC(N'DROP SCHEMA [rrhh]');
IF SCHEMA_ID(N'catalogo') IS NOT NULL EXEC(N'DROP SCHEMA [catalogo]');
GO
*/
