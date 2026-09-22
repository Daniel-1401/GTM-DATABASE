-- Datos de prueba: 001_semilla_datos_maestros_alimentacion
-- Motor objetivo: Microsoft SQL Server 2017
-- Alcance: configuración maestra del schema alimentacion.
-- Incluye: VentanaRetiroServicio, MajorAreaBeacon, ConfiguracionBeacon reutilizable
--          y BeaconAutorizado.
-- Excluye: Planificacion, Menu, ConsolidacionPlanificacion,
--          CantidadConsolidadaMenu, Reserva, CodigoQR, Entrega y ValidacionEntrega.
-- No ejecutar contra producción. Requiere las migraciones núcleo 001..008,
-- Alimentación 009 y la sede sintética GTM-PRUEBA / LIM-PRU.

SET XACT_ABORT ON;
SET NOCOUNT ON;

IF OBJECT_ID(N'[alimentacion].[VentanaRetiroServicio]', N'U') IS NULL
   OR OBJECT_ID(N'[proximidad].[BeaconAutorizado]', N'U') IS NULL
   OR OBJECT_ID(N'[proximidad].[ConfiguracionBeacon]', N'U') IS NULL
   OR OBJECT_ID(N'[proximidad].[MajorAreaBeacon]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Empresa]', N'U') IS NULL
   OR OBJECT_ID(N'[organizacion].[Sede]', N'U') IS NULL
    THROW 51010, N'Faltan tablas requeridas. Aplique primero las migraciones núcleo 001..008 y Alimentación 009.', 1;

DECLARE @IdEmpresaPrueba INT =
(
    SELECT [IdEmpresa]
    FROM [organizacion].[Empresa]
    WHERE [CodigoEmpresa] = N'03'
);

DECLARE @IdSedePrueba INT =
(
    SELECT [s].[IdSede]
    FROM [organizacion].[Sede] AS [s]
    WHERE [s].[IdEmpresa] = @IdEmpresaPrueba
      AND [s].[CodigoSede] = N'01'
);

IF @IdSedePrueba IS NULL
    THROW 51011, N'No se encontró la sede de prueba GTM-PRUEBA / GOLDEN PALACE. Ejecute primero la semilla del núcleo.', 1;

BEGIN TRANSACTION;

-- Ventanas maestras de retiro por tipo de servicio.
IF NOT EXISTS
(
    SELECT 1
    FROM [alimentacion].[VentanaRetiroServicio]
    WHERE [IdSede] = @IdSedePrueba
      AND [TipoServicio] = N'DESAYUNO'
      AND [FechaInicioVigencia] = '2026-09-01'
)
    INSERT INTO [alimentacion].[VentanaRetiroServicio]
        ([IdSede], [TipoServicio], [HoraInicio], [HoraFin], [FechaInicioVigencia])
    VALUES
        (@IdSedePrueba, N'DESAYUNO', '07:00', '09:00', '2026-09-01');

IF NOT EXISTS
(
    SELECT 1
    FROM [alimentacion].[VentanaRetiroServicio]
    WHERE [IdSede] = @IdSedePrueba
      AND [TipoServicio] = N'ALMUERZO'
      AND [FechaInicioVigencia] = '2026-09-01'
)
    INSERT INTO [alimentacion].[VentanaRetiroServicio]
        ([IdSede], [TipoServicio], [HoraInicio], [HoraFin], [FechaInicioVigencia])
    VALUES
        (@IdSedePrueba, N'ALMUERZO', '12:00', '14:00', '2026-09-01');

IF NOT EXISTS
(
    SELECT 1
    FROM [alimentacion].[VentanaRetiroServicio]
    WHERE [IdSede] = @IdSedePrueba
      AND [TipoServicio] = N'CENA'
      AND [FechaInicioVigencia] = '2026-09-01'
)
    INSERT INTO [alimentacion].[VentanaRetiroServicio]
        ([IdSede], [TipoServicio], [HoraInicio], [HoraFin], [FechaInicioVigencia])
    VALUES
        (@IdSedePrueba, N'CENA', '18:00', '20:00', '2026-09-01');

DECLARE @UUID_BEACON_PRUEBAS UNIQUEIDENTIFIER = 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0';
DECLARE @NumeroMajorBeaconPrueba INT = 1;
IF EXISTS
(
    SELECT 1
    FROM [proximidad].[MajorAreaBeacon]
    WHERE [IdSede] = @IdSedePrueba
      AND [NumeroMajor] = @NumeroMajorBeaconPrueba
      AND [CodigoAreaFisica] <> N'COMEDOR'
)
    THROW 51014, N'El major de prueba ya está asociado a otra área física.', 1;

-- El major de prueba corresponde al área física COMEDOR de la sede.
IF NOT EXISTS
(
    SELECT 1
    FROM [proximidad].[MajorAreaBeacon]
    WHERE [IdSede] = @IdSedePrueba
      AND [NumeroMajor] = @NumeroMajorBeaconPrueba
)
    INSERT INTO [proximidad].[MajorAreaBeacon]
        ([IdSede], [CodigoAreaFisica], [NombreAreaFisica], [NumeroMajor], [UbicacionReferencia])
    VALUES
        (@IdSedePrueba, N'COMEDOR', N'Comedor', @NumeroMajorBeaconPrueba, N'Comedor de la sede Golden Palace');

DECLARE @IdMajorAreaBeaconPrueba BIGINT =
(
    SELECT [IdMajorAreaBeacon]
    FROM [proximidad].[MajorAreaBeacon]
    WHERE [IdSede] = @IdSedePrueba
      AND [NumeroMajor] = @NumeroMajorBeaconPrueba
);

-- Política maestra vigente reutilizable para los beacons sintéticos de la sede.
DECLARE @CodigoVersionConfiguracionPrueba NVARCHAR(100) = N'BEACON-PRUEBA-V1';
IF NOT EXISTS
(
    SELECT 1
    FROM [proximidad].[ConfiguracionBeacon]
    WHERE [IdSede] = @IdSedePrueba
      AND [CodigoVersion] = @CodigoVersionConfiguracionPrueba
)
    INSERT INTO [proximidad].[ConfiguracionBeacon]
        ([IdSede], [CodigoVersion], [CantidadMinimaEmisiones], [VentanaConfirmacionMilisegundos],
         [IntervaloEvaluacionMilisegundos], [TiempoSalidaRangoMilisegundos], [UmbralRssi], [FechaInicioVigencia])
    VALUES
        (@IdSedePrueba, @CodigoVersionConfiguracionPrueba, 3, 4000, 250, 2000, -70, '2026-09-21T00:00:00.000');

DECLARE @IdConfiguracionProximidadBeaconPrueba BIGINT =
(
    SELECT [IdConfiguracionProximidadBeacon]
    FROM [proximidad].[ConfiguracionBeacon]
    WHERE [IdSede] = @IdSedePrueba
      AND [CodigoVersion] = @CodigoVersionConfiguracionPrueba
);

-- Beacon sintético autorizado para la sede de prueba.
IF NOT EXISTS
(
    SELECT 1
    FROM [proximidad].[BeaconAutorizado]
    WHERE [IdentificadorUuid] = @UUID_BEACON_PRUEBAS
      AND [NumeroMajor] = @NumeroMajorBeaconPrueba
      AND [NumeroMinor] = 1
)
    INSERT INTO [proximidad].[BeaconAutorizado]
        ([IdSede], [IdMajorAreaBeacon], [IdConfiguracionProximidadBeacon], [ReferenciaBeacon], [DireccionMac], [IdentificadorUuid], [NumeroMajor], [NumeroMinor], [EstaActivo])
    VALUES
        (@IdSedePrueba, @IdMajorAreaBeaconPrueba, @IdConfiguracionProximidadBeaconPrueba, N'room-test-01', 'F8:9B:EB:B0:C8:71', @UUID_BEACON_PRUEBAS, @NumeroMajorBeaconPrueba, 1, 1);

COMMIT TRANSACTION;
GO
