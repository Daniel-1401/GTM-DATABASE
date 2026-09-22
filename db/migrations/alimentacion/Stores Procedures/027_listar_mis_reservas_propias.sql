-- Procedimiento: alimentacion.usp_ListarMisReservasPropias
-- Referencias: migraciones 010 y 011 del modulo Alimentacion.
-- Motivo: consultar las reservas activas propias desde la fecha actual.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarMisReservasPropias]
    @IdColaborador BIGINT,
    @NumeroPagina INT,
    @TamanoPagina INT,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdColaborador IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El colaborador es obligatorio.';
        RETURN;
    END;

    IF @NumeroPagina IS NULL OR @TamanoPagina IS NULL
       OR @NumeroPagina < 1
       OR @TamanoPagina < 1
       OR @TamanoPagina > 100
    BEGIN
        SET @Codigo = N'INVALID_FILTER';
        SET @Mensaje = N'La pagina debe ser mayor o igual a 1 y el tamano debe estar entre 1 y 100.';
        RETURN;
    END;

    SELECT @IdColaborador = [Colaborador].[IdColaborador]
    FROM [rrhh].[Colaborador] AS [Colaborador]
    WHERE [Colaborador].[UsuarioId] = @IdColaborador;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [rrhh].[Colaborador] AS [Colaborador]
        WHERE [Colaborador].[IdColaborador] = @IdColaborador
    )
    BEGIN
        SET @Codigo = N'NOT_FOUND';
        SET @Mensaje = N'El colaborador indicado no existe.';
        RETURN;
    END;

    BEGIN TRY
        -- SYSDATETIME() es la convencion vigente del repositorio para la
        -- fecha oficial del servicio.
        DECLARE @FechaOficial DATE = CONVERT(DATE, SYSDATETIME());

        SELECT
            [Reserva].[IdentificadorPublico] AS [IdReserva],
            [Menu].[IdentificadorPublico] AS [IdMenu],
            [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
            [Reserva].[IdSede] AS [IdSede],
            [Sede].[IdentificadorPublico] AS [IdSedePublico],
            [Sede].[NombreSede],
            [Reserva].[FechaServicio],
            [Reserva].[TipoServicio],
            [Planificacion].[Nombre] AS [NombrePlanificacion],
            [Planificacion].[Estado] AS [EstadoPlanificacion],
            [Menu].[Nombre] AS [NombreMenu],
            [Menu].[Descripcion] AS [DescripcionMenu],
            [Menu].[ReferenciaImagen] AS [ReferenciaImagenMenu],
            [Reserva].[Estado] AS [EstadoReserva],
            [Reserva].[FechaCreacion] AS [FechaCreacionReserva],
            [Reserva].[FechaModificacion] AS [FechaModificacionReserva],
            CONVERT(BIT, CASE
                WHEN [Planificacion].[Estado] = N'PUBLICADA_ABIERTA' THEN 1
                ELSE 0
            END) AS [PuedeCancelar]
        FROM [alimentacion].[Reserva] AS [Reserva]
        INNER JOIN [alimentacion].[Menu] AS [Menu]
            ON [Menu].[IdMenu] = [Reserva].[IdMenu]
           AND [Menu].[IdPlanificacion] = [Reserva].[IdPlanificacion]
           AND [Menu].[FechaServicio] = [Reserva].[FechaServicio]
           AND [Menu].[TipoServicio] = [Reserva].[TipoServicio]
        INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
           AND [Planificacion].[IdSede] = [Reserva].[IdSede]
        INNER JOIN [organizacion].[Sede] AS [Sede]
            ON [Sede].[IdSede] = [Reserva].[IdSede]
        WHERE [Reserva].[IdColaborador] = @IdColaborador
          AND [Reserva].[FechaServicio] >= @FechaOficial
          AND [Reserva].[Estado] = N'RESERVADA'
        ORDER BY
            [Reserva].[FechaServicio],
            [Reserva].[IdentificadorPublico]
        OFFSET
            (CONVERT(BIGINT, @NumeroPagina) - 1) * CONVERT(BIGINT, @TamanoPagina)
            ROWS
        FETCH NEXT CONVERT(BIGINT, @TamanoPagina) ROWS ONLY;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ListarMisReservasPropias',
            @NumeroError = @NumeroErrorCapturado,
            @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado,
            @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO
