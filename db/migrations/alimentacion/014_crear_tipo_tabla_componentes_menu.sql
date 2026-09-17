-- Migración: 014_crear_tipo_tabla_componentes_menu
-- Fecha: 2026-09-16T12:00:00-05:00
-- Entidad(es) afectada(s): alimentacion.TipoComponenteMenuCreacion
-- Motivo: Definir el TVP usado al crear un menú con sus componentes informativos.

IF TYPE_ID(N'alimentacion.TipoComponenteMenuCreacion') IS NULL
BEGIN
    EXEC(N'
        CREATE TYPE [alimentacion].[TipoComponenteMenuCreacion] AS TABLE
        (
            [Orden] SMALLINT NOT NULL,
            [DescripcionComponente] NVARCHAR(300) NOT NULL
        );
    ');
END;
GO

-- DOWN
/*
DROP TYPE [alimentacion].[TipoComponenteMenuCreacion];
GO
*/
