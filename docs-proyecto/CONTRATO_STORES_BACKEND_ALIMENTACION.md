# Catálogo de tablas y solicitud de stores — Alimentación

Fecha: 2026-09-07  
Motor objetivo: SQL Server 2017  
Schema: `[alimentacion]`  
Estado: contrato de trabajo para Backend; revisión humana y ejecución DDL
pendientes.

## 1. Propósito

Este documento describe las tablas disponibles para que Backend solicite la
creación de stores para sus endpoints. El catálogo refleja las migraciones
`009`, `010`, `011`, `012` y `017` y contiene 15 tablas del módulo.

La planificación no es mensual: una fila de `Planificacion` puede contener
cualquier conjunto de fechas mediante `Menu.FechaServicio`. Las fechas no tienen
que ser consecutivas ni pertenecer al mismo mes.

La fuente ejecutable sigue siendo `db/migrations/alimentacion`. Este documento
no autoriza ejecutar DDL, crear procedures ni conceder permisos.

## 2. Convenciones obligatorias de los stores

- Usar transacciones explícitas para cada mutación de negocio.
- Recibir `IdCorrelacion` en operaciones mutables y escribir `EventoAuditoria`.
- Las mutaciones repetibles deben comenzar resolviendo `RegistroIdempotencia` por
  `ClaveIdempotencia` y comparar `HashSolicitud` antes de repetir efectos.
- No aceptar `Anio`, `Mes` ni una regla de fechas consecutivas. La fecha se toma
  de `Menu.FechaServicio`.
- Validar estado, sede, actor y pertenencia entre las claves compuestas antes
  de insertar o actualizar.
- No guardar QR en claro: `CodigoQR.HashCodigo` y
  `ValidacionEntrega.HashCodigo` almacenan únicamente el hash.
- Los nombres `usp_Alimentacion_*` que se proponen abajo son identificadores de
  trabajo; deben aprobarse con el contrato API antes de implementarse.

## 3. Dependencias del núcleo

Los stores pueden consultar estas tablas existentes, pero no deben duplicarlas
en `[alimentacion]`:

| Tabla | Uso | Clave referenciada |
|---|---|---|
| `organizacion.Sede` | Validar sede de planificación, ventanas, beacon, auditoría y entrega. | `IdSede` |
| `rrhh.Colaborador` | Resolver actor, colaborador que reserva y operador de entrega. | `IdColaborador` |
| `rrhh.HorarioLaboral` | Asociar la configuración de servicio al horario maestro. | `IdHorarioLaboral` |

## 4. Catálogo físico de tablas

### 4.1 Configuración operativa

#### `alimentacion.ConfiguracionServicioHorario`

- Propósito: asociar un horario laboral a `DESAYUNO`, `ALMUERZO` o `CENA`.
- PK: `IdConfiguracionServicioHorario`.
- Columnas: `IdHorarioLaboral`, `TipoServicio`, `FechaInicioVigencia`,
  `FechaFinVigencia`, `FechaCreacionUtc`.
- FK: `rrhh.HorarioLaboral(IdHorarioLaboral)`.
- Reglas: una configuración abierta por horario; fecha final nula o posterior a
  la inicial; tipo de servicio válido.

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

### 4.5 Soporte técnico y auditoría

#### `alimentacion.RegistroIdempotencia`

- Propósito: evitar efectos duplicados en mutaciones.
- PK: `IdRegistroIdempotencia`.
- Columnas: `ClaveIdempotencia`, `IdActorColaborador`, `Operacion`,
  `HashSolicitud`, `IdCorrelacion`, `EstadoProcesamiento`, `CodigoResultado`,
  `IdentificadorResultado`, `FechaRegistroUtc`, `FechaFinalizacionUtc`,
  `FechaExpiracionUtc`.
- FK: `rrhh.Colaborador(IdColaborador)`.
- Unicidad: `ClaveIdempotencia` e `IdCorrelacion`.
- Estados: `EN_PROCESO`, `COMPLETADO`, `FALLIDO`.

#### `alimentacion.EventoAuditoria`

- Propósito: evento funcional minimizado, separado de logs técnicos.
- PK: `IdEventoAuditoria`.
- Columnas: `IdentificadorEvento`, `TipoEvento`, `FechaHoraOficialUtc`,
  `IdActorColaborador`, `AplicacionOrigen`, `RolContexto`, `TipoObjeto`,
  `IdentificadorObjeto`, `IdSede`, `TipoServicio`, `FechaNegocio`,
  `EstadoAnterior`, `EstadoResultante`, `Resultado`, `MotivoSeguro`,
  `FiltrosMinimizados`, `IdCorrelacion`, `HuellaIdempotencia`.
- FK opcionales: colaborador y sede.
- Resultados: `ACEPTADO` o `RECHAZADO`.
- No almacenar secretos, QR claro ni datos personales innecesarios.

## 5. Solicitud propuesta de stores por endpoint

Los siguientes nombres son una matriz de solicitud para Backend. El contrato
HTTP definitivo debe fijar autorización, paginación, códigos de error y DTOs.

| Área / endpoint lógico | Store solicitado | Tablas principales | Transacción |
|---|---|---|---|
| Configuración de servicio | `usp_Alimentacion_ConfigurarServicioHorario` | `ConfiguracionServicioHorario`, `HorarioLaboral` | Sí |
| Ventanas de retiro | `usp_Alimentacion_GestionarVentanaRetiro` | `VentanaRetiroServicio`, `Sede` | Sí |
| Beacons | `usp_Alimentacion_GestionarBeacon` | `BeaconAutorizado`, `Sede` | Sí |
| Proximidad | `usp_Alimentacion_GestionarProximidadBeacon` | `ConfiguracionProximidadBeacon`, `BeaconAutorizado` | Sí |
| Crear/listar planificación | `usp_Alimentacion_Planificacion_Guardar` / `_Listar` | `Planificacion` | Sí / lectura |
| Menús por fecha | `usp_Alimentacion_Menu_Guardar` / `_Listar` | `Menu`, `ComponenteMenu`, `Planificacion` | Sí / lectura |
| Publicar/cerrar planificación | `usp_Alimentacion_Planificacion_CambiarEstado` | `Planificacion`, `EventoAuditoria` | Sí |
| Consolidar | `usp_Alimentacion_Planificacion_Consolidar` | `ConsolidacionPlanificacion`, `CantidadConsolidadaMenu`, `Planificacion`, `EventoAuditoria` | Sí |
| Crear/cancelar reserva | `usp_Alimentacion_Reserva_Crear` / `_Cancelar` | `Reserva`, `Menu`, `Planificacion`, `RegistroIdempotencia`, `EventoAuditoria` | Sí |
| Emitir/revocar QR | `usp_Alimentacion_QR_Emitir` / `_Revocar` | `CodigoQR`, `Reserva`, `RegistroIdempotencia`, `EventoAuditoria` | Sí |
| Validar QR | `usp_Alimentacion_Entrega_Validar` | `ValidacionEntrega`, `CodigoQR`, `Reserva`, `RegistroIdempotencia`, `EventoAuditoria` | Sí |
| Confirmar entrega | `usp_Alimentacion_Entrega_Confirmar` | `Entrega`, `Reserva`, `CodigoQR`, `EventoAuditoria` | Sí |
| Consulta de auditoría | `usp_Alimentacion_Auditoria_Listar` | `EventoAuditoria` | Lectura |

## 6. Contrato mínimo de entrada/salida para Backend

Cada store mutable debe documentar como mínimo:

1. Parámetros de actor (`IdActorColaborador`), sede, correlación e idempotencia.
2. Precondiciones de estado y ownership de las claves.
3. Tablas afectadas y orden de escritura.
4. Resultado (`CodigoResultado`, identificador público y estado resultante).
5. Errores de negocio: conflicto de versión, duplicidad, estado inválido,
   fecha/servicio inexistente, QR vencido o QR ya consumido.
6. Evento de auditoría emitido y huella de idempotencia asociada.

Las consultas de listado deben devolver DTOs estables y paginables; no deben
exponer directamente columnas internas que no formen parte del contrato.

## 7. Límites y pendientes

- Este catálogo no demuestra compilación ni ejecución contra SQL Server.
- La carpeta `db/procedures` no se modifica con este documento; sus stores deben
  solicitarse y revisarse contra este modelo corregido.
- No existen en este módulo tablas para inventario, compras, recetas, costos,
  cupos/capacidad ni reportes materializados.
- Antes de implementar Backend se requiere aprobación del contrato de endpoints,
  autorización de roles/sedes y un checkpoint separado para DDL/procedures.
