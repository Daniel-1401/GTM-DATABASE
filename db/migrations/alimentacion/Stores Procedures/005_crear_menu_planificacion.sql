-- Procedimiento: alimentacion.usp_CrearMenuPlanificacion
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Crear un menú, o registrar un servicio sin atención, para una planificación en BORRADOR.
-- Ejecutar después de la migración 010.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_CrearMenuPlanificacion]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @IdColaboradorRegistroCorporativo UNIQUEIDENTIFIER,
    @IdMenuExterno BIGINT,
    @FechaServicio DATE,
    @TipoServicio NVARCHAR(20),
    @EstaDisponible BIT,
    @Nombre NVARCHAR(200) = NULL,
    @Descripcion NVARCHAR(1000) = NULL,
    @ReferenciaImagen NVARCHAR(500) = NULL,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    SET @TipoServicio = UPPER(NULLIF(LTRIM(RTRIM(@TipoServicio)), N''));
    SET @Nombre = NULLIF(LTRIM(RTRIM(@Nombre)), N'');
    SET @Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), N'');
    SET @ReferenciaImagen = NULLIF(LTRIM(RTRIM(@ReferenciaImagen)), N'');

    IF @IdPlanificacion IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El identificador de planificación es obligatorio.';
        RETURN;
    END;
    IF @FechaServicio IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'La fecha de servicio es obligatoria.';
        RETURN;
    END;
    IF @IdColaboradorRegistroCorporativo IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El colaborador que registra el menú es obligatorio.';
        RETURN;
    END;
    IF @IdMenuExterno IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'La referencia externa del menú es obligatoria.';
        RETURN;
    END;
    IF @TipoServicio IS NULL
       OR NOT EXISTS
       (
           SELECT 1
           FROM [alimentacion].[TipoServicio] AS [TipoServicio]
           WHERE [TipoServicio].[CodigoTipoServicio] = @TipoServicio
             AND [TipoServicio].[EstaActivo] = 1
       )
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El tipo de servicio no es válido.';
        RETURN;
    END;
    IF @EstaDisponible IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'Debe indicar si el servicio está disponible.';
        RETURN;
    END;
    IF @EstaDisponible = 1 AND @Nombre IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El nombre es obligatorio cuando el servicio está disponible.';
        RETURN;
    END;
    IF @EstaDisponible = 0 AND (@Nombre IS NOT NULL OR @Descripcion IS NOT NULL OR @ReferenciaImagen IS NOT NULL)
    BEGIN
        SET @Codigo = N'BUSINESS_RULE_VIOLATION';
        SET @Mensaje = N'Un servicio sin atención no puede contener contenido.';
        RETURN;
    END;
    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @FechaInicio DATE;
    DECLARE @FechaFin DATE;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @IdMenuInterno BIGINT;

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
    IF @FechaServicio NOT BETWEEN @FechaInicio AND @FechaFin
    BEGIN
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @Codigo = N'BUSINESS_RULE_VIOLATION';
        SET @Mensaje = N'La fecha de servicio no pertenece al período de la planificación.';
        RETURN;
    END;
    IF EXISTS
    (
        SELECT 1 FROM [alimentacion].[Menu] WITH (UPDLOCK, HOLDLOCK)
        WHERE [IdPlanificacion] = @IdPlanificacionInterno
          AND [FechaServicio] = @FechaServicio AND [TipoServicio] = @TipoServicio
    )
    BEGIN
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @Codigo = N'MENU_ALREADY_EXISTS';
        SET @Mensaje = N'Ya existe un menú para la fecha y tipo de servicio indicados.';
        RETURN;
    END;

    INSERT INTO [alimentacion].[Menu]
    (
        [IdMenuExterno], [IdPlanificacion], [IdColaboradorRegistroCorporativo], [FechaServicio], [TipoServicio], [EstaDisponible],
        [Nombre], [Descripcion], [ReferenciaImagen]
    )
    VALUES
    (
        @IdMenuExterno, @IdPlanificacionInterno, @IdColaboradorRegistroCorporativo, @FechaServicio, @TipoServicio, @EstaDisponible,
        @Nombre, @Descripcion, @ReferenciaImagen
    );

    SET @IdMenuInterno = CONVERT(BIGINT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SET @Codigo = N'CREATED';
        SET @Mensaje = NULL;

        SELECT
            [Menu].[IdentificadorPublico] AS [IdMenu],
            [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
            [Menu].[FechaServicio], [Menu].[TipoServicio], [Menu].[EstaDisponible], [Menu].[EstaActivo], [Menu].[IdColaboradorRegistroCorporativo],
            [Menu].[Nombre], [Menu].[Descripcion], [Menu].[ReferenciaImagen],
            [Menu].[VersionRegistro], [Menu].[FechaCreacion]
        FROM [alimentacion].[Menu] AS [Menu]
        INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Menu].[IdPlanificacion]
        WHERE [Menu].[IdMenu] = @IdMenuInterno;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_CrearMenuPlanificacion',
            @NumeroError = @NumeroErrorCapturado, @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado, @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO

-- EXEC [alimentacion].[usp_CrearMenuPlanificacion]
--     @IdPlanificacion = '00000000-0000-0000-0000-000000000000',
--     @IdColaboradorRegistroCorporativo = '00000000-0000-0000-0000-000000000000',
--     @IdMenuExterno = 1,
--     @FechaServicio = '2026-09-01',
--     @TipoServicio = N'ALMUERZO',
--     @EstaDisponible = 1,
--     @Nombre = N'Pollo al horno',
--     @Descripcion = N'Pollo con arroz y ensalada.';
