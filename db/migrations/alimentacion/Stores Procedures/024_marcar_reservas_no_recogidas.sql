-- Procedimiento interno: alimentacion.usp_MarcarReservasNoRecogidas
-- Motivo: marcar masivamente reservas RESERVADA cuyo servicio consolidado ya
-- termino y que no tienen una Entrega, para incluirlas en el historial.
-- Este procedimiento es invocado unicamente por un backend/job autorizado.
-- No es una operacion del movil.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_MarcarReservasNoRecogidas]
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;
    DECLARE @InstanteOficial DATETIME2(3) = SYSDATETIME();
    DECLARE @FechaOficial DATE = CONVERT(DATE, @InstanteOficial);
    DECLARE @HoraOficial TIME(0) = CONVERT(TIME(0), @InstanteOficial);
    DECLARE @CantidadMarcada INT = 0;
    DECLARE @CantidadOmitidaSinVentana INT = 0;
    DECLARE @CantidadOmitidaVentanaAmbigua INT = 0;

    DECLARE @Candidatas TABLE
    (
        [IdReserva] BIGINT NOT NULL PRIMARY KEY
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        -- UPDLOCK/HOLDLOCK sobre Reserva y Entrega serializa esta decision con
        -- una entrega concurrente. La reserva se vuelve a filtrar por
        -- RESERVADA en el UPDATE para conservar idempotencia.
        ;WITH [ReservasElegibles] AS
        (
            SELECT
                [Reserva].[IdReserva],
                [Reserva].[FechaServicio],
                [Reserva].[IdSede],
                [Reserva].[TipoServicio],
                [Ventanas].[CantidadVentanas],
                [Ventanas].[CantidadVentanasNocturnas],
                [Ventanas].[HoraFinUnica]
            FROM [alimentacion].[Reserva] AS [Reserva] WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
                ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
               AND [Planificacion].[Estado] = N'CONSOLIDADA'
            OUTER APPLY
            (
                SELECT
                    COUNT_BIG(1) AS [CantidadVentanas],
                    SUM(CASE WHEN [Ventana].[HoraInicio] > [Ventana].[HoraFin] THEN 1 ELSE 0 END)
                        AS [CantidadVentanasNocturnas],
                    MAX(CASE WHEN [Ventana].[HoraInicio] <= [Ventana].[HoraFin]
                             THEN [Ventana].[HoraFin] END) AS [HoraFinUnica]
                FROM [alimentacion].[VentanaRetiroServicio] AS [Ventana] WITH (HOLDLOCK)
                WHERE [Ventana].[IdSede] = [Reserva].[IdSede]
                  AND [Ventana].[TipoServicio] = [Reserva].[TipoServicio]
                  AND [Reserva].[FechaServicio] >= [Ventana].[FechaInicioVigencia]
                  AND ([Ventana].[FechaFinVigencia] IS NULL
                       OR [Reserva].[FechaServicio] <= [Ventana].[FechaFinVigencia])
            ) AS [Ventanas]
            WHERE [Reserva].[Estado] = N'RESERVADA'
              AND NOT EXISTS
              (
                  SELECT 1
                  FROM [alimentacion].[Entrega] AS [Entrega] WITH (UPDLOCK, HOLDLOCK)
                  WHERE [Entrega].[IdReserva] = [Reserva].[IdReserva]
              )
        )
        INSERT INTO @Candidatas ([IdReserva])
        SELECT [Elegibles].[IdReserva]
        FROM [ReservasElegibles] AS [Elegibles]
        WHERE
            (
                [Elegibles].[FechaServicio] < @FechaOficial
                OR
                (
                    [Elegibles].[FechaServicio] = @FechaOficial
                    AND [Elegibles].[CantidadVentanas] = 1
                    AND [Elegibles].[CantidadVentanasNocturnas] = 0
                    AND @HoraOficial >= [Elegibles].[HoraFinUnica]
                )
            );

        SELECT
            @CantidadOmitidaSinVentana = COUNT(1)
        FROM [alimentacion].[Reserva] AS [Reserva] WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
           AND [Planificacion].[Estado] = N'CONSOLIDADA'
        OUTER APPLY
        (
            SELECT COUNT_BIG(1) AS [CantidadVentanas]
            FROM [alimentacion].[VentanaRetiroServicio] AS [Ventana] WITH (HOLDLOCK)
            WHERE [Ventana].[IdSede] = [Reserva].[IdSede]
              AND [Ventana].[TipoServicio] = [Reserva].[TipoServicio]
              AND @FechaOficial >= [Ventana].[FechaInicioVigencia]
              AND ([Ventana].[FechaFinVigencia] IS NULL
                   OR @FechaOficial <= [Ventana].[FechaFinVigencia])
        ) AS [Ventanas]
        WHERE [Reserva].[FechaServicio] = @FechaOficial
          AND [Reserva].[Estado] = N'RESERVADA'
          AND [Ventanas].[CantidadVentanas] = 0
          AND NOT EXISTS
          (
              SELECT 1
              FROM [alimentacion].[Entrega] AS [Entrega] WITH (UPDLOCK, HOLDLOCK)
              WHERE [Entrega].[IdReserva] = [Reserva].[IdReserva]
          );

        SELECT
            @CantidadOmitidaVentanaAmbigua = COUNT(1)
        FROM [alimentacion].[Reserva] AS [Reserva] WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
           AND [Planificacion].[Estado] = N'CONSOLIDADA'
        OUTER APPLY
        (
            SELECT
                COUNT_BIG(1) AS [CantidadVentanas],
                SUM(CASE WHEN [Ventana].[HoraInicio] > [Ventana].[HoraFin] THEN 1 ELSE 0 END)
                    AS [CantidadVentanasNocturnas]
            FROM [alimentacion].[VentanaRetiroServicio] AS [Ventana] WITH (HOLDLOCK)
            WHERE [Ventana].[IdSede] = [Reserva].[IdSede]
              AND [Ventana].[TipoServicio] = [Reserva].[TipoServicio]
              AND @FechaOficial >= [Ventana].[FechaInicioVigencia]
              AND ([Ventana].[FechaFinVigencia] IS NULL
                   OR @FechaOficial <= [Ventana].[FechaFinVigencia])
        ) AS [Ventanas]
        WHERE [Reserva].[FechaServicio] = @FechaOficial
          AND [Reserva].[Estado] = N'RESERVADA'
          AND
          (
              [Ventanas].[CantidadVentanas] > 1
              OR ([Ventanas].[CantidadVentanas] = 1 AND [Ventanas].[CantidadVentanasNocturnas] = 1)
          )
          AND NOT EXISTS
          (
              SELECT 1
              FROM [alimentacion].[Entrega] AS [Entrega] WITH (UPDLOCK, HOLDLOCK)
              WHERE [Entrega].[IdReserva] = [Reserva].[IdReserva]
          );

        UPDATE [Reserva]
        SET
            [Reserva].[Estado] = N'NO_RECOGIDA',
            [Reserva].[FechaModificacion] = @InstanteOficial
        FROM [alimentacion].[Reserva] AS [Reserva]
        INNER JOIN @Candidatas AS [Candidata]
            ON [Candidata].[IdReserva] = [Reserva].[IdReserva]
        WHERE [Reserva].[Estado] = N'RESERVADA'
          AND NOT EXISTS
          (
              SELECT 1
              FROM [alimentacion].[Entrega] AS [Entrega] WITH (UPDLOCK, HOLDLOCK)
              WHERE [Entrega].[IdReserva] = [Reserva].[IdReserva]
          );

        SET @CantidadMarcada = @@ROWCOUNT;
        COMMIT TRANSACTION;

        IF @CantidadMarcada > 0
            SET @Codigo = N'UPDATED';
        ELSE
            SET @Codigo = N'OK';

        SELECT
            @FechaOficial AS [FechaOficial],
            @CantidadMarcada AS [CantidadMarcadaNoRecogida],
            @CantidadOmitidaSinVentana AS [CantidadOmitidaSinVentana],
            @CantidadOmitidaVentanaAmbigua AS [CantidadOmitidaVentanaAmbigua];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_MarcarReservasNoRecogidas',
            @NumeroError = @NumeroErrorCapturado,
            @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado,
            @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO
