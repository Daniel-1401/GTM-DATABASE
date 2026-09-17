-- Procedimiento: alimentacion.usp_CrearMenuPlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql,
--             db/migrations/alimentacion/014_crear_tipo_tabla_componentes_menu.sql
-- Motivo: Crear un menú, o registrar un servicio sin atención, para una planificación en BORRADOR.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_CrearMenuPlanificacion]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @IdColaboradorRegistro BIGINT,
    @FechaServicio DATE,
    @TipoServicio NVARCHAR(20),
    @EstaDisponible BIT,
    @Nombre NVARCHAR(200) = NULL,
    @Descripcion NVARCHAR(1000) = NULL,
    @ReferenciaImagen NVARCHAR(500) = NULL,
    @Componentes [alimentacion].[TipoComponenteMenuCreacion] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @TipoServicio = UPPER(NULLIF(LTRIM(RTRIM(@TipoServicio)), N''));
    SET @Nombre = NULLIF(LTRIM(RTRIM(@Nombre)), N'');
    SET @Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), N'');
    SET @ReferenciaImagen = NULLIF(LTRIM(RTRIM(@ReferenciaImagen)), N'');

    IF @IdPlanificacion IS NULL
    BEGIN
        ;THROW 50210, N'El identificador de planificación es obligatorio.', 1;
    END;
    IF @FechaServicio IS NULL
    BEGIN
        ;THROW 50211, N'La fecha de servicio es obligatoria.', 1;
    END;
    IF @IdColaboradorRegistro IS NULL
    BEGIN
        ;THROW 50216, N'El colaborador que registra el menu es obligatorio.', 1;
    END;
    IF @TipoServicio NOT IN (N'DESAYUNO', N'ALMUERZO', N'CENA')
    BEGIN
        ;THROW 50212, N'El tipo de servicio debe ser DESAYUNO, ALMUERZO o CENA.', 1;
    END;
    IF @EstaDisponible IS NULL
    BEGIN
        ;THROW 50213, N'Debe indicar si el servicio está disponible.', 1;
    END;
    IF @EstaDisponible = 1 AND @Nombre IS NULL
    BEGIN
        ;THROW 50214, N'El nombre es obligatorio cuando el servicio está disponible.', 1;
    END;
    IF @EstaDisponible = 0 AND (@Nombre IS NOT NULL OR @Descripcion IS NOT NULL OR @ReferenciaImagen IS NOT NULL)
    BEGIN
        ;THROW 50215, N'Un servicio sin atención no puede contener nombre, descripción ni imagen.', 1;
    END;
    IF EXISTS
    (
        SELECT 1 FROM @Componentes
        WHERE [Orden] <= 0 OR NULLIF(LTRIM(RTRIM([DescripcionComponente])), N'') IS NULL
    )
    BEGIN
        ;THROW 50217, N'Cada componente debe tener orden positivo y descripción de hasta 300 caracteres.', 1;
    END;

    IF EXISTS (SELECT [Orden] FROM @Componentes GROUP BY [Orden] HAVING COUNT(*) > 1)
    BEGIN
        ;THROW 50218, N'No se permiten órdenes de componente repetidos.', 1;
    END;
    IF @EstaDisponible = 0 AND EXISTS (SELECT 1 FROM @Componentes)
    BEGIN
        ;THROW 50219, N'Un servicio sin atención no puede contener componentes.', 1;
    END;

    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @FechaInicio DATE;
    DECLARE @FechaFin DATE;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @IdMenuInterno BIGINT;

    IF NOT EXISTS (SELECT 1 FROM [rrhh].[Colaborador] WHERE [IdColaborador] = @IdColaboradorRegistro)
    BEGIN
        ;THROW 50224, N'El colaborador que registra el menu no existe.', 1;
    END;

    BEGIN TRANSACTION;

    SELECT
        @IdPlanificacionInterno = [IdPlanificacion],
        @FechaInicio = [FechaInicio],
        @FechaFin = [FechaFin],
        @EstadoPlanificacion = [Estado]
    FROM [alimentacion].[Planificacion] WITH (UPDLOCK, HOLDLOCK)
    WHERE [IdentificadorPublico] = @IdPlanificacion;

    IF @IdPlanificacionInterno IS NULL
    BEGIN
        ;THROW 50220, N'La planificación indicada no existe.', 1;
    END;
    IF @EstadoPlanificacion <> N'BORRADOR'
    BEGIN
        ;THROW 50221, N'Solo se pueden crear menús en una planificación en BORRADOR.', 1;
    END;
    IF @FechaServicio NOT BETWEEN @FechaInicio AND @FechaFin
    BEGIN
        ;THROW 50222, N'La fecha de servicio debe pertenecer al período de la planificación.', 1;
    END;
    IF EXISTS
    (
        SELECT 1 FROM [alimentacion].[Menu] WITH (UPDLOCK, HOLDLOCK)
        WHERE [IdPlanificacion] = @IdPlanificacionInterno
          AND [FechaServicio] = @FechaServicio AND [TipoServicio] = @TipoServicio
    )
    BEGIN
        ;THROW 50223, N'Ya existe un menú para la fecha y tipo de servicio indicados.', 1;
    END;

    INSERT INTO [alimentacion].[Menu]
    (
        [IdPlanificacion], [IdColaboradorRegistro], [FechaServicio], [TipoServicio], [EstaDisponible],
        [Nombre], [Descripcion], [ReferenciaImagen]
    )
    VALUES
    (
        @IdPlanificacionInterno, @IdColaboradorRegistro, @FechaServicio, @TipoServicio, @EstaDisponible,
        @Nombre, @Descripcion, @ReferenciaImagen
    );

    SET @IdMenuInterno = CONVERT(BIGINT, SCOPE_IDENTITY());

    INSERT INTO [alimentacion].[ComponenteMenu] ([IdMenu], [IdColaboradorRegistro], [Orden], [DescripcionComponente])
    SELECT @IdMenuInterno, @IdColaboradorRegistro, [Orden], LTRIM(RTRIM([DescripcionComponente]))
    FROM @Componentes;

    COMMIT TRANSACTION;

    SELECT
        [Menu].[IdentificadorPublico] AS [IdMenu],
        [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
        [Menu].[FechaServicio], [Menu].[TipoServicio], [Menu].[EstaDisponible], [Menu].[EstaActivo], [Menu].[IdColaboradorRegistro],
        [Menu].[Nombre], [Menu].[Descripcion], [Menu].[ReferenciaImagen],
        [Menu].[VersionRegistro], [Menu].[FechaCreacionUtc]
    FROM [alimentacion].[Menu] AS [Menu]
    INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
        ON [Planificacion].[IdPlanificacion] = [Menu].[IdPlanificacion]
    WHERE [Menu].[IdMenu] = @IdMenuInterno;
END;
GO

-- DECLARE @Componentes [alimentacion].[TipoComponenteMenuCreacion];
-- INSERT INTO @Componentes ([Orden], [DescripcionComponente])
-- VALUES (1, N'Pollo'), (2, N'Arroz');
--
-- EXEC [alimentacion].[usp_CrearMenuPlanificacion]
--     @IdPlanificacion = '00000000-0000-0000-0000-000000000000', @IdColaboradorRegistro = 1,
--     @FechaServicio = '2026-09-01', @TipoServicio = N'ALMUERZO',
--     @EstaDisponible = 1, @Nombre = N'Pollo al horno',
--     @Descripcion = N'Pollo con arroz y ensalada.', @Componentes = @Componentes;
