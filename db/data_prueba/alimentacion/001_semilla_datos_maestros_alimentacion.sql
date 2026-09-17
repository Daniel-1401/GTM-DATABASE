-- Datos de prueba: 001_semilla_datos_maestros_alimentacion
-- Motor objetivo: Microsoft SQL Server 2017
-- Alcance: configuración maestra del schema alimentacion.
-- Incluye: VentanaRetiroServicio, MatrizInformativaBeacon, MajorAreaBeacon,
--          BeaconAutorizado y ConfiguracionProximidadBeacon.
-- Excluye: Planificacion, Menu, ComponenteMenu, ConsolidacionPlanificacion,
--          CantidadConsolidadaMenu, Reserva, CodigoQR, Entrega y ValidacionEntrega.
-- No ejecutar contra producción. Requiere las migraciones núcleo 001..008,
-- Alimentación 009 y la sede sintética GTM-PRUEBA / LIM-PRU.

SET XACT_ABORT ON;
SET NOCOUNT ON;

IF OBJECT_ID(N'[alimentacion].[VentanaRetiroServicio]', N'U') IS NULL
   OR OBJECT_ID(N'[proximidad].[BeaconAutorizado]', N'U') IS NULL
   OR OBJECT_ID(N'[proximidad].[ConfiguracionBeacon]', N'U') IS NULL
   OR OBJECT_ID(N'[proximidad].[MatrizInformativaBeacon]', N'U') IS NULL
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
IF EXISTS
(
    SELECT 1
    FROM [proximidad].[MatrizInformativaBeacon]
    WHERE [IdentificadorUuid] = @UUID_BEACON_PRUEBAS
      AND [IdEmpresa] <> @IdEmpresaPrueba
)
    THROW 51013, N'El UUID de prueba ya pertenece a otra empresa.', 1;

-- El UUID de prueba pertenece a Golden Palace (empresa 03).
IF NOT EXISTS
(
    SELECT 1
    FROM [proximidad].[MatrizInformativaBeacon]
    WHERE [IdentificadorUuid] = @UUID_BEACON_PRUEBAS
)
    INSERT INTO [proximidad].[MatrizInformativaBeacon]
        ([IdEmpresa], [IdentificadorUuid])
    VALUES
        (@IdEmpresaPrueba, @UUID_BEACON_PRUEBAS);

DECLARE @IdMatrizInformativaBeacon BIGINT =
(
    SELECT [IdMatrizInformativaBeacon]
    FROM [proximidad].[MatrizInformativaBeacon]
    WHERE [IdentificadorUuid] = @UUID_BEACON_PRUEBAS
);

IF EXISTS
(
    SELECT 1
    FROM [proximidad].[MajorAreaBeacon]
    WHERE [IdMatrizInformativaBeacon] = @IdMatrizInformativaBeacon
      AND [NumeroMajor] = 100
      AND [CodigoAreaFisica] <> N'COMEDOR'
)
    THROW 51014, N'El Major 100 del UUID de prueba ya está asociado a otra área física.', 1;

-- El Major 100 del UUID de prueba corresponde al área física COMEDOR.
IF NOT EXISTS
(
    SELECT 1
    FROM [proximidad].[MajorAreaBeacon]
    WHERE [IdMatrizInformativaBeacon] = @IdMatrizInformativaBeacon
      AND [NumeroMajor] = 100
)
    INSERT INTO [proximidad].[MajorAreaBeacon]
        ([IdMatrizInformativaBeacon], [CodigoAreaFisica], [NombreAreaFisica], [NumeroMajor], [UbicacionReferencia])
    VALUES
        (@IdMatrizInformativaBeacon, N'COMEDOR', N'Comedor', 100, N'Comedor de la sede Golden Palace');

-- Beacon sintético autorizado para la sede de prueba.
IF NOT EXISTS
(
    SELECT 1
    FROM [proximidad].[BeaconAutorizado]
    WHERE [IdentificadorUuid] = @UUID_BEACON_PRUEBAS
      AND [NumeroMajor] = 100
      AND [NumeroMinor] = 1
)
    INSERT INTO [proximidad].[BeaconAutorizado]
        ([IdSede], [IdentificadorUuid], [NumeroMajor], [NumeroMinor], [EstaActivo])
    VALUES
        (@IdSedePrueba, @UUID_BEACON_PRUEBAS, 100, 1, 1);

DECLARE @IdBeaconPrueba BIGINT =
(
    SELECT [IdBeaconAutorizado]
    FROM [proximidad].[BeaconAutorizado]
    WHERE [IdentificadorUuid] = @UUID_BEACON_PRUEBAS
      AND [NumeroMajor] = 100
      AND [NumeroMinor] = 1
);

-- Configuración maestra vigente de proximidad para el beacon sintético.
IF NOT EXISTS
(
    SELECT 1
    FROM [proximidad].[ConfiguracionBeacon]
    WHERE [IdBeaconAutorizado] = @IdBeaconPrueba
      AND [FechaInicioVigenciaUtc] = '2024-01-01T00:00:00.000'
)
    INSERT INTO [proximidad].[ConfiguracionBeacon]
        ([IdBeaconAutorizado], [CantidadMinimaEmisiones], [VentanaConfirmacionMilisegundos],
         [TiempoSalidaRangoMilisegundos], [UmbralRssi], [FechaInicioVigenciaUtc])
    VALUES
        (@IdBeaconPrueba, 3, 5000, 10000, -75, '2024-01-01T00:00:00.000');

COMMIT TRANSACTION;
GO
