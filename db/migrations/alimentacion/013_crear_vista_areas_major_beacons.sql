-- Migración: 013_crear_vista_areas_major_beacons
-- Fecha: 2026-09-10T12:00:00-05:00
-- Entidad(es) afectada(s): proximidad.VistaMajorAreaBeacon
-- Referencia: docs-proyecto/alimentacion/TABLAS_ALIMENTACION.md
-- Motivo: Exponer el inventario operativo Área major → beacon autorizado sin duplicar UUID, major, minor, sede ni política.

CREATE VIEW [proximidad].[VistaMajorAreaBeacon]
AS
SELECT
    [MajorArea].[IdMajorAreaBeacon],
    [MajorArea].[IdSede],
    [Sede].[CodigoSede],
    [Sede].[NombreSede],
    [Beacon].[IdentificadorUuid],
    [MajorArea].[NumeroMajor],
    [MajorArea].[CodigoAreaFisica],
    [MajorArea].[NombreAreaFisica],
    [MajorArea].[UbicacionReferencia],
    [MajorArea].[Observacion],
    [Beacon].[IdBeaconAutorizado],
    [Beacon].[ReferenciaBeacon],
    [Beacon].[DireccionMac],
    [Beacon].[NumeroMinor],
    [Beacon].[EstaActivo] AS [EstaActivoBeacon]
FROM [proximidad].[MajorAreaBeacon] AS [MajorArea]
INNER JOIN [organizacion].[Sede] AS [Sede]
    ON [Sede].[IdSede] = [MajorArea].[IdSede]
LEFT JOIN [proximidad].[BeaconAutorizado] AS [Beacon]
    ON [Beacon].[IdMajorAreaBeacon] = [MajorArea].[IdMajorAreaBeacon];
GO

-- DOWN (destructivo; solo sobre la base del proyecto y con aprobación explícita)
-- DROP VIEW IF EXISTS [proximidad].[VistaMajorAreaBeacon];
