-- Migración: 005_crear_relaciones_laborales_y_referencias_empleado_sap
-- Fecha: 2026-09-04T08:00:21-05:00
-- Entidad(es) afectada(s): rrhh.RelacionLaboral
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: Conservar reingresos y planillas simultáneas como relaciones independientes.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [rrhh].[RelacionLaboral]
(
    [IdRelacionLaboral] BIGINT IDENTITY(1,1) NOT NULL,
    [IdColaborador] BIGINT NOT NULL,
    [IdEmpresa] INT NOT NULL,
    [FechaInicio] DATE NOT NULL,
    [FechaFin] DATE NULL,
    [MotivoFin] NVARCHAR(250) NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_RelacionLaboral_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_RelacionLaboral] PRIMARY KEY CLUSTERED ([IdRelacionLaboral]),
    CONSTRAINT [CE_RelacionLaboral_Colaborador] FOREIGN KEY ([IdColaborador]) REFERENCES [rrhh].[Colaborador] ([IdColaborador]),
    CONSTRAINT [CE_RelacionLaboral_Empresa] FOREIGN KEY ([IdEmpresa]) REFERENCES [organizacion].[Empresa] ([IdEmpresa]),
    CONSTRAINT [RV_RelacionLaboral_Vigencia] CHECK ([FechaFin] IS NULL OR [FechaFin] > [FechaInicio]),
    CONSTRAINT [RV_RelacionLaboral_MotivoFin] CHECK ([FechaFin] IS NOT NULL OR [MotivoFin] IS NULL)
);

CREATE INDEX [IN_RelacionLaboral_ColaboradorVigencia]
    ON [rrhh].[RelacionLaboral] ([IdColaborador], [FechaInicio], [FechaFin])
    INCLUDE ([IdEmpresa]);

CREATE INDEX [IN_RelacionLaboral_EmpresaVigencia]
    ON [rrhh].[RelacionLaboral] ([IdEmpresa], [FechaInicio], [FechaFin])
    INCLUDE ([IdColaborador]);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. Elimina las relaciones laborales.
/*
DROP TABLE IF EXISTS [rrhh].[RelacionLaboral];
GO
*/
