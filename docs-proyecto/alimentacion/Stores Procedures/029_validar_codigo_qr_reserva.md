# `alimentacion.usp_ValidarCodigoQRReserva`

## Proposito

Valida un QR opaco para el retiro presencial y crea una `ValidacionEntrega`
temporal, o reutiliza la vigente para el mismo QR, operador y sede. No consume
el QR ni registra una entrega.

## Firma

```sql
@HashCodigoQR VARBINARY(64),
@IdSede INT,
@IdOperadorColaboradorCorporativo UNIQUEIDENTIFIER,
@MetodoLectura NVARCHAR(20), -- CAMARA o LECTOR_HID
@IdCorrelacion UNIQUEIDENTIFIER,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

El backend obtiene el UUID corporativo del operador y su sede autorizada desde
la sesion. Calcula el hash del QR antes de invocar el procedure; SQL Server no
recibe ni persiste el QR en claro.

## Parametros

| Parametro | Descripcion |
|---|---|
| `@HashCodigoQR` | Hash no vacio del QR leido; admite hasta 64 bytes. |
| `@IdSede` | Sede autorizada en la que se produjo la lectura. |
| `@IdOperadorColaboradorCorporativo` | UUID corporativo del operador autenticado. |
| `@MetodoLectura` | `CAMARA` o `LECTOR_HID`. |
| `@IdCorrelacion` | Clave de idempotencia del intento de validacion. |
| `@Codigo` | Codigo de resultado de salida. |
| `@Mensaje` | Mensaje seguro de salida. |

## Recordset de exito

En `CREATED` o `IDEMPOTENT_REPLAY` retorna exactamente una fila.

| Columna | Tipo | Descripcion |
|---|---|---|
| `ValidationId` | `UNIQUEIDENTIFIER` | Identificador que debe recibirse para confirmar la entrega. |
| `IdReserva` | `UNIQUEIDENTIFIER` | Identificador publico de la reserva. |
| `FechaVencimiento` | `DATETIME2(3)` | Fin de la validacion temporal segun la hora oficial. |
| `NombreMenu` | `NVARCHAR(200)` o `null` | Nombre del menu reservado. |
| `TipoServicio` | `NVARCHAR(20)` | Tipo de servicio reservado. |
| `ReferenciaImagenMenu` | `NVARCHAR(500)` o `null` | Referencia de imagen del menu. |
| `IdColaboradorCorporativo` | `UNIQUEIDENTIFIER` | Identificador corporativo del titular de la reserva. |
| `NombreColaborador` | `NVARCHAR(200)` o `null` | Nombre completo del titular, aportado por la proyeccion corporativa autorizada. |
| `CargoColaborador` | `NVARCHAR(150)` o `null` | Cargo del titular en la sede de la reserva. |

El nombre se consulta antes de abrir la transaccion en la proyeccion corporativa
`[GSBEDEV01\CO].[PERSONALMANEGEMENTCORP].[rrhh].[vw_ColaboradorConsulta]`. El
cargo se obtiene de
`[PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA].[rrhh].[vw_ContextoOrganizacionalColaborador]`
para el UUID y la sede de la reserva. Si una proyeccion no tiene una fila,
devuelve el campo respectivo como `null`; si una dependencia no esta disponible,
se registra el detalle y se devuelve `INTERNAL_ERROR`.

## Codigos y mensajes seguros

| Codigo | Mensaje |
|---|---|
| `CREATED` | `La validacion de entrega fue creada correctamente.` |
| `IDEMPOTENT_REPLAY` | `Ya existe una validacion vigente para el retiro.` |
| `VALIDATION_ERROR` | `Los datos de validacion son obligatorios y validos.` |
| `IDEMPOTENCY_CONFLICT` | `La correlacion ya esta vinculada a otra validacion.` |
| `QR_NOT_FOUND` | `El codigo QR indicado no existe.` |
| `SITE_FORBIDDEN` | `El codigo QR no corresponde a la sede indicada.` |
| `QR_REVOKED` | `El codigo QR fue revocado.` |
| `QR_ALREADY_USED` | `El codigo QR ya fue utilizado.` |
| `QR_EXPIRED` | `El codigo QR ya vencio.` |
| `STATE_CONFLICT` | `La reserva no puede validarse para entrega.` o `La validacion ya fue consumida.` |
| `DELIVERY_VALIDATION_EXPIRED` | `La validacion de entrega ya vencio.` |
| `CONFIGURATION_UNAVAILABLE` | `No existe una ventana de retiro valida para la reserva.` |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` |

## Reglas relevantes

- La validacion se crea dentro de una transaccion con bloqueos sobre
  planificacion, reserva, QR y validacion, en ese orden.
- Su vencimiento es el menor entre dos minutos desde la validacion y el
  vencimiento del QR. El QR conserva su propia vigencia de hasta cinco minutos.
- Un reescaneo con otra correlacion reutiliza la validacion vigente del mismo
  QR, operador y sede. No crea otra fila ni elimina la existente.
- Un reintento con la misma correlacion devuelve la misma validacion mientras
  siga vigente y sin consumir. Una correlacion asociada a otro contexto retorna
  `IDEMPOTENCY_CONFLICT`.
- El QR debe estar `VIGENTE`; la reserva debe estar `RESERVADA`, corresponder a
  la fecha oficial y tener una planificacion `CONSOLIDADA` dentro de una ventana
  de retiro vigente.
- Los errores inesperados se registran mediante
  `auditoria.usp_RegistrarErrorProcedimiento` y solo se devuelve
  `INTERNAL_ERROR`.
