# Catálogo oficial de tablas y objetos programables pendientes — Alimentación

Fecha: 2026-09-07
Motor objetivo: SQL Server 2017
Schema objetivo: `[alimentacion]`
Estado: las tablas descritas son oficiales; los objetos programables no están
definidos. La ejecución DDL sigue pendiente y ninguna tabla de este documento
se acredita como existente en una base de datos por evidencia de este
repositorio.

## 1. Propósito

Este documento describe las tablas oficiales del módulo. El catálogo refleja
las migraciones no ejecutadas `009`, `010`, `011` y `012`, que declaran las 12
tablas oficiales de Alimentación.

La planificación no es mensual: una fila de `Planificacion` puede contener
cualquier conjunto de fechas mediante `Menu.FechaServicio`. Las fechas no tienen
que ser consecutivas ni pertenecer al mismo mes.

La fuente de DDL sigue siendo `db/migrations/alimentacion`. Este documento no
autoriza ejecutar DDL ni define procedures, triggers, vistas, funciones o
permisos.

## 2. Objetos programables pendientes de definición

No se definen stores, triggers, vistas, funciones, permisos ni sus convenciones
de implementación. Cualquier referencia previa a nombres `usp_*` es un
antecedente no oficial y no puede ser consumida por Backend. Su definición
requerirá un contrato aprobado independiente del catálogo de tablas.

## 3. Dependencias del núcleo

Cuando el DDL se apruebe y ejecute, los futuros objetos programables podrán
consultar estas tablas del núcleo; no deben duplicarlas en `[alimentacion]`:

| Tabla | Uso | Clave referenciada |
|---|---|---|
| `organizacion.Sede` | Validar sede de planificación, ventanas, beacon, auditoría y entrega. | `IdSede` |
| `rrhh.Colaborador` | Resolver actor, colaborador que reserva y operador de entrega. | `IdColaborador` |

`rrhh.HorarioLaboral.TipoTurno` clasifica el horario como `MANANA`, `TARDE`,
`NOCHE` o `MADRUGADA`. Alimentación no lo relaciona ni lo usa para determinar
desayuno, almuerzo o cena: esos servicios los configura directamente el personal
en cada `Menu` por fecha.

## 4. Catálogo físico de tablas

### 4.1 Configuración operativa

#### `alimentacion.VentanaRetiroServicio`

- Propósito: ventana horaria de retiro por sede y tipo de servicio.
- PK: `IdVentanaRetiroServicio`.
- Columnas: `IdSede`, `TipoServicio`, `HoraInicio`, `HoraFin`,
  `FechaInicioVigencia`, `FechaFinVigencia`, `FechaCreacionUtc`.
- FK: `organizacion.Sede(IdSede)`.
- Reglas: una ventana abierta por sede y servicio; `HoraInicio` diferente de
  `HoraFin`; fin de vigencia posterior al inicio.

#### `alimentacion.BeaconAutorizado`

- Propósito: registrar el beacon permitido para una sede.
- PK: `IdBeaconAutorizado`.
- Columnas: `IdSede`, `IdentificadorUuid`, `NumeroMajor`, `NumeroMinor`,
  `EstaActivo`, `FechaCreacionUtc`, `FechaModificacionUtc`.
- FK: `organizacion.Sede(IdSede)`.
- Unicidad: `(IdentificadorUuid, NumeroMajor, NumeroMinor)`.
- Reglas: `NumeroMajor` y `NumeroMinor` entre 0 y 65535.

#### `alimentacion.ConfiguracionProximidadBeacon`

- Propósito: versionar los parámetros de detección y salida de un beacon.
- PK: `IdConfiguracionProximidadBeacon`.
- Columnas: `IdBeaconAutorizado`, `CantidadMinimaEmisiones`,
  `VentanaConfirmacionMilisegundos`, `TiempoSalidaRangoMilisegundos`,
  `UmbralRssi`, `FechaInicioVigenciaUtc`, `FechaFinVigenciaUtc`,
  `FechaCreacionUtc`.
- FK: `BeaconAutorizado(IdBeaconAutorizado)`.
- Reglas: una configuración abierta por beacon; cantidades y ventanas mayores
  que cero; RSSI nulo o entre -127 y 0.

### 4.2 Planificación y menú

#### `alimentacion.Planificacion`

- Propósito: agrupar días elegidos para una sede y controlar su estado/version.
- PK: `IdPlanificacion`.
- Columnas: `IdentificadorPublico`, `IdSede`, `Estado`, `VersionRegistro`,
  `FechaCreacionUtc`, `FechaModificacionUtc`.
- FK: `organizacion.Sede(IdSede)`.
- Unicidad: `IdentificadorPublico` y `(IdPlanificacion, IdSede)`.
- Estados: `BORRADOR`, `PUBLICADA_ABIERTA`, `PUBLICADA_CERRADA`, `CONSOLIDADA`.
- Importante: no contiene año, mes ni rango obligatorio.

#### `alimentacion.Menu`

- Propósito: definir el menú o la indisponibilidad de un servicio en una fecha.
- PK: `IdMenu`.
- Columnas: `IdentificadorPublico`, `IdPlanificacion`, `FechaServicio`,
  `TipoServicio`, `EstaDisponible`, `Nombre`, `Descripcion`,
  `ReferenciaImagen`, `VersionRegistro`, `FechaCreacionUtc`,
  `FechaModificacionUtc`.
- FK: `Planificacion(IdPlanificacion)`.
- Unicidad principal: `(IdPlanificacion, FechaServicio, TipoServicio)`.
- Reglas: menú disponible exige `Nombre`; no disponible no conserva contenido.

#### `alimentacion.ComponenteMenu`

- Propósito: componentes informativos ordenados de un menú.
- PK: `IdComponenteMenu`.
- Columnas: `IdMenu`, `Orden`, `DescripcionComponente`, `FechaCreacionUtc`.
- FK: `Menu(IdMenu)`.
- Unicidad: `(IdMenu, Orden)`; `Orden` mayor que cero.

### 4.3 Consolidación

#### `alimentacion.ConsolidacionPlanificacion`

- Propósito: registrar el hecho irreversible de consolidar una planificación.
- PK: `IdConsolidacionPlanificacion`.
- Columnas: `IdPlanificacion`, `IdActorColaborador`, `EstadoAnterior`,
  `VersionPlanificacion`, `FechaConsolidacionUtc`, `IdCorrelacion`.
- FK: `Planificacion`, `rrhh.Colaborador`.
- Unicidad: una consolidación por `IdPlanificacion`; `IdCorrelacion` único.
- Regla: `EstadoAnterior` debe ser `PUBLICADA_CERRADA`.

#### `alimentacion.CantidadConsolidadaMenu`

- Propósito: snapshot final de cantidades por menú al consolidar.
- PK: `(IdConsolidacionPlanificacion, IdMenu)`.
- Columnas: `IdConsolidacionPlanificacion`, `IdPlanificacion`, `IdMenu`,
  `CantidadReservas`.
- FK compuestas: consolidación `(IdConsolidacionPlanificacion, IdPlanificacion)`
  y menú `(IdMenu, IdPlanificacion)`.
- Regla: `CantidadReservas >= 0`; no reemplaza el conteo operativo de reservas.

### 4.4 Reserva, QR y entrega

#### `alimentacion.Reserva`

- Propósito: reserva individual de un colaborador para un servicio.
- PK: `IdReserva`.
- Columnas: `IdentificadorPublico`, `IdColaborador`, `IdPlanificacion`, `IdMenu`,
  `IdSede`, `FechaServicio`, `TipoServicio`, `Estado`, `FechaCreacionUtc`,
  `FechaModificacionUtc`.
- FK: colaborador, planificación/sede y menú/planificación/fecha/servicio.
- Unicidad contextual: `(IdReserva, IdPlanificacion, IdSede, FechaServicio,
  TipoServicio)`.
- Estados: `RESERVADA`, `CANCELADA`, `ENTREGADA`, `NO_RECOGIDA`.
- Índice filtrado: una reserva activa por colaborador y fecha.

#### `alimentacion.CodigoQR`

- Propósito: QR opaco de un solo uso asociado a una reserva.
- PK: `IdCodigoQR` (UUID).
- Columnas: `IdReserva`, `HashCodigo`, `Estado`, `FechaEmisionUtc`,
  `FechaVencimientoUtc`, `FechaUsoUtc`, `FechaRevocacionUtc`,
  `MotivoRevocacion`, `IdCorrelacion`.
- FK: `Reserva(IdReserva)`.
- Estados: `VIGENTE`, `VENCIDO`, `UTILIZADO`, `REVOCADO`.
- Reglas: vencimiento máximo de cinco minutos; solo un QR vigente por reserva;
  hash obligatorio y nunca valor claro.

#### `alimentacion.Entrega`

- Propósito: confirmar el retiro presencial normal.
- PK: `IdEntrega`.
- Columnas: `IdentificadorPublico`, `IdReserva`, `IdCodigoQR`,
  `IdOperadorColaborador`, `IdPlanificacion`, `IdSede`, `FechaServicio`,
  `TipoServicio`, `MecanismoLectura`, `FechaEntregaUtc`, `IdCorrelacion`.
- FK: contexto de reserva, QR/reserva y operador.
- Unicidad: una entrega por reserva, por QR y por correlación.
- `MecanismoLectura`: `CAMARA` o `LECTOR_HID`.

#### `alimentacion.ValidacionEntrega`

- Propósito: validación temporal previa al consumo del QR.
- PK: `ValidationId` (UUID).
- Columnas: `IdCodigoQR`, `IdReserva`, `IdOperadorColaborador`, `IdSede`,
  `MetodoLectura`, `FechaCreacionUtc`, `FechaVencimientoUtc`,
  `FechaConsumoUtc`, `IdCorrelacion`, `HashCodigo`.
- FK: QR/reserva, reserva, operador y sede.
- Reglas: vencimiento máximo de dos minutos; `CAMARA` o `LECTOR_HID`; hash sin QR
  en claro.

## 5. Límites y pendientes

- Este catálogo no demuestra compilación ni ejecución contra SQL Server; ninguna
  tabla ha sido creada por estos scripts.
- La carpeta `db/procedures` no define objetos oficiales y no debe ser consumida
  por Backend.
- No existen en este módulo tablas para inventario, compras, recetas, costos,
  cupos/capacidad ni reportes materializados.
- Antes de implementar Backend se requiere aprobar el contrato de endpoints,
  autorización de roles/sedes y, si corresponde, un checkpoint separado para
  definir objetos programables y para ejecutar DDL.
