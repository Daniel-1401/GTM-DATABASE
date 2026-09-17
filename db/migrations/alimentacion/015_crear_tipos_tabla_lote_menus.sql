-- Migración: 015_crear_tipos_tabla_lote_menus
-- Fecha: 2026-09-16T12:00:00-05:00
-- Entidad(es) afectada(s): alimentacion.TipoMenuPlanificacionLoteCreacion,
--                       alimentacion.TipoComponenteMenuLoteCreacion
-- Motivo: Definir los TVP para crear varios menús y sus componentes en una sola operación.

IF TYPE_ID(N'alimentacion.TipoMenuPlanificacionLoteCreacion') IS NULL
BEGIN
    EXEC(N'
        CREATE TYPE [alimentacion].[TipoMenuPlanificacionLoteCreacion] AS TABLE
        (
            [IdReferencia] UNIQUEIDENTIFIER NOT NULL,
            [FechaServicio] DATE NOT NULL,
            [TipoServicio] NVARCHAR(20) NOT NULL,
            [EstaDisponible] BIT NOT NULL,
            [Nombre] NVARCHAR(200) NULL,
            [Descripcion] NVARCHAR(1000) NULL,
            [ReferenciaImagen] NVARCHAR(500) NULL
        );
    ');
END;
GO

IF TYPE_ID(N'alimentacion.TipoComponenteMenuLoteCreacion') IS NULL
BEGIN
    EXEC(N'
        CREATE TYPE [alimentacion].[TipoComponenteMenuLoteCreacion] AS TABLE
        (
            [IdReferenciaMenu] UNIQUEIDENTIFIER NOT NULL,
            [Orden] SMALLINT NOT NULL,
            [DescripcionComponente] NVARCHAR(300) NOT NULL
        );
    ');
END;
GO

-- DOWN
/*
DROP TYPE [alimentacion].[TipoComponenteMenuLoteCreacion];
DROP TYPE [alimentacion].[TipoMenuPlanificacionLoteCreacion];
GO
*/
