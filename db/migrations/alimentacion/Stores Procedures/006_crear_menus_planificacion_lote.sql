-- Procedimiento: alimentacion.usp_CrearMenusPlanificacionLote
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql,
--             db/migrations/alimentacion/015_crear_tipos_tabla_lote_menus.sql
-- Motivo: Crear varios menús de una planificación BORRADOR, con sus componentes, de forma atómica.
-- Ejecutar después de las migraciones 010 y 015.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_CrearMenusPlanificacionLote]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @IdColaboradorRegistro BIGINT,
    @Menus [alimentacion].[TipoMenuPlanificacionLoteCreacion] READONLY,
    @Componentes [alimentacion].[TipoComponenteMenuLoteCreacion] READONLY,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdPlanificacion IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El identificador de planificación es obligatorio.';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM @Menus)
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'Debe enviar al menos un menú.';
        RETURN;
    END;
    IF @IdColaboradorRegistro IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El colaborador que registra los menús es obligatorio.';
        RETURN;
    END;
    IF EXISTS
    (
        SELECT 1
        FROM @Menus
        WHERE UPPER(LTRIM(RTRIM([TipoServicio]))) NOT IN (N'DESAYUNO', N'ALMUERZO', N'CENA')
           OR ([EstaDisponible] = 1 AND NULLIF(LTRIM(RTRIM([Nombre])), N'') IS NULL)
           OR ([EstaDisponible] = 0 AND
               (NULLIF(LTRIM(RTRIM([Nombre])), N'') IS NOT NULL
                OR NULLIF(LTRIM(RTRIM([Descripcion])), N'') IS NOT NULL
                OR NULLIF(LTRIM(RTRIM([ReferenciaImagen])), N'') IS NOT NULL))
    )
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'Uno o más menús contienen datos no válidos.';
        RETURN;
    END;

    IF EXISTS (SELECT [IdReferencia] FROM @Menus GROUP BY [IdReferencia] HAVING COUNT(*) > 1)
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'No se permiten referencias temporales de menú repetidas.';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT [FechaServicio], UPPER(LTRIM(RTRIM([TipoServicio])))
        FROM @Menus
        GROUP BY [FechaServicio], UPPER(LTRIM(RTRIM([TipoServicio])))
        HAVING COUNT(*) > 1
    )
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'No se permiten menús repetidos para la misma fecha y tipo de servicio.';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM @Componentes AS [Componente]
        LEFT JOIN @Menus AS [Menu]
            ON [Menu].[IdReferencia] = [Componente].[IdReferenciaMenu]
        WHERE [Menu].[IdReferencia] IS NULL
           OR [Componente].[Orden] <= 0
           OR NULLIF(LTRIM(RTRIM([Componente].[DescripcionComponente])), N'') IS NULL
    )
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'Uno o más componentes no son válidos.';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT [IdReferenciaMenu], [Orden]
        FROM @Componentes
        GROUP BY [IdReferenciaMenu], [Orden]
        HAVING COUNT(*) > 1
    )
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'No se permiten órdenes de componente repetidos dentro del mismo menú.';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM @Componentes AS [Componente]
        INNER JOIN @Menus AS [Menu]
            ON [Menu].[IdReferencia] = [Componente].[IdReferenciaMenu]
        WHERE [Menu].[EstaDisponible] = 0
    )
    BEGIN
        SET @Codigo = N'BUSINESS_RULE_VIOLATION';
        SET @Mensaje = N'Un servicio sin atención no puede contener componentes.';
        RETURN;
    END;

    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @FechaInicio DATE;
    DECLARE @FechaFin DATE;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @MenusInsertados TABLE
    (
        [IdReferencia] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [IdMenu] BIGINT NOT NULL
    );

    BEGIN TRY
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
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @Codigo = N'PLAN_NOT_FOUND';
        SET @Mensaje = N'La planificación indicada no existe.';
        RETURN;
    END;

    IF @EstadoPlanificacion <> N'BORRADOR'
    BEGIN
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @Codigo = N'INVALID_PLAN_STATE';
        SET @Mensaje = N'La planificación no permite crear menús.';
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM @Menus WHERE [FechaServicio] NOT BETWEEN @FechaInicio AND @FechaFin)
    BEGIN
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @Codigo = N'BUSINESS_RULE_VIOLATION';
        SET @Mensaje = N'La fecha de cada menú no pertenece al período de la planificación.';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [alimentacion].[Menu] AS [Menu] WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN @Menus AS [Entrada]
            ON [Entrada].[FechaServicio] = [Menu].[FechaServicio]
           AND UPPER(LTRIM(RTRIM([Entrada].[TipoServicio]))) = [Menu].[TipoServicio]
        WHERE [Menu].[IdPlanificacion] = @IdPlanificacionInterno
    )
    BEGIN
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @Codigo = N'MENU_ALREADY_EXISTS';
        SET @Mensaje = N'El lote contiene un menú que ya existe en la planificación.';
        RETURN;
    END;

    INSERT INTO [alimentacion].[Menu]
    (
        [IdPlanificacion], [IdColaboradorRegistro], [FechaServicio], [TipoServicio], [EstaDisponible],
        [Nombre], [Descripcion], [ReferenciaImagen]
    )
    SELECT
        @IdPlanificacionInterno, @IdColaboradorRegistro,
        [Entrada].[FechaServicio],
        UPPER(LTRIM(RTRIM([Entrada].[TipoServicio]))),
        [Entrada].[EstaDisponible],
        NULLIF(LTRIM(RTRIM([Entrada].[Nombre])), N''),
        NULLIF(LTRIM(RTRIM([Entrada].[Descripcion])), N''),
        NULLIF(LTRIM(RTRIM([Entrada].[ReferenciaImagen])), N'')
    FROM @Menus AS [Entrada];

    INSERT INTO @MenusInsertados ([IdReferencia], [IdMenu])
    SELECT
        [Entrada].[IdReferencia],
        [Menu].[IdMenu]
    FROM @Menus AS [Entrada]
    INNER JOIN [alimentacion].[Menu] AS [Menu]
        ON [Menu].[IdPlanificacion] = @IdPlanificacionInterno
       AND [Menu].[FechaServicio] = [Entrada].[FechaServicio]
       AND [Menu].[TipoServicio] = UPPER(LTRIM(RTRIM([Entrada].[TipoServicio])));

    INSERT INTO [alimentacion].[ComponenteMenu] ([IdMenu], [IdColaboradorRegistro], [Orden], [DescripcionComponente])
    SELECT
        [Insertado].[IdMenu], @IdColaboradorRegistro,
        [Componente].[Orden],
        LTRIM(RTRIM([Componente].[DescripcionComponente]))
    FROM @Componentes AS [Componente]
    INNER JOIN @MenusInsertados AS [Insertado]
        ON [Insertado].[IdReferencia] = [Componente].[IdReferenciaMenu];

        COMMIT TRANSACTION;

        SET @Codigo = N'CREATED';
        SET @Mensaje = NULL;

        SELECT
        [Insertado].[IdReferencia] AS [IdReferenciaMenu],
        [Menu].[IdentificadorPublico] AS [IdMenu],
        [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
        [Menu].[FechaServicio], [Menu].[TipoServicio], [Menu].[EstaDisponible], [Menu].[EstaActivo], [Menu].[IdColaboradorRegistro],
        [Menu].[Nombre], [Menu].[Descripcion], [Menu].[ReferenciaImagen],
        [Menu].[VersionRegistro], [Menu].[FechaCreacion]
    FROM @MenusInsertados AS [Insertado]
    INNER JOIN [alimentacion].[Menu] AS [Menu]
        ON [Menu].[IdMenu] = [Insertado].[IdMenu]
    INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
        ON [Planificacion].[IdPlanificacion] = [Menu].[IdPlanificacion]
        ORDER BY [Menu].[FechaServicio], [Menu].[TipoServicio];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_CrearMenusPlanificacionLote',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO
