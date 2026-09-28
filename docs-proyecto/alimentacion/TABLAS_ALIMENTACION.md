# Tablas del módulo Alimentación GTM

Fecha de actualización: 2026-09-21
Motor objetivo: Microsoft SQL Server 2017  
Schema propio: `alimentacion`

## Alcance y fuente de verdad

Este documento describe las 10 tablas del esquema `alimentacion` y las tres tablas transversales de proximidad creadas por la migración `009`. La fuente de verdad son las migraciones `009` a `017` en `db/migrations/alimentacion/`; ante cualquier diferencia, prevalecen esas migraciones.

No se definen aquí tablas de inventario, compras, recetas, costos, cupos, usuarios, roles ni permisos. Esta documentación no acredita que el DDL haya sido aplicado en una instancia.

## Dependencias del núcleo

Alimentación reutiliza, sin duplicarlos, los siguientes datos externos. La
topología y las fuentes canónicas del ambiente de desarrollo están documentadas
en [STACK.md](../STACK.md#topología-de-desarrollo-vigente).

| Fuente canónica | Uso |
|---|---|
| `PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA.organizacion.Sede` | Sede de ventanas, beacons, planificación, reservas, validaciones y entregas. En desarrollo se consulta desde la instancia GI. |
| `PERSONALMANEGEMENTCORP` | Colaborador corporativo identificado por UUID para reservas y actores. No existe FK local en GTM. |
| `USERMANAGEMENTCORP` | Usuario, identidad y autorización resueltos por backend; no se duplican en GTM. |

## Vista general

| Grupo | Tablas |
|---|---|
| Configuración operativa | `TipoServicio`, `VentanaRetiroServicio` |
| Proximidad | `proximidad.MajorAreaBeacon`, `proximidad.ConfiguracionBeacon`, `proximidad.BeaconAutorizado` |
| Planificación y menú | `Planificacion`, `Menu` |
| Consolidación | `ConsolidacionPlanificacion`, `CantidadConsolidadaMenu` |
| Reserva, QR y entrega | `Reserva`, `CodigoQR`, `Entrega`, `ValidacionEntrega` |

## Configuración operativa

### `alimentacion.TipoServicio`

Maestro de los tipos de servicio que pueden utilizar los menús y las ventanas de retiro. Su clave es `IdTipoServicio`; `CodigoTipoServicio` es único y se referencia desde las tablas operativas.

- Valores iniciales: `DESAYUNO`, `ALMUERZO` y `CENA`.
- `NombreTipoServicio` y `OrdenPresentacion` permiten que el frontend los muestre sin codificar valores.
- Solo los tipos con `EstaActivo = 1` se exponen para crear menús y en `usp_ListarTiposServicio`.

### `alimentacion.VentanaRetiroServicio`

Configura una ventana de retiro por sede y servicio. Su clave es `IdVentanaRetiroServicio`; `IdSede` es una referencia externa a `PERSONAL_MANAGEMENTE_UNIDAD_ORGANIZATIVA`, sin FK local. Registra tipo de servicio, horas de inicio/fin y vigencia.

- El tipo de servicio debe existir en `alimentacion.TipoServicio`.
- Las horas de inicio y fin deben ser distintas.
- El fin de vigencia debe ser posterior al inicio.
- El índice filtrado `IN_VentanaRetiroServicio_Abierta` permite una sola ventana abierta por sede y servicio.

La configuración de beacons y proximidad es transversal y se administra en el esquema `proximidad`.

### `proximidad.MajorAreaBeacon`

Define el área física asociada a una combinación de sede y `major`. Su clave es
`IdMajorAreaBeacon`; la combinación `IdSede` y `NumeroMajor` es única.

- Conserva el código, nombre, ubicación de referencia y observación del área.
- `IdSede` es una referencia externa a `PERSONAL_MANAGEMENTE_UNIDAD_ORGANIZATIVA`, sin FK local.
- Un beacon autorizado debe referenciar obligatoriamente un área major de la
  misma sede y major.
- La tabla no representa un beacon físico: un área major puede tener varios
  beacons, diferenciados por `minor`.

### `proximidad.ConfiguracionBeacon`

Define una política reutilizable de proximidad para una sede. Su clave es
`IdConfiguracionProximidadBeacon`; `CodigoVersion` es único dentro de la sede y
se expone al backend como `configurationVersion`.

- La política contiene `CantidadMinimaEmisiones`,
  `VentanaConfirmacionMilisegundos`, `IntervaloEvaluacionMilisegundos`,
  `TiempoSalidaRangoMilisegundos` y `UmbralRssi`.
- `IdSede` es una referencia externa a `PERSONAL_MANAGEMENTE_UNIDAD_ORGANIZATIVA`, sin FK local.
- La política tiene vigencia mediante `FechaInicioVigencia` y
  `FechaFinVigencia`; el fin, si existe, debe ser posterior al inicio.
- Para cambiar parámetros se registra una nueva configuración con otro
  `CodigoVersion` y se reasignan los beacons; la configuración publicada no se
  modifica en sitio.
- Una misma configuración puede asignarse a varios beacons de la misma sede,
  evitando duplicar sus parámetros.
- `IdConfiguracionProximidadBeacon` identifica internamente la política aplicada
  y puede exponerse como referencia de configuración si un consumidor lo requiere.

### `proximidad.BeaconAutorizado`

Registra un beacon habilitado para una sede. Su identidad técnica es la terna
`IdentificadorUuid`, `NumeroMajor` y `NumeroMinor`, que es única.

- `IdSede` es una referencia externa a `PERSONAL_MANAGEMENTE_UNIDAD_ORGANIZATIVA`, sin FK local.
- Cada beacon referencia obligatoriamente una `ConfiguracionBeacon` de su misma
  sede mediante la FK compuesta por configuración y sede.
- La regla impide asignar a un beacon la política de otra sede.
- `ReferenciaBeacon` es la referencia funcional que el backend expone como
  `beaconRef`; debe contener texto no vacío.
- `DireccionMac` permite registrar la MAC del dispositivo en formato canónico
  `AA:BB:CC:DD:EE:FF`. Es opcional y no sustituye la identidad BLE formada por
  UUID, major y minor.
- `EstaActivo` determina si el beacon puede ser expuesto para operación móvil.

## Planificación y menú

### `alimentacion.Planificacion`

Agrupa días de servicio elegidos libremente para una sede y controla su estado. Su clave es `IdPlanificacion`, con identificador público único. `IdSede` conserva el identificador interno de la sede en `PERSONAL_MANAGEMENTE_UNIDAD_ORGANIZATIVA`; no tiene FK local porque la sede reside en otra base de datos.

- Estados: `BORRADOR`, `PUBLICADA_ABIERTA`, `PUBLICADA_CERRADA`, `CONSOLIDADA`, `ELIMINADA`.
- `IdColaboradorRegistroCorporativo` e `IdColaboradorModificacionCorporativo` conservan los UUID de CO del registrador y del último modificador, respectivamente. No tienen FK local porque el colaborador reside en otra instancia.
- Conserva la vigencia lógica (`EstaActivo`); una planificación eliminada queda inactiva.
- `VersionRegistro` debe ser mayor que cero.
- Conserva `Nombre`, `FechaInicio` y `FechaFin` como período explícito para identificarla y listarla; el fin no puede ser anterior al inicio.
- Los días con servicio se definen mediante `Menu.FechaServicio`; no es obligatorio que todos los días del período tengan menú.

### `alimentacion.Menu`

Define un menú —o la indisponibilidad— para una planificación, fecha y tipo de servicio. Su clave es `IdMenu`; tiene FK a `Planificacion` e identificador público único.

- `MenuId` es una referencia obligatoria a un menú gestionado en otra base de datos. No tiene FK local y debe ser provista por `usp_CrearMenuPlanificacion` y `usp_CrearMenusPlanificacionLote`.
- `IdColaboradorRegistroCorporativo` conserva el UUID de CO de quien registra el menú, sin FK local.
- La combinación `IdPlanificacion`, `FechaServicio`, `TipoServicio` es única.
- El tipo de servicio debe existir en `alimentacion.TipoServicio`.
- Si está disponible, exige nombre; si no lo está, no puede conservar nombre, descripción ni imagen.
- `VersionRegistro` debe ser mayor que cero.

## Consolidación

### `alimentacion.ConsolidacionPlanificacion`

Registra el hecho irreversible de consolidar una planificación. Su clave es `IdConsolidacionPlanificacion`; tiene FK a `Planificacion` y conserva en `IdActorColaboradorCorporativo` el UUID de CO del actor, sin FK local.

- Existe como máximo una consolidación por planificación.
- `IdCorrelacion` es único.
- `EstadoAnterior` debe ser `PUBLICADA_CERRADA`.
- Conserva la versión de la planificación, actor y fecha de consolidación.

### `alimentacion.CantidadConsolidadaMenu`

Guarda la fotografía final de reservas por menú al consolidar. Tiene clave compuesta `IdConsolidacionPlanificacion` + `IdMenu`.

- Referencia, mediante FKs compuestas, la consolidación y el menú de la misma planificación.
- `CantidadReservas` no puede ser negativa.
- Es un snapshot de consolidación; no reemplaza el conteo operativo de reservas.

## Reserva, QR y entrega

### `alimentacion.Reserva`

Representa la reserva individual de un colaborador para un servicio. Su clave es `IdReserva`; tiene FKs hacia el contexto de `Planificacion`/sede y el de `Menu`. `IdColaboradorCorporativo` conserva el UUID de CO del colaborador, sin FK local.

- Estados: `RESERVADA`, `CANCELADA`, `ENTREGADA`, `NO_RECOGIDA`.
- El índice filtrado `IN_Reserva_ActivaColaboradorFecha` limita a una reserva con estado `RESERVADA` por colaborador y fecha.
- Almacena el contexto de sede, fecha y servicio para asegurar la coherencia con el menú elegido.

### `alimentacion.CodigoQR`

Representa un QR opaco asociado a una reserva. Su clave es el UUID `IdCodigoQR`; tiene FK a `Reserva`.

- Solo persiste `HashCodigo`, nunca el valor del QR en claro.
- Estados: `VIGENTE`, `VENCIDO`, `UTILIZADO`, `REVOCADO`.
- El vencimiento es posterior a la emisión y no excede cinco minutos.
- Solo puede existir un QR vigente por reserva.
- Las fechas de uso o revocación y el motivo de revocación deben ser consistentes con el estado.

### `alimentacion.Entrega`

Confirma el retiro presencial normal. Su clave es `IdEntrega`; tiene FKs compuestas al contexto de reserva y QR. `IdOperadorColaboradorCorporativo` conserva el UUID de CO del operador, sin FK local.

- Una entrega por reserva, por QR y por correlación.
- Métodos permitidos: `CAMARA` y `LECTOR_HID`.
- Conserva el contexto de sede, fecha y servicio, el operador y la fecha local de entrega.

### `alimentacion.ValidacionEntrega`

Registra la validación temporal previa al consumo del QR. Su clave es el UUID `ValidationId`; tiene FKs al par QR/reserva y a reserva. `IdOperadorColaboradorCorporativo` conserva el UUID de CO del operador e `IdSede` la referencia a UO, ambos sin FK local.

- Conserva solo `HashCodigo`; no persiste el QR en claro.
- Métodos permitidos: `CAMARA` y `LECTOR_HID`.
- El vencimiento debe ser posterior a la creación y no exceder dos minutos.
- `IdCorrelacion` es único y el consumo no puede ocurrir antes de la creación.

## Relaciones principales

```text
TipoServicio ──< VentanaRetiroServicio, Menu, Reserva, Entrega
Sede ──< VentanaRetiroServicio
Sede ──< MajorAreaBeacon ──< BeaconAutorizado >── ConfiguracionBeacon
Sede ──< ConfiguracionBeacon
Sede ──< Planificacion ──< Menu
                              │
Planificacion ── 0..1 ConsolidacionPlanificacion ──< CantidadConsolidadaMenu
                              │
Colaborador ──< Reserva >── Menu
                    │
                    ├──< CodigoQR ── 0..1 Entrega
                    └──< ValidacionEntrega

Colaborador ──< Entrega, ValidacionEntrega
```

## Límites conocidos

- Las migraciones no implementan procedures, vistas, funciones, triggers, roles ni permisos.
- Los límites transaccionales entre reserva, QR, validación, entrega y consolidación requieren un contrato de backend y objetos programables aprobados por separado.
- El módulo no determina el servicio a partir de `rrhh.HorarioLaboral.TipoTurno`; lo configura explícitamente por menú y fecha.
- No hay tablas de inventario, compras, recetas, costos, capacidad ni reportes materializados.

## Referencias

- `db/migrations/alimentacion/009_crear_schema_y_configuracion_alimentacion.sql` a `017_crear_maestro_tipos_servicio.sql`.
- `docs-proyecto/alimentacion/Stores Procedures/usp_ListarPlanificaciones.md`, contrato de lectura del listado maestro.
- `docs-proyecto/alimentacion/Stores Procedures/usp_ObtenerResumenPlanificacion.md`, contrato del resumen de planificación.
- `docs-proyecto/alimentacion/Stores Procedures/usp_ListarMenusPlanificacionPorTipoServicio.md`, contrato del calendario de menús por tipo de servicio.
- `docs-proyecto/alimentacion/Stores Procedures/016_listar_menus_configuracion_plantilla.md`, contrato del listado diario de menús y sus reservas para sistemas consumidores.
- `docs-proyecto/alimentacion/Stores Procedures/017_listar_planificaciones_plantilla.md`, contrato del listado simple de planificaciones para sistemas consumidores.
- `docs-proyecto/alimentacion/Stores Procedures/009_listar_tipos_servicio.md`, contrato del maestro de tipos de servicio para frontend.
- `docs-proyecto/nucleo/TABLAS_NUCLEO.md`, para las tablas externas requeridas del núcleo común.
