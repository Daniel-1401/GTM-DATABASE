# Estado oficial de objetos de base de datos

Fecha de actualización: 2026-09-07  
Motor objetivo: Microsoft SQL Server 2017

## 1. Decisión vigente

El catálogo físico oficial de GTM está formado exclusivamente por las **27
tablas** declaradas en las migraciones vigentes de este repositorio: 15 del
núcleo y 12 de Alimentación. Sus schemas, columnas, restricciones e índices
son los que constan en dichos archivos de migración.

Esta decisión oficializa el modelo de tablas como fuente de documentación. No
aporta evidencia de que el DDL haya sido aplicado ni de que esas tablas existan
en una instancia SQL Server: no hay ejecución ni conexión a una instancia
registradas por este repositorio.

## 2. Catálogo oficial de tablas

| Schema | Tablas oficiales | Fuente |
|---|---:|---|
| `catalogo` | `TipoDocumento`, `TipoJefatura` | `db/migrations/nucleo/002_crear_catalogos_identidad_y_jefatura.sql` |
| `rrhh` | `Persona`, `Colaborador`, `DocumentoPersona`, `RelacionLaboral`, `AsignacionOrganizacional`, `HorarioLaboral`, `VigenciaHorario`, `JefaturaRelacionLaboral` | Migraciones núcleo `003`, `005` a `008` |
| `organizacion` | `Empresa`, `Sede`, `Area`, `Cargo` | `db/migrations/nucleo/004_crear_organizacion_y_centros_costo_sap.sql` |
| `integracion` | `CuentaMicrosoftCorporativa` | `db/migrations/nucleo/003_crear_personas_colaboradores_e_identidad_microsoft.sql` |
| `alimentacion` | `VentanaRetiroServicio`, `BeaconAutorizado`, `ConfiguracionProximidadBeacon`, `Planificacion`, `Menu`, `ComponenteMenu`, `ConsolidacionPlanificacion`, `CantidadConsolidadaMenu`, `Reserva`, `CodigoQR`, `Entrega`, `ValidacionEntrega` | Migraciones Alimentación `009` a `012` |

## 3. Objetos no definidos

No existe una definición oficial para procedimientos almacenados (stores),
triggers, vistas, funciones, permisos, roles, jobs, sinónimos ni otros objetos
programables o de operación. Por tanto, ninguno se considera parte del modelo
oficial ni puede consumirse como contrato de Backend.

## 4. Próximo gate

Antes de definir cualquier objeto no tabular se requiere un contrato funcional
y técnico aprobado que indique su propósito, firma, transacciones, seguridad,
auditoría, concurrencia, pruebas y responsable consumidor. La definición de
esos objetos y la autorización para ejecutar DDL son decisiones separadas.

## 5. Lectura de los demás documentos

Los diagramas ER y el registro de scripts describen las tablas oficiales. Cuando
un documento anterior mencione stores, triggers, vistas, funciones o artefactos
similares, debe leerse como antecedente no oficial hasta que supere el gate de
la sección 4. Este documento prevalece para el estado de definición de objetos.
