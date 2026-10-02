-- Procedimiento: alimentacion.usp_ObtenerResumenServicioHoyColaborador
-- Referencias: migraciones nucleo 003/004 y alimentacion 010/011.
-- Motivo: entregar el resumen de la reserva propia del colaborador para la
-- pantalla inicial movil, siempre con una fila determinista.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ObtenerResumenServicioHoyColaborador]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    /**
      DECLARE @IdColaboradorCorporativo UNIQUEIDENTIFIER = '4D43C4D1-834A-4FC0-811C-7B4A7FF2FF77',
              @Codigo NVARCHAR(50) ,
              @Mensaje NVARCHAR(500) ;
      EXEC [alimentacion].[usp_ObtenerResumenServicioHoyColaborador] @IdColaboradorCorporativo, @Codigo OUTPUT, @Mensaje OUTPUT;
      SELECT @Codigo, @Mensaje


     */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdColaboradorCorporativo IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El colaborador es obligatorio.';
        RETURN;
    END;

    BEGIN TRY
        -- No existe una conversion SQL aprobada de la zona IANA America/Lima;
        -- SYSDATETIME() es la convencion vigente del repositorio.
        DECLARE @FechaOficial DATE = CONVERT(DATE, SYSDATETIME());

        ;WITH [ReservaHoy] AS
        (
            SELECT
                [Reserva].[IdReserva] AS [IdReservaInterno],
                [Reserva].[IdentificadorPublico] AS [IdReserva],
                [Reserva].[IdPlanificacion] AS [IdPlanificacionInterno],
                [Reserva].[IdMenu] AS [IdMenuInterno],
                [Reserva].[IdSede] AS [IdSedeInterno],
                [Reserva].[FechaServicio],
                [Reserva].[TipoServicio],
                [Reserva].[Estado] AS [EstadoReserva],
                [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
                [Planificacion].[Estado] AS [EstadoPlanificacion],
                [Menu].[IdentificadorPublico] AS [IdMenu],
                [Menu].[EstaDisponible],
                [Menu].[Nombre] AS [NombreMenu],
                [Menu].[Descripcion] AS [DescripcionMenu],
                [Menu].[ReferenciaImagen],
                [Sede].[IdSedePublico] AS [IdSedePublico],
                [Sede].[NombreSede]
            FROM [alimentacion].[Reserva] AS [Reserva]
            INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
                ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
            LEFT JOIN [alimentacion].[Menu] AS [Menu]
                ON [Menu].[IdMenu] = [Reserva].[IdMenu]
               AND [Menu].[IdPlanificacion] = [Reserva].[IdPlanificacion]
               AND [Menu].[FechaServicio] = [Reserva].[FechaServicio]
               AND [Menu].[TipoServicio] = [Reserva].[TipoServicio]
            LEFT JOIN [PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA].[organizacion].[Sede] AS [Sede]
                ON [Sede].[IdSede] = [Reserva].[IdSede]
            WHERE [Reserva].[IdColaboradorCorporativo] = @IdColaboradorCorporativo
              AND [Reserva].[FechaServicio] = @FechaOficial
              AND [Reserva].[Estado] = N'RESERVADA'
              AND [Planificacion].[Estado] = N'CONSOLIDADA'
        )
        SELECT
            @FechaOficial AS [FechaOficial],
            [ReservaHoy].[IdReserva],
            [ReservaHoy].[IdPlanificacion],
            [ReservaHoy].[IdMenu],
            [ReservaHoy].[IdSedeInterno] AS [IdSede],
            [ReservaHoy].[IdSedePublico],
            [ReservaHoy].[NombreSede],
            [ReservaHoy].[FechaServicio],
            [ReservaHoy].[TipoServicio],
            [ReservaHoy].[EstadoReserva],
            [ReservaHoy].[EstadoPlanificacion],
            [ReservaHoy].[EstaDisponible],
            [ReservaHoy].[NombreMenu],
            [ReservaHoy].[DescripcionMenu],
            [ReservaHoy].[ReferenciaImagen],
            CONVERT(BIT, CASE WHEN [ReservaHoy].[IdReservaInterno] IS NULL THEN 0 ELSE 1 END) AS [TieneReservaHoy],
            CONVERT(BIT, CASE
                WHEN [ReservaHoy].[IdReservaInterno] IS NOT NULL
                 AND [ReservaHoy].[EstadoPlanificacion] = N'PUBLICADA_ABIERTA'
                THEN 1 ELSE 0 END) AS [PuedeCancelar],
            CONVERT(BIT, CASE
                WHEN [ReservaHoy].[IdReservaInterno] IS NOT NULL
                 AND [ReservaHoy].[EstadoPlanificacion] = N'CONSOLIDADA'
                THEN 1 ELSE 0 END) AS [PuedeGenerarQR],
            CONVERT(BIT, CASE
                WHEN [ReservaHoy].[IdReservaInterno] IS NOT NULL
                 AND [ReservaHoy].[EstadoPlanificacion] = N'CONSOLIDADA'
                THEN 1 ELSE 0 END) AS [PuedeRecoger]
        FROM (VALUES (1)) AS [FilaUnica] ([Valor])
        LEFT JOIN [ReservaHoy]
            ON 1 = 1
        ORDER BY [ReservaHoy].[IdReservaInterno];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ObtenerResumenServicioHoyColaborador',
            @NumeroError = @NumeroErrorCapturado,
            @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado,
            @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO
