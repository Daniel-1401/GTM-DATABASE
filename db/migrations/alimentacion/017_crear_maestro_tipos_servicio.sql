-- Migración: 017_crear_maestro_tipos_servicio
-- Entidad(es) afectada(s): alimentacion.TipoServicio, alimentacion.Menu,
--                          alimentacion.VentanaRetiroServicio, alimentacion.Reserva, alimentacion.Entrega
-- Motivo: Centralizar los tipos de servicio disponibles y exponerlos al frontend.

SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [alimentacion].[TipoServicio]
(
    [IdTipoServicio] SMALLINT IDENTITY(1,1) NOT NULL,
    [CodigoTipoServicio] NVARCHAR(20) NOT NULL,
    [NombreTipoServicio] NVARCHAR(100) NOT NULL,
    [OrdenPresentacion] TINYINT NOT NULL,
    [EstaActivo] BIT NOT NULL CONSTRAINT [VP_TipoServicio_EstaActivo] DEFAULT (1),
    [FechaCreacion] DATETIME2(3) NOT NULL CONSTRAINT [VP_TipoServicio_FechaCreacion] DEFAULT (SYSDATETIME()),
    CONSTRAINT [CP_TipoServicio] PRIMARY KEY CLUSTERED ([IdTipoServicio]),
    CONSTRAINT [CU_TipoServicio_Codigo] UNIQUE ([CodigoTipoServicio]),
    CONSTRAINT [CU_TipoServicio_Orden] UNIQUE ([OrdenPresentacion]),
    CONSTRAINT [RV_TipoServicio_CodigoNoVacio] CHECK (LEN(LTRIM(RTRIM([CodigoTipoServicio]))) > 0),
    CONSTRAINT [RV_TipoServicio_NombreNoVacio] CHECK (LEN(LTRIM(RTRIM([NombreTipoServicio]))) > 0)
);

INSERT INTO [alimentacion].[TipoServicio]
    ([CodigoTipoServicio], [NombreTipoServicio], [OrdenPresentacion])
VALUES
    (N'DESAYUNO', N'Desayuno', 1),
    (N'ALMUERZO', N'Almuerzo', 2),
    (N'CENA', N'Cena', 3);

ALTER TABLE [alimentacion].[VentanaRetiroServicio]
    DROP CONSTRAINT [RV_VentanaRetiroServicio_TipoServicio];
ALTER TABLE [alimentacion].[Menu]
    DROP CONSTRAINT [RV_Menu_TipoServicio];
ALTER TABLE [alimentacion].[Reserva]
    DROP CONSTRAINT [RV_Reserva_TipoServicio];
ALTER TABLE [alimentacion].[Entrega]
    DROP CONSTRAINT [RV_Entrega_TipoServicio];

ALTER TABLE [alimentacion].[VentanaRetiroServicio] WITH CHECK
    ADD CONSTRAINT [CE_VentanaRetiroServicio_TipoServicio]
    FOREIGN KEY ([TipoServicio]) REFERENCES [alimentacion].[TipoServicio] ([CodigoTipoServicio]);
ALTER TABLE [alimentacion].[Menu] WITH CHECK
    ADD CONSTRAINT [CE_Menu_TipoServicio]
    FOREIGN KEY ([TipoServicio]) REFERENCES [alimentacion].[TipoServicio] ([CodigoTipoServicio]);
ALTER TABLE [alimentacion].[Reserva] WITH CHECK
    ADD CONSTRAINT [CE_Reserva_TipoServicio]
    FOREIGN KEY ([TipoServicio]) REFERENCES [alimentacion].[TipoServicio] ([CodigoTipoServicio]);
ALTER TABLE [alimentacion].[Entrega] WITH CHECK
    ADD CONSTRAINT [CE_Entrega_TipoServicio]
    FOREIGN KEY ([TipoServicio]) REFERENCES [alimentacion].[TipoServicio] ([CodigoTipoServicio]);

COMMIT TRANSACTION;
GO

-- DOWN
/*
ALTER TABLE [alimentacion].[Entrega] DROP CONSTRAINT [CE_Entrega_TipoServicio];
ALTER TABLE [alimentacion].[Reserva] DROP CONSTRAINT [CE_Reserva_TipoServicio];
ALTER TABLE [alimentacion].[Menu] DROP CONSTRAINT [CE_Menu_TipoServicio];
ALTER TABLE [alimentacion].[VentanaRetiroServicio] DROP CONSTRAINT [CE_VentanaRetiroServicio_TipoServicio];
DROP TABLE [alimentacion].[TipoServicio];
GO
*/
