# Tablas del módulo Alimentación GTM

Fecha de actualización: 2026-09-08  
Motor objetivo: Microsoft SQL Server 2017  
Schema propio: `alimentacion`

## Alcance y fuente de verdad

Este documento describe las 12 tablas oficiales del módulo Alimentación. La fuente de verdad son las migraciones `009` a `015` en `db/migrations/alimentacion/`; ante cualquier diferencia, prevalecen esas migraciones.

No se definen aquí tablas de inventario, compras, recetas, costos, cupos, usuarios, roles ni permisos. Esta documentación no acredita que el DDL haya sido aplicado en una instancia.

## Dependencias del núcleo

Alimentación reutiliza, sin duplicarlos, los siguientes datos del núcleo:

| Tabla del núcleo | Uso |
|---|---|
| `organizacion.Sede` | Sede de ventanas, beacons, planificación, reservas, validaciones y entregas. |
| `rrhh.Colaborador` | Colaborador que reserva, actor de consolidación y operador de entrega. |

## Vista general

| Grupo | Tablas |
|---|---|
| Configuración operativa | `VentanaRetiroServicio` |
| Planificación y menú | `Planificacion`, `Menu`, `ComponenteMenu` |
| Consolidación | `ConsolidacionPlanificacion`, `CantidadConsolidadaMenu` |
| Reserva, QR y entrega | `Reserva`, `CodigoQR`, `Entrega`, `ValidacionEntrega` |

## Configuración operativa

### `alimentacion.VentanaRetiroServicio`

Configura una ventana de retiro por sede y servicio. Su clave es `IdVentanaRetiroServicio`; tiene FK a `organizacion.Sede`. Registra tipo de servicio, horas de inicio/fin y vigencia.

- Servicios permitidos: `DESAYUNO`, `ALMUERZO`, `CENA`.
- Las horas de inicio y fin deben ser distintas.
- El fin de vigencia debe ser posterior al inicio.
- El índice filtrado `IN_VentanaRetiroServicio_Abierta` permite una sola ventana abierta por sede y servicio.

La configuración de beacons y proximidad es transversal y se administra en el esquema `proximidad`.

## Planificación y menú

### `alimentacion.Planificacion`

Agrupa días de servicio elegidos libremente para una sede y controla su estado. Su clave es `IdPlanificacion`, con identificador público único y FK a `organizacion.Sede`.

- Estados: `BORRADOR`, `PUBLICADA_ABIERTA`, `PUBLICADA_CERRADA`, `CONSOLIDADA`, `ELIMINADA`.
- Conserva el colaborador registrador (`IdColaboradorRegistro`) y la vigencia lógica (`EstaActivo`); una planificación eliminada queda inactiva.
- `VersionRegistro` debe ser mayor que cero.
- Conserva el colaborador registrador (`IdColaboradorRegistro`) y la vigencia lógica (`EstaActivo`).
- Conserva `Nombre`, `FechaInicio` y `FechaFin` como período explícito para identificarla y listarla; el fin no puede ser anterior al inicio.
- Los días con servicio se definen mediante `Menu.FechaServicio`; no es obligatorio que todos los días del período tengan menú.

### `alimentacion.Menu`

Define un menú —o la indisponibilidad— para una planificación, fecha y tipo de servicio. Su clave es `IdMenu`; tiene FK a `Planificacion` e identificador público único.

- La combinación `IdPlanificacion`, `FechaServicio`, `TipoServicio` es única.
- Servicios permitidos: `DESAYUNO`, `ALMUERZO`, `CENA`.
- Si está disponible, exige nombre; si no lo está, no puede conservar nombre, descripción ni imagen.
- `VersionRegistro` debe ser mayor que cero.

### `alimentacion.ComponenteMenu`

Conserva componentes informativos ordenados de un menú. Su clave es `IdComponenteMenu` y tiene FK a `Menu`.

- La combinación `IdMenu` + `Orden` es única.
- El orden debe ser mayor que cero.
- Conserva el colaborador registrador (`IdColaboradorRegistro`) y la vigencia lógica (`EstaActivo`).

## Consolidación

### `alimentacion.ConsolidacionPlanificacion`

Registra el hecho irreversible de consolidar una planificación. Su clave es `IdConsolidacionPlanificacion`; tiene FKs a `Planificacion` y `rrhh.Colaborador`.

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

Representa la reserva individual de un colaborador para un servicio. Su clave es `IdReserva`; tiene FKs hacia `rrhh.Colaborador`, contexto de `Planificacion`/sede y contexto de `Menu`.

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

Confirma el retiro presencial normal. Su clave es `IdEntrega`; tiene FKs compuestas al contexto de reserva y QR, y FK a `rrhh.Colaborador` para el operador.

- Una entrega por reserva, por QR y por correlación.
- Métodos permitidos: `CAMARA` y `LECTOR_HID`.
- Conserva el contexto de sede, fecha y servicio, el operador y la fecha UTC de entrega.

### `alimentacion.ValidacionEntrega`

Registra la validación temporal previa al consumo del QR. Su clave es el UUID `ValidationId`; tiene FKs al par QR/reserva, reserva, operador y sede.

- Conserva solo `HashCodigo`; no persiste el QR en claro.
- Métodos permitidos: `CAMARA` y `LECTOR_HID`.
- El vencimiento debe ser posterior a la creación y no exceder dos minutos.
- `IdCorrelacion` es único y el consumo no puede ocurrir antes de la creación.

## Relaciones principales

```text
Sede ──< VentanaRetiroServicio
Sede ──< Planificacion ──< Menu ──< ComponenteMenu
                              │
Planificacion ── 0..1 ConsolidacionPlanificacion ──< CantidadConsolidadaMenu
                              │
Colaborador ──< Reserva >── Menu
                    │
                    ├──< CodigoQR ── 0..1 Entrega
                    └──< ValidacionEntrega

Colaborador ──< ConsolidacionPlanificacion, Entrega, ValidacionEntrega
```

## Límites conocidos

- Las migraciones no implementan procedures, vistas, funciones, triggers, roles ni permisos.
- Los límites transaccionales entre reserva, QR, validación, entrega y consolidación requieren un contrato de backend y objetos programables aprobados por separado.
- El módulo no determina el servicio a partir de `rrhh.HorarioLaboral.TipoTurno`; lo configura explícitamente por menú y fecha.
- No hay tablas de inventario, compras, recetas, costos, capacidad ni reportes materializados.

## Referencias

- `db/migrations/alimentacion/009_crear_schema_y_configuracion_alimentacion.sql` a `013_crear_matriz_informativa_beacons.sql`.
- `docs-proyecto/alimentacion/Stores Procedures/usp_ListarPlanificaciones.md`, contrato de lectura del listado maestro.
- `docs-proyecto/alimentacion/Stores Procedures/usp_ObtenerResumenPlanificacion.md`, contrato del resumen de planificación.
- `docs-proyecto/alimentacion/Stores Procedures/usp_ListarMenusPlanificacionPorTipoServicio.md`, contrato del calendario de menús por tipo de servicio.
- `docs-proyecto/nucleo/TABLAS_NUCLEO.md`, para las tablas externas requeridas del núcleo común.
