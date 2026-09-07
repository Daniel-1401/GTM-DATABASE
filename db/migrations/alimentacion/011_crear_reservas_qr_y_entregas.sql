-- Migración: 011_crear_reservas_qr_y_entregas
-- Fecha: 2026-09-04T12:00:00-05:00
-- Entidad(es) afectada(s): alimentacion.Reserva, alimentacion.CodigoQR, alimentacion.Entrega
-- Referencia: Lineamientos/Alimentacion/funcionalidades/02_RESERVAS.md, 03_QR_Y_BLE.md y 04_ENTREGA_PRESENCIAL.md / STACK.md
-- Motivo: Persistir reservas individuales, QR opacos de un uso y entregas presenciales normales sin excepciones.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [alimentacion].[Reserva]
(
    [IdReserva] BIGINT IDENTITY(1,1) NOT NULL,
    [IdentificadorPublico] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_Reserva_IdentificadorPublico] DEFAULT (NEWSEQUENTIALID()),
    [IdColaborador] BIGINT NOT NULL,
    [IdPlanificacion] BIGINT NOT NULL,
    [IdMenu] BIGINT NOT NULL,
    [IdSede] INT NOT NULL,
    [FechaServicio] DATE NOT NULL,
    [TipoServicio] NVARCHAR(20) NOT NULL,
    [Estado] NVARCHAR(20) NOT NULL CONSTRAINT [VP_Reserva_Estado] DEFAULT (N'RESERVADA'),
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_Reserva_FechaCreacionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaModificacionUtc] DATETIME2(3) NULL,
    CONSTRAINT [CP_Reserva] PRIMARY KEY CLUSTERED ([IdReserva]),
    CONSTRAINT [CU_Reserva_IdentificadorPublico] UNIQUE ([IdentificadorPublico]),
    CONSTRAINT [CU_Reserva_Contexto] UNIQUE ([IdReserva], [IdPlanificacion], [IdSede], [FechaServicio], [TipoServicio]),
    CONSTRAINT [CE_Reserva_Colaborador] FOREIGN KEY ([IdColaborador]) REFERENCES [rrhh].[Colaborador] ([IdColaborador]),
    CONSTRAINT [CE_Reserva_PlanificacionSede] FOREIGN KEY ([IdPlanificacion], [IdSede]) REFERENCES [alimentacion].[Planificacion] ([IdPlanificacion], [IdSede]),
    CONSTRAINT [CE_Reserva_Menu] FOREIGN KEY ([IdMenu], [IdPlanificacion], [FechaServicio], [TipoServicio]) REFERENCES [alimentacion].[Menu] ([IdMenu], [IdPlanificacion], [FechaServicio], [TipoServicio]),
    CONSTRAINT [RV_Reserva_TipoServicio] CHECK ([TipoServicio] IN (N'DESAYUNO', N'ALMUERZO', N'CENA')),
    CONSTRAINT [RV_Reserva_Estado] CHECK ([Estado] IN (N'RESERVADA', N'CANCELADA', N'ENTREGADA', N'NO_RECOGIDA'))
);

CREATE UNIQUE INDEX [IN_Reserva_ActivaColaboradorFecha]
    ON [alimentacion].[Reserva] ([IdColaborador], [FechaServicio])
    WHERE [Estado] = N'RESERVADA';

CREATE INDEX [IN_Reserva_PlanificacionMenuEstado]
    ON [alimentacion].[Reserva] ([IdPlanificacion], [IdMenu], [Estado])
    INCLUDE ([IdColaborador], [IdSede], [FechaServicio], [TipoServicio]);

CREATE INDEX [IN_Reserva_ColaboradorHistorial]
    ON [alimentacion].[Reserva] ([IdColaborador], [FechaServicio], [Estado])
    INCLUDE ([IdSede], [TipoServicio], [IdMenu]);

CREATE TABLE [alimentacion].[CodigoQR]
(
    [IdCodigoQR] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_CodigoQR_IdCodigoQR] DEFAULT (NEWSEQUENTIALID()),
    [IdReserva] BIGINT NOT NULL,
    [HashCodigo] VARBINARY(64) NOT NULL,
    [Estado] NVARCHAR(20) NOT NULL CONSTRAINT [VP_CodigoQR_Estado] DEFAULT (N'VIGENTE'),
    [FechaEmisionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_CodigoQR_FechaEmisionUtc] DEFAULT (SYSUTCDATETIME()),
    [FechaVencimientoUtc] DATETIME2(3) NOT NULL,
    [FechaUsoUtc] DATETIME2(3) NULL,
    [FechaRevocacionUtc] DATETIME2(3) NULL,
    [MotivoRevocacion] NVARCHAR(100) NULL,
    [IdCorrelacion] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [CP_CodigoQR] PRIMARY KEY CLUSTERED ([IdCodigoQR]),
    CONSTRAINT [CU_CodigoQR_HashCodigo] UNIQUE ([HashCodigo]),
    CONSTRAINT [CU_CodigoQR_IdReserva] UNIQUE ([IdCodigoQR], [IdReserva]),
    CONSTRAINT [CE_CodigoQR_Reserva] FOREIGN KEY ([IdReserva]) REFERENCES [alimentacion].[Reserva] ([IdReserva]),
    CONSTRAINT [RV_CodigoQR_Estado] CHECK ([Estado] IN (N'VIGENTE', N'VENCIDO', N'UTILIZADO', N'REVOCADO')),
    CONSTRAINT [RV_CodigoQR_Vigencia] CHECK ([FechaVencimientoUtc] > [FechaEmisionUtc] AND [FechaVencimientoUtc] <= DATEADD(MINUTE, 5, [FechaEmisionUtc])),
    CONSTRAINT [RV_CodigoQR_Transicion] CHECK
    (
        ([Estado] = N'VIGENTE' AND [FechaUsoUtc] IS NULL AND [FechaRevocacionUtc] IS NULL)
        OR ([Estado] = N'VENCIDO' AND [FechaUsoUtc] IS NULL AND [FechaRevocacionUtc] IS NULL)
        OR ([Estado] = N'UTILIZADO' AND [FechaUsoUtc] IS NOT NULL AND [FechaRevocacionUtc] IS NULL)
        OR ([Estado] = N'REVOCADO' AND [FechaUsoUtc] IS NULL AND [FechaRevocacionUtc] IS NOT NULL)
    ),
    CONSTRAINT [RV_CodigoQR_MotivoRevocacion] CHECK
    (
        ([Estado] = N'REVOCADO' AND NULLIF(LTRIM(RTRIM([MotivoRevocacion])), N'') IS NOT NULL)
        OR ([Estado] <> N'REVOCADO' AND [MotivoRevocacion] IS NULL)
    )
);

CREATE UNIQUE INDEX [IN_CodigoQR_VigentePorReserva]
    ON [alimentacion].[CodigoQR] ([IdReserva])
    WHERE [Estado] = N'VIGENTE';

CREATE INDEX [IN_CodigoQR_ReservaEstadoVencimiento]
    ON [alimentacion].[CodigoQR] ([IdReserva], [Estado], [FechaVencimientoUtc]);

CREATE TABLE [alimentacion].[Entrega]
(
    [IdEntrega] BIGINT IDENTITY(1,1) NOT NULL,
    [IdentificadorPublico] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_Entrega_IdentificadorPublico] DEFAULT (NEWSEQUENTIALID()),
    [IdReserva] BIGINT NOT NULL,
    [IdCodigoQR] UNIQUEIDENTIFIER NOT NULL,
    [IdOperadorColaborador] BIGINT NOT NULL,
    [IdPlanificacion] BIGINT NOT NULL,
    [IdSede] INT NOT NULL,
    [FechaServicio] DATE NOT NULL,
    [TipoServicio] NVARCHAR(20) NOT NULL,
    [MecanismoLectura] NVARCHAR(20) NOT NULL,
    [FechaEntregaUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_Entrega_FechaEntregaUtc] DEFAULT (SYSUTCDATETIME()),
    [IdCorrelacion] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [CP_Entrega] PRIMARY KEY CLUSTERED ([IdEntrega]),
    CONSTRAINT [CU_Entrega_IdentificadorPublico] UNIQUE ([IdentificadorPublico]),
    CONSTRAINT [CU_Entrega_Reserva] UNIQUE ([IdReserva]),
    CONSTRAINT [CU_Entrega_CodigoQR] UNIQUE ([IdCodigoQR]),
    CONSTRAINT [CU_Entrega_Correlacion] UNIQUE ([IdCorrelacion]),
    CONSTRAINT [CE_Entrega_ReservaContexto] FOREIGN KEY ([IdReserva], [IdPlanificacion], [IdSede], [FechaServicio], [TipoServicio]) REFERENCES [alimentacion].[Reserva] ([IdReserva], [IdPlanificacion], [IdSede], [FechaServicio], [TipoServicio]),
    CONSTRAINT [CE_Entrega_CodigoQRReserva] FOREIGN KEY ([IdCodigoQR], [IdReserva]) REFERENCES [alimentacion].[CodigoQR] ([IdCodigoQR], [IdReserva]),
    CONSTRAINT [CE_Entrega_Operador] FOREIGN KEY ([IdOperadorColaborador]) REFERENCES [rrhh].[Colaborador] ([IdColaborador]),
    CONSTRAINT [RV_Entrega_TipoServicio] CHECK ([TipoServicio] IN (N'DESAYUNO', N'ALMUERZO', N'CENA')),
    CONSTRAINT [RV_Entrega_MecanismoLectura] CHECK ([MecanismoLectura] IN (N'CAMARA', N'LECTOR_HID'))
);

CREATE INDEX [IN_Entrega_SedeFechaServicio]
    ON [alimentacion].[Entrega] ([IdSede], [FechaServicio], [TipoServicio])
    INCLUDE ([IdReserva], [FechaEntregaUtc]);

CREATE INDEX [IN_Entrega_OperadorFecha]
    ON [alimentacion].[Entrega] ([IdOperadorColaborador], [FechaEntregaUtc]);

COMMIT TRANSACTION;
GO

-- DOWN
-- Reversión destructiva declarada. Elimina solo entregas, QR y reservas del módulo.
/*
DROP TABLE IF EXISTS [alimentacion].[Entrega];
DROP TABLE IF EXISTS [alimentacion].[CodigoQR];
DROP TABLE IF EXISTS [alimentacion].[Reserva];
GO
*/
