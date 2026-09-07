-- Migración: 006_crear_asignaciones_organizacionales_y_referencias_posicion_sap
-- Fecha: 2026-09-04T08:00:21-05:00
-- Entidad(es) afectada(s): rrhh.AsignacionOrganizacional
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Historiar el contexto de sede, área, cargo y centro de costo de cada relación laboral sin anticipar reglas procedurales.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [rrhh].[AsignacionOrganizacional]
(
    [IdAsignacionOrganizacional] BIGINT IDENTITY(1,1) NOT NULL,
    [IdRelacionLaboral] BIGINT NOT NULL,
    [IdSede] INT NOT NULL,
    [IdArea] INT NOT NULL,
    [IdCargo] INT NOT NULL,
    [FechaInicio] DATE NOT NULL,
    [FechaFin] DATE NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_AsignacionOrganizacional_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_AsignacionOrganizacional] PRIMARY KEY CLUSTERED ([IdAsignacionOrganizacional]),
    CONSTRAINT [CE_AsignacionOrganizacional_RelacionLaboral] FOREIGN KEY ([IdRelacionLaboral]) REFERENCES [rrhh].[RelacionLaboral] ([IdRelacionLaboral]),
    CONSTRAINT [CE_AsignacionOrganizacional_Sede] FOREIGN KEY ([IdSede]) REFERENCES [organizacion].[Sede] ([IdSede]),
    CONSTRAINT [CE_AsignacionOrganizacional_Area] FOREIGN KEY ([IdArea]) REFERENCES [organizacion].[Area] ([IdArea]),
    CONSTRAINT [CE_AsignacionOrganizacional_Cargo] FOREIGN KEY ([IdCargo]) REFERENCES [organizacion].[Cargo] ([IdCargo]),
    CONSTRAINT [RV_AsignacionOrganizacional_Vigencia] CHECK ([FechaFin] IS NULL OR [FechaFin] > [FechaInicio])
);

CREATE UNIQUE INDEX [IN_AsignacionOrganizacional_Abierta]
    ON [rrhh].[AsignacionOrganizacional] ([IdRelacionLaboral])
    WHERE [FechaFin] IS NULL;

CREATE INDEX [IN_AsignacionOrganizacional_RelacionVigencia]
    ON [rrhh].[AsignacionOrganizacional] ([IdRelacionLaboral], [FechaInicio], [FechaFin])
    INCLUDE ([IdSede], [IdArea], [IdCargo]);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada.
/*
DROP TABLE IF EXISTS [rrhh].[AsignacionOrganizacional];
GO
*/
