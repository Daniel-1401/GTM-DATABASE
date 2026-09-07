-- Migración: 012_crear_idempotencia_y_auditoria_alimentacion
-- Fecha: 2026-09-04T12:00:00-05:00
-- Entidad(es) afectada(s): alimentacion.RegistroIdempotencia, alimentacion.EventoAuditoria
-- Referencia: Lineamientos/Alimentacion/contratos/API_REST.md y funcionalidades/05_AUDITORIA_Y_REPORTES.md / STACK.md
-- Motivo: Evitar efectos duplicados en mutaciones y conservar eventos minimizados, separados de los logs técnicos.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [alimentacion].[RegistroIdempotencia]
(
    [IdRegistroIdempotencia] BIGINT IDENTITY(1,1) NOT NULL,
    [ClaveIdempotencia] UNIQUEIDENTIFIER NOT NULL,
    [IdActorColaborador] BIGINT NOT NULL,
    [Operacion] NVARCHAR(100) NOT NULL,
    [HashSolicitud] VARBINARY(64) NOT NULL,
    [IdCorrelacion] UNIQUEIDENTIFIER NOT NULL,
    [EstadoProcesamiento] NVARCHAR(20) NOT NULL CONSTRAINT [VP_RegistroIdempotencia_EstadoProcesamiento] DEFAULT (N'EN_PROCESO'),
    [CodigoResultado] NVARCHAR(50) NULL,
    [IdentificadorResultado] NVARCHAR(100) NULL,
    [FechaRegistroUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_RegistroIdempotencia_FechaRegistroUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaFinalizacionUtc] DATETIME2(3) NULL,
    [FechaExpiracionUtc] DATETIME2(3) NOT NULL,
    CONSTRAINT [CP_RegistroIdempotencia] PRIMARY KEY CLUSTERED ([IdRegistroIdempotencia]),
    CONSTRAINT [CU_RegistroIdempotencia_Clave] UNIQUE ([ClaveIdempotencia]),
    CONSTRAINT [CU_RegistroIdempotencia_Correlacion] UNIQUE ([IdCorrelacion]),
    CONSTRAINT [CE_RegistroIdempotencia_Actor] FOREIGN KEY ([IdActorColaborador]) REFERENCES [rrhh].[Colaborador] ([IdColaborador]),
    CONSTRAINT [RV_RegistroIdempotencia_OperacionNoVacia] CHECK (LEN(LTRIM(RTRIM([Operacion]))) > 0),
    CONSTRAINT [RV_RegistroIdempotencia_Estado] CHECK ([EstadoProcesamiento] IN (N'EN_PROCESO', N'COMPLETADO', N'FALLIDO')),
    CONSTRAINT [RV_RegistroIdempotencia_Finalizacion] CHECK
    (
        ([EstadoProcesamiento] = N'EN_PROCESO' AND [FechaFinalizacionUtc] IS NULL)
        OR ([EstadoProcesamiento] IN (N'COMPLETADO', N'FALLIDO') AND [FechaFinalizacionUtc] IS NOT NULL)
    ),
    CONSTRAINT [RV_RegistroIdempotencia_Expiracion] CHECK ([FechaExpiracionUtc] > [FechaRegistroUtc])
);

CREATE INDEX [IN_RegistroIdempotencia_ActorOperacion]
    ON [alimentacion].[RegistroIdempotencia] ([IdActorColaborador], [Operacion], [FechaRegistroUtc]);

CREATE INDEX [IN_RegistroIdempotencia_Expiracion]
    ON [alimentacion].[RegistroIdempotencia] ([FechaExpiracionUtc], [EstadoProcesamiento]);

CREATE TABLE [alimentacion].[EventoAuditoria]
(
    [IdEventoAuditoria] BIGINT IDENTITY(1,1) NOT NULL,
    [IdentificadorEvento] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_EventoAuditoria_IdentificadorEvento] DEFAULT (NEWSEQUENTIALID()),
    [TipoEvento] NVARCHAR(100) NOT NULL,
    [FechaHoraOficialUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_EventoAuditoria_FechaHoraOficialUtc] DEFAULT (SYSUTCDATETIME()),
    [IdActorColaborador] BIGINT NULL,
    [AplicacionOrigen] NVARCHAR(50) NOT NULL,
    [RolContexto] NVARCHAR(50) NULL,
    [TipoObjeto] NVARCHAR(50) NULL,
    [IdentificadorObjeto] NVARCHAR(100) NULL,
    [IdSede] INT NULL,
    [TipoServicio] NVARCHAR(20) NULL,
    [FechaNegocio] DATE NULL,
    [EstadoAnterior] NVARCHAR(50) NULL,
    [EstadoResultante] NVARCHAR(50) NULL,
    [Resultado] NVARCHAR(20) NOT NULL,
    [MotivoSeguro] NVARCHAR(500) NULL,
    [FiltrosMinimizados] NVARCHAR(1000) NULL,
    [IdCorrelacion] UNIQUEIDENTIFIER NOT NULL,
    [HuellaIdempotencia] VARBINARY(64) NULL,
    CONSTRAINT [CP_EventoAuditoria] PRIMARY KEY CLUSTERED ([IdEventoAuditoria]),
    CONSTRAINT [CU_EventoAuditoria_IdentificadorEvento] UNIQUE ([IdentificadorEvento]),
    CONSTRAINT [CE_EventoAuditoria_Actor] FOREIGN KEY ([IdActorColaborador]) REFERENCES [rrhh].[Colaborador] ([IdColaborador]),
    CONSTRAINT [CE_EventoAuditoria_Sede] FOREIGN KEY ([IdSede]) REFERENCES [organizacion].[Sede] ([IdSede]),
    CONSTRAINT [RV_EventoAuditoria_TipoEventoNoVacio] CHECK (LEN(LTRIM(RTRIM([TipoEvento]))) > 0),
    CONSTRAINT [RV_EventoAuditoria_AplicacionNoVacia] CHECK (LEN(LTRIM(RTRIM([AplicacionOrigen]))) > 0),
    CONSTRAINT [RV_EventoAuditoria_TipoServicio] CHECK ([TipoServicio] IS NULL OR [TipoServicio] IN (N'DESAYUNO', N'ALMUERZO', N'CENA')),
    CONSTRAINT [RV_EventoAuditoria_Resultado] CHECK ([Resultado] IN (N'ACEPTADO', N'RECHAZADO'))
);

CREATE INDEX [IN_EventoAuditoria_TipoFecha]
    ON [alimentacion].[EventoAuditoria] ([TipoEvento], [FechaHoraOficialUtc]);

CREATE INDEX [IN_EventoAuditoria_ActorFecha]
    ON [alimentacion].[EventoAuditoria] ([IdActorColaborador], [FechaHoraOficialUtc]);

CREATE INDEX [IN_EventoAuditoria_ObjetoFecha]
    ON [alimentacion].[EventoAuditoria] ([TipoObjeto], [IdentificadorObjeto], [FechaHoraOficialUtc]);

CREATE INDEX [IN_EventoAuditoria_SedeServicioFecha]
    ON [alimentacion].[EventoAuditoria] ([IdSede], [TipoServicio], [FechaHoraOficialUtc]);

CREATE INDEX [IN_EventoAuditoria_Correlacion]
    ON [alimentacion].[EventoAuditoria] ([IdCorrelacion]);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. Elimina únicamente auditoría e idempotencia de Alimentación.
/*
DROP TABLE IF EXISTS [alimentacion].[EventoAuditoria];
DROP TABLE IF EXISTS [alimentacion].[RegistroIdempotencia];
GO
*/
