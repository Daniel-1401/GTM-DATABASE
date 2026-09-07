-- Migración: 008_crear_jefaturas_relaciones_laborales
-- Fecha: 2026-09-04T08:00:21-05:00
-- Entidad(es) afectada(s): rrhh.JefaturaRelacionLaboral
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Vincular relaciones laborales subordinada y supervisora con historia, tipo y dos prioridades posibles.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [rrhh].[JefaturaRelacionLaboral]
(
    [IdJefaturaRelacionLaboral] BIGINT IDENTITY(1,1) NOT NULL,
    [IdRelacionLaboralSubordinada] BIGINT NOT NULL,
    [IdRelacionLaboralJefatura] BIGINT NOT NULL,
    [IdTipoJefatura] SMALLINT NOT NULL,
    [Prioridad] TINYINT NOT NULL,
    [FechaInicio] DATE NOT NULL,
    [FechaFin] DATE NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_JefaturaRelacionLaboral_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_JefaturaRelacionLaboral] PRIMARY KEY CLUSTERED ([IdJefaturaRelacionLaboral]),
    CONSTRAINT [CE_JefaturaRelacionLaboral_Subordinada] FOREIGN KEY ([IdRelacionLaboralSubordinada]) REFERENCES [rrhh].[RelacionLaboral] ([IdRelacionLaboral]),
    CONSTRAINT [CE_JefaturaRelacionLaboral_Jefatura] FOREIGN KEY ([IdRelacionLaboralJefatura]) REFERENCES [rrhh].[RelacionLaboral] ([IdRelacionLaboral]),
    CONSTRAINT [CE_JefaturaRelacionLaboral_TipoJefatura] FOREIGN KEY ([IdTipoJefatura]) REFERENCES [catalogo].[TipoJefatura] ([IdTipoJefatura]),
    CONSTRAINT [RV_JefaturaRelacionLaboral_Distintas] CHECK ([IdRelacionLaboralSubordinada] <> [IdRelacionLaboralJefatura]),
    CONSTRAINT [RV_JefaturaRelacionLaboral_Prioridad] CHECK ([Prioridad] IN (1, 2)),
    CONSTRAINT [RV_JefaturaRelacionLaboral_Vigencia] CHECK ([FechaFin] IS NULL OR [FechaFin] > [FechaInicio])
);

CREATE UNIQUE INDEX [IN_JefaturaRelacionLaboral_PrioridadAbierta]
    ON [rrhh].[JefaturaRelacionLaboral] ([IdRelacionLaboralSubordinada], [Prioridad])
    WHERE [FechaFin] IS NULL;

CREATE INDEX [IN_JefaturaRelacionLaboral_SubordinadaVigencia]
    ON [rrhh].[JefaturaRelacionLaboral] ([IdRelacionLaboralSubordinada], [FechaInicio], [FechaFin])
    INCLUDE ([IdRelacionLaboralJefatura], [IdTipoJefatura], [Prioridad]);

CREATE INDEX [IN_JefaturaRelacionLaboral_JefaturaVigencia]
    ON [rrhh].[JefaturaRelacionLaboral] ([IdRelacionLaboralJefatura], [FechaInicio], [FechaFin])
    INCLUDE ([IdRelacionLaboralSubordinada], [IdTipoJefatura], [Prioridad]);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. El máximo histórico sin solapamientos queda pendiente de una fase posterior.
/*
DROP TABLE IF EXISTS [rrhh].[JefaturaRelacionLaboral];
GO
*/

