-- Procedimiento: proximidad.usp_ObtenerConfiguracionBeaconsSede
-- Referencias: migraciones 009 y 016 del módulo Alimentación.
-- Motivo: Exponer al backend las configuraciones vigentes de proximidad y los
--          beacons autorizados de una sede, mediante recordsets normalizados.
-- Este procedimiento es de lectura y no abre transacciones de negocio.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [proximidad].[usp_ObtenerConfiguracionBeaconsSede]
    @IdSede INT,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdSede IS NULL OR @IdSede <= 0
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'La sede es obligatoria y debe ser válida.';
        RETURN;
    END;

    DECLARE @EstaActivaSede BIT;

    SELECT
        @EstaActivaSede = [Sede].[EstaActiva]
    FROM [PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA].[organizacion].[Sede] AS [Sede]
    WHERE [Sede].[IdSede] = @IdSede;

    IF @EstaActivaSede IS NULL
    BEGIN
        SET @Codigo = N'NOT_FOUND';
        SET @Mensaje = N'La sede indicada no existe.';
        RETURN;
    END;

    BEGIN TRY
        -- SYSDATETIME() es la convención vigente para la fecha oficial en SQL Server.
        DECLARE @FechaConsulta DATETIME2(3) = SYSDATETIME();

        DECLARE @ConfiguracionesVigentes TABLE
        (
            [IdConfiguracionProximidadBeacon] BIGINT NOT NULL PRIMARY KEY,
            [CodigoVersion] NVARCHAR(100) NOT NULL,
            [CantidadMinimaEmisiones] SMALLINT NOT NULL,
            [VentanaConfirmacionMilisegundos] INT NOT NULL,
            [IntervaloEvaluacionMilisegundos] INT NOT NULL,
            [TiempoSalidaRangoMilisegundos] INT NOT NULL,
            [UmbralRssi] SMALLINT NULL,
            [FechaInicioVigencia] DATETIME2(3) NOT NULL,
            [FechaFinVigencia] DATETIME2(3) NULL
        );

        INSERT INTO @ConfiguracionesVigentes
        (
            [IdConfiguracionProximidadBeacon],
            [CodigoVersion],
            [CantidadMinimaEmisiones],
            [VentanaConfirmacionMilisegundos],
            [IntervaloEvaluacionMilisegundos],
            [TiempoSalidaRangoMilisegundos],
            [UmbralRssi],
            [FechaInicioVigencia],
            [FechaFinVigencia]
        )
        SELECT
            [Configuracion].[IdConfiguracionProximidadBeacon],
            [Configuracion].[CodigoVersion],
            [Configuracion].[CantidadMinimaEmisiones],
            [Configuracion].[VentanaConfirmacionMilisegundos],
            [Configuracion].[IntervaloEvaluacionMilisegundos],
            [Configuracion].[TiempoSalidaRangoMilisegundos],
            [Configuracion].[UmbralRssi],
            [Configuracion].[FechaInicioVigencia],
            [Configuracion].[FechaFinVigencia]
        FROM [proximidad].[ConfiguracionBeacon] AS [Configuracion]
        WHERE [Configuracion].[IdSede] = @IdSede
          AND [Configuracion].[FechaInicioVigencia] <= @FechaConsulta
          AND
          (
              [Configuracion].[FechaFinVigencia] IS NULL
              OR [Configuracion].[FechaFinVigencia] > @FechaConsulta
          );

        -- Recordset 1: políticas vigentes de la sede.
        SELECT
            [IdSede] = @IdSede,
            [EstaActivaSede] = @EstaActivaSede,
            [Configuracion].[IdConfiguracionProximidadBeacon],
            [Configuracion].[CodigoVersion],
            [Configuracion].[CantidadMinimaEmisiones],
            [Configuracion].[VentanaConfirmacionMilisegundos],
            [Configuracion].[IntervaloEvaluacionMilisegundos],
            [Configuracion].[TiempoSalidaRangoMilisegundos],
            [Configuracion].[UmbralRssi],
            [Configuracion].[FechaInicioVigencia],
            [Configuracion].[FechaFinVigencia]
        FROM @ConfiguracionesVigentes AS [Configuracion]
        ORDER BY [Configuracion].[CodigoVersion], [Configuracion].[IdConfiguracionProximidadBeacon];

        -- Recordset 2: beacons asociados a cada política vigente.
        SELECT
            [Beacon].[IdSede],
            [Beacon].[IdConfiguracionProximidadBeacon],
            [Beacon].[IdBeaconAutorizado],
            [Beacon].[ReferenciaBeacon],
            [Beacon].[DireccionMac],
            [Beacon].[IdentificadorUuid],
            [Beacon].[NumeroMajor],
            [Beacon].[NumeroMinor],
            [Beacon].[EstaActivo] AS [EstaActivoBeacon],
            [MajorArea].[IdMajorAreaBeacon],
            [MajorArea].[CodigoAreaFisica],
            [MajorArea].[NombreAreaFisica],
            [MajorArea].[UbicacionReferencia],
            [MajorArea].[Observacion]
        FROM [proximidad].[BeaconAutorizado] AS [Beacon]
        INNER JOIN @ConfiguracionesVigentes AS [Configuracion]
            ON [Configuracion].[IdConfiguracionProximidadBeacon] = [Beacon].[IdConfiguracionProximidadBeacon]
        INNER JOIN [proximidad].[MajorAreaBeacon] AS [MajorArea]
            ON [MajorArea].[IdMajorAreaBeacon] = [Beacon].[IdMajorAreaBeacon]
        WHERE [Beacon].[IdSede] = @IdSede
        ORDER BY
            [Beacon].[IdConfiguracionProximidadBeacon],
            [Beacon].[ReferenciaBeacon],
            [Beacon].[IdBeaconAutorizado];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();

        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'proximidad.usp_ObtenerConfiguracionBeaconsSede',
            @NumeroError = @NumeroErrorCapturado,
            @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado,
            @DetalleInterno = @DetalleErrorCapturado;

        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO

/*
    DECLARE @IdSede INT = 1,
            @Codigo NVARCHAR(50),
            @Mensaje NVARCHAR(500);
    EXEC [proximidad].[usp_ObtenerConfiguracionBeaconsSede] @IdSede, @Codigo, @Mensaje;

 */
