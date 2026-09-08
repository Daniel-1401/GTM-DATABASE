-- Migracion: 012_crear_validacion_entrega
-- Fecha: 2026-09-04T12:00:00-05:00
-- Entidad(es) afectada(s): alimentacion.ValidacionEntrega
-- Referencia: docs-proyecto/CONTRATO_STORES_BACKEND_ALIMENTACION.md
-- Motivo: Persistir la validacion temporal sin guardar el QR en claro.
-- UP
-- No ejecutar desde este repositorio sin aprobacion DDL y base Local autorizada.
-- El QR nunca se persiste en claro: solo se recibe como hash calculado en memoria.
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [alimentacion].[ValidacionEntrega]
(
    [ValidationId] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [VP_ValidacionEntrega_Id] DEFAULT (NEWSEQUENTIALID()),
    [IdCodigoQR] UNIQUEIDENTIFIER NOT NULL,
    [IdReserva] BIGINT NOT NULL,
    [IdOperadorColaborador] BIGINT NOT NULL,
    [IdSede] INT NOT NULL,
    [MetodoLectura] NVARCHAR(20) NOT NULL,
    [FechaCreacionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_ValidacionEntrega_Creacion] DEFAULT (SYSUTCDATETIME()),
    [FechaVencimientoUtc] DATETIME2(3) NOT NULL,
    [FechaConsumoUtc] DATETIME2(3) NULL,
    [IdCorrelacion] UNIQUEIDENTIFIER NOT NULL,
    [HashCodigo] VARBINARY(64) NOT NULL,
    CONSTRAINT [CP_ValidacionEntrega] PRIMARY KEY CLUSTERED ([ValidationId]),
    CONSTRAINT [CU_ValidacionEntrega_Correlacion] UNIQUE ([IdCorrelacion]),
    CONSTRAINT [CE_ValidacionEntrega_QR] FOREIGN KEY ([IdCodigoQR], [IdReserva]) REFERENCES [alimentacion].[CodigoQR] ([IdCodigoQR], [IdReserva]),
    CONSTRAINT [CE_ValidacionEntrega_Reserva] FOREIGN KEY ([IdReserva]) REFERENCES [alimentacion].[Reserva] ([IdReserva]),
    CONSTRAINT [CE_ValidacionEntrega_Operador] FOREIGN KEY ([IdOperadorColaborador]) REFERENCES [rrhh].[Colaborador] ([IdColaborador]),
    CONSTRAINT [CE_ValidacionEntrega_Sede] FOREIGN KEY ([IdSede]) REFERENCES [organizacion].[Sede] ([IdSede]),
    CONSTRAINT [RV_ValidacionEntrega_Metodo] CHECK ([MetodoLectura] IN (N'CAMARA', N'LECTOR_HID')),
    CONSTRAINT [RV_ValidacionEntrega_Vigencia] CHECK ([FechaVencimientoUtc] > [FechaCreacionUtc] AND [FechaVencimientoUtc] <= DATEADD(MINUTE, 2, [FechaCreacionUtc])),
    CONSTRAINT [RV_ValidacionEntrega_Consumo] CHECK ([FechaConsumoUtc] IS NULL OR [FechaConsumoUtc] >= [FechaCreacionUtc])
);

CREATE INDEX [IN_ValidacionEntrega_ReservaVigencia]
    ON [alimentacion].[ValidacionEntrega] ([IdReserva], [FechaVencimientoUtc], [FechaConsumoUtc]);
CREATE INDEX [IN_ValidacionEntrega_Hash]
    ON [alimentacion].[ValidacionEntrega] ([HashCodigo]);

COMMIT TRANSACTION;
GO

-- DOWN (destructivo; solo sobre la base del proyecto y con aprobacion explicita)
-- DROP TABLE IF EXISTS [alimentacion].[ValidacionEntrega];
