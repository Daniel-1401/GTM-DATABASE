-- Migración: 001_crear_usuario_referencia_colaborador
-- Fecha: 2026-09-25
-- Entidad(es) afectada(s): dbo.UsuarioReferenciaColaborador
-- Referencia: docs-proyecto/STACK.md / docs-proyecto/nucleo/er-diagram-v1.md
-- Motivo: vincular de forma aditiva un usuario legacy con sus GUID corporativos del núcleo GTM.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [dbo].[UsuarioReferenciaColaborador]
(
    [UsuarioId] INT NOT NULL,
    [IdUsuarioCorporativo] UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT [VP_UsuarioReferenciaColaborador_IdUsuarioCorporativo] DEFAULT (NEWID()),
    [IdColaboradorCorporativo] UNIQUEIDENTIFIER NULL,
    [EstaActiva] BIT NOT NULL
        CONSTRAINT [VP_UsuarioReferenciaColaborador_EstaActiva] DEFAULT (1),
    [FechaCrea] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_UsuarioReferenciaColaborador_FechaCrea] DEFAULT (SYSDATETIME()),
    [FechaModifica] DATETIME2(3) NULL,
    CONSTRAINT [CP_UsuarioReferenciaColaborador] PRIMARY KEY CLUSTERED ([UsuarioId]),
    CONSTRAINT [CU_UsuarioReferenciaColaborador_UsuarioCorporativo] UNIQUE ([IdUsuarioCorporativo]),
    CONSTRAINT [CA_UsuarioReferenciaColaborador_Usuario] FOREIGN KEY ([UsuarioId])
        REFERENCES [dbo].[Usuario] ([UsuarioId])
);

CREATE UNIQUE INDEX [IU_UsuarioReferenciaColaborador_ColaboradorActivo]
    ON [dbo].[UsuarioReferenciaColaborador] ([IdColaboradorCorporativo])
    WHERE [EstaActiva] = 1 AND [IdColaboradorCorporativo] IS NOT NULL;

COMMIT TRANSACTION;
GO

-- DOWN
-- La reversión controlada está centralizada en db/reversiones/revertir_usermanagementcorp_referencia_colaborador.sql.
