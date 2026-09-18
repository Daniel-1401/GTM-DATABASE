-- Procedimiento: alimentacion.usp_CrearMenusPlanificacionLote
-- Referencia: db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql
-- Motivo: Configurar un mismo menú para un rango de días de una planificación
--         BORRADOR, sin modificar los días que ya poseen menú.
-- Ejecutar después de la migración 017.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_CrearMenusPlanificacionLote]
    @IdPlanificacion UNIQUEIDENTIFIER,
    @IdColaboradorRegistro BIGINT,
    @FechaInicio DATE,
    @FechaFin DATE,
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
    IF @IdColaboradorRegistro IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El colaborador que registra los menús es obligatorio.';
        RETURN;
    END;
    IF @FechaInicio IS NULL OR @FechaFin IS NULL OR @FechaFin < @FechaInicio
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El rango de fechas no es válido.';
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
    DECLARE @FechaInicioPlanificacion DATE;
    DECLARE @FechaFinPlanificacion DATE;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @CantidadCreados INT;
    DECLARE @CantidadOmitidos INT;
    DECLARE @FechasSolicitadas TABLE ([FechaServicio] DATE NOT NULL PRIMARY KEY);
    DECLARE @MenusCreados TABLE
    (
        [IdMenu] BIGINT NOT NULL PRIMARY KEY,
        [FechaServicio] DATE NOT NULL UNIQUE
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @IdPlanificacionInterno = [Planificacion].[IdPlanificacion],
            @FechaInicioPlanificacion = [Planificacion].[FechaInicio],
            @FechaFinPlanificacion = [Planificacion].[FechaFin],
            @EstadoPlanificacion = [Planificacion].[Estado]
        FROM [alimentacion].[Planificacion] AS [Planificacion] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Planificacion].[IdentificadorPublico] = @IdPlanificacion;

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
        IF @FechaInicio < @FechaInicioPlanificacion OR @FechaFin > @FechaFinPlanificacion
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'BUSINESS_RULE_VIOLATION';
            SET @Mensaje = N'El rango de fechas no pertenece al período de la planificación.';
            RETURN;
        END;

        ;WITH [Fechas] AS
        (
            SELECT @FechaInicio AS [FechaServicio]
            UNION ALL
            SELECT DATEADD(DAY, 1, [Fechas].[FechaServicio])
            FROM [Fechas]
            WHERE [Fechas].[FechaServicio] < @FechaFin
        )
        INSERT INTO @FechasSolicitadas ([FechaServicio])
        SELECT [Fechas].[FechaServicio]
        FROM [Fechas]
        OPTION (MAXRECURSION 0);

        INSERT INTO [alimentacion].[Menu]
        (
            [IdPlanificacion], [IdColaboradorRegistro], [FechaServicio], [TipoServicio], [EstaDisponible],
            [Nombre], [Descripcion], [ReferenciaImagen]
        )
        OUTPUT inserted.[IdMenu], inserted.[FechaServicio]
            INTO @MenusCreados ([IdMenu], [FechaServicio])
        SELECT
            @IdPlanificacionInterno, @IdColaboradorRegistro, [Fecha].[FechaServicio], @TipoServicio,
            @EstaDisponible, @Nombre, @Descripcion, @ReferenciaImagen
        FROM @FechasSolicitadas AS [Fecha]
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM [alimentacion].[Menu] AS [Menu] WITH (UPDLOCK, HOLDLOCK)
            WHERE [Menu].[IdPlanificacion] = @IdPlanificacionInterno
              AND [Menu].[FechaServicio] = [Fecha].[FechaServicio]
              AND [Menu].[TipoServicio] = @TipoServicio
        );

        SET @CantidadCreados = @@ROWCOUNT;
        SET @CantidadOmitidos = (SELECT COUNT(*) FROM @FechasSolicitadas) - @CantidadCreados;

        COMMIT TRANSACTION;

        SET @Codigo = N'CREATED';
        SET @Mensaje = CONCAT(
            N'Se crearon ', @CantidadCreados, N' menú(s) y se omitieron ', @CantidadOmitidos,
            N' fecha(s) que ya tenían un menú configurado.');

        SELECT
            [Fecha].[FechaServicio],
            @TipoServicio AS [TipoServicio],
            CONVERT(BIT, CASE WHEN [Creado].[IdMenu] IS NULL THEN 0 ELSE 1 END) AS [FueCreado],
            CASE WHEN [Creado].[IdMenu] IS NULL THEN N'OMITIDO_EXISTENTE' ELSE N'CREADO' END AS [Resultado],
            [Menu].[IdentificadorPublico] AS [IdMenu],
            [Menu].[EstaDisponible],
            [Menu].[Nombre], [Menu].[Descripcion], [Menu].[ReferenciaImagen],
            [Menu].[VersionRegistro], [Menu].[FechaCreacion]
        FROM @FechasSolicitadas AS [Fecha]
        INNER JOIN [alimentacion].[Menu] AS [Menu]
            ON [Menu].[IdPlanificacion] = @IdPlanificacionInterno
           AND [Menu].[FechaServicio] = [Fecha].[FechaServicio]
           AND [Menu].[TipoServicio] = @TipoServicio
        LEFT JOIN @MenusCreados AS [Creado]
            ON [Creado].[IdMenu] = [Menu].[IdMenu]
        ORDER BY [Fecha].[FechaServicio];
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
