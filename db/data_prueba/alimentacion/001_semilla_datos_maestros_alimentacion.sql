-- Datos de prueba: 001_semilla_datos_maestros_alimentacion
-- Motor objetivo: Microsoft SQL Server 2017
-- Alcance: configuración maestra del schema alimentacion.
-- Incluye: VentanaRetiroServicio, BeaconAutorizado y ConfiguracionProximidadBeacon.
-- Excluye: Planificacion, Menu, ComponenteMenu, ConsolidacionPlanificacion,
--          CantidadConsolidadaMenu, Reserva, CodigoQR, Entrega y ValidacionEntrega.
-- No ejecutar contra producción. Requiere las migraciones núcleo 001..008,
-- Alimentación 009 y la sede sintética GTM-PRUEBA / LIM-PRU.

SET XACT_ABORT ON;
SET NOCOUNT ON;

IF OBJECT_ID(N'[alimentacion].[VentanaRetiroServicio]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[BeaconAutorizado]', N'U') IS NULL
   OR OBJECT_ID(N'[alimentacion].[ConfiguracionProximidadBeacon]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Sede]', N'U') IS NULL
    THROW 51010, N'Faltan tablas requeridas. Aplique primero las migraciones núcleo 001..008 y Alimentación 009.', 1;

DECLARE @IdSedePrueba INT =
(
    SELECT [s].[IdSede]
    FROM [organizacion].[Sede] AS [s]
    INNER JOIN [organizacion].[Empresa] AS [e]
        ON [e].[IdEmpresa] = [s].[IdEmpresa]
    WHERE [e].[CodigoEmpresa] = N'03'
      AND [s].[CodigoSede] = N'01'
);

IF @IdSedePrueba IS NULL
    THROW 51011, N'No se encontró la sede de prueba GTM-PRUEBA / LIM-PRU. Ejecute primero la semilla del núcleo.', 1;

BEGIN TRANSACTION;

-- Ventanas maestras de retiro por tipo de servicio.
IF NOT EXISTS
(
    SELECT 1
    FROM [alimentacion].[VentanaRetiroServicio]
    WHERE [IdSede] = @IdSedePrueba
      AND [TipoServicio] = N'DESAYUNO'
      AND [FechaInicioVigencia] = '2024-01-01'
)
    INSERT INTO [alimentacion].[VentanaRetiroServicio]
        ([IdSede], [TipoServicio], [HoraInicio], [HoraFin], [FechaInicioVigencia])
    VALUES
        (@IdSedePrueba, N'DESAYUNO', '07:00', '09:00', '2024-01-01');

IF NOT EXISTS
(
    SELECT 1
    FROM [alimentacion].[VentanaRetiroServicio]
    WHERE [IdSede] = @IdSedePrueba
      AND [TipoServicio] = N'ALMUERZO'
      AND [FechaInicioVigencia] = '2024-01-01'
)
    INSERT INTO [alimentacion].[VentanaRetiroServicio]
        ([IdSede], [TipoServicio], [HoraInicio], [HoraFin], [FechaInicioVigencia])
    VALUES
        (@IdSedePrueba, N'ALMUERZO', '12:00', '14:00', '2024-01-01');

IF NOT EXISTS
(
    SELECT 1
    FROM [alimentacion].[VentanaRetiroServicio]
    WHERE [IdSede] = @IdSedePrueba
      AND [TipoServicio] = N'CENA'
      AND [FechaInicioVigencia] = '2024-01-01'
)
    INSERT INTO [alimentacion].[VentanaRetiroServicio]
        ([IdSede], [TipoServicio], [HoraInicio], [HoraFin], [FechaInicioVigencia])
    VALUES
        (@IdSedePrueba, N'CENA', '18:00', '20:00', '2024-01-01');

-- Beacon sintético autorizado para la sede de prueba.
IF NOT EXISTS
(
    SELECT 1
    FROM [alimentacion].[BeaconAutorizado]
    WHERE [IdentificadorUuid] = '11111111-1111-1111-1111-111111111111'
      AND [NumeroMajor] = 100
      AND [NumeroMinor] = 1
)
    INSERT INTO [alimentacion].[BeaconAutorizado]
        ([IdSede], [IdentificadorUuid], [NumeroMajor], [NumeroMinor], [EstaActivo])
    VALUES
        (@IdSedePrueba, '11111111-1111-1111-1111-111111111111', 100, 1, 1);

DECLARE @IdBeaconPrueba BIGINT =
(
    SELECT [IdBeaconAutorizado]
    FROM [alimentacion].[BeaconAutorizado]
    WHERE [IdentificadorUuid] = '11111111-1111-1111-1111-111111111111'
      AND [NumeroMajor] = 100
      AND [NumeroMinor] = 1
);

-- Configuración maestra vigente de proximidad para el beacon sintético.
IF NOT EXISTS
(
    SELECT 1
    FROM [alimentacion].[ConfiguracionProximidadBeacon]
    WHERE [IdBeaconAutorizado] = @IdBeaconPrueba
      AND [FechaInicioVigenciaUtc] = '2024-01-01T00:00:00.000'
)
    INSERT INTO [alimentacion].[ConfiguracionProximidadBeacon]
        ([IdBeaconAutorizado], [CantidadMinimaEmisiones], [VentanaConfirmacionMilisegundos],
         [TiempoSalidaRangoMilisegundos], [UmbralRssi], [FechaInicioVigenciaUtc])
    VALUES
        (@IdBeaconPrueba, 3, 5000, 10000, -75, '2024-01-01T00:00:00.000');

COMMIT TRANSACTION;
GO
