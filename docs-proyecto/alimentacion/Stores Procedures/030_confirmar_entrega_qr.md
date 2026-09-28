# `alimentacion.usp_ConfirmarEntregaQR`

## Proposito

Confirma una entrega presencial normal consumiendo una `ValidacionEntrega`
vigente. En una unica transaccion registra la entrega, consume la validacion y
el QR, y cambia la reserva a `ENTREGADA`.

## Firma

```sql
@ValidationId UNIQUEIDENTIFIER,
@IdSede INT,
@IdOperadorColaboradorCorporativo UNIQUEIDENTIFIER,
@IdCorrelacion UNIQUEIDENTIFIER,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

El backend resuelve el operador y la sede desde el contexto autenticado. La
aplicacion solo conserva el `ValidationId` recibido del paso de validacion.

## Parametros

| Parametro | Descripcion |
|---|---|
| `@ValidationId` | Identificador de la validacion temporal a consumir. |
| `@IdSede` | Sede autorizada del operador. |
| `@IdOperadorColaboradorCorporativo` | UUID corporativo del operador autenticado. |
| `@IdCorrelacion` | Clave de idempotencia de la confirmacion. |
| `@Codigo` | Codigo de resultado de salida. |
| `@Mensaje` | Mensaje seguro de salida. |

## Recordset de exito

En `CREATED` o `IDEMPOTENT_REPLAY` retorna exactamente una fila.

| Columna | Tipo | Descripcion |
|---|---|---|
| `IdEntrega` | `UNIQUEIDENTIFIER` | Identificador publico de la entrega. |
| `ValidationId` | `UNIQUEIDENTIFIER` | Validacion consumida para la entrega. |
| `EstadoReserva` | `NVARCHAR(20)` | `ENTREGADA`. |
| `EstadoQR` | `NVARCHAR(20)` | `UTILIZADO`. |

## Codigos y mensajes seguros

| Codigo | Mensaje |
|---|---|
| `CREATED` | `La entrega fue confirmada correctamente.` |
| `IDEMPOTENT_REPLAY` | `La entrega ya habia sido confirmada.` |
| `VALIDATION_ERROR` | `Los datos de confirmacion son obligatorios y validos.` |
| `DELIVERY_VALIDATION_NOT_FOUND` | `La validacion de entrega no existe.` |
| `DELIVERY_VALIDATION_EXPIRED` | `La validacion de entrega ya vencio.` |
| `SITE_FORBIDDEN` | `La validacion no corresponde a la sede indicada.` |
| `FORBIDDEN` | `El operador no puede confirmar esta validacion.` |
| `QR_REVOKED` | `El codigo QR fue revocado.` |
| `QR_ALREADY_USED` | `El codigo QR ya fue utilizado.` |
| `QR_EXPIRED` | `El codigo QR ya vencio.` |
| `STATE_CONFLICT` | `La validacion ya fue consumida.`, `La validacion ya no esta disponible.` o `La reserva no puede confirmarse desde su estado actual.` |
| `ALREADY_DELIVERED` | `La reserva ya fue entregada.` |
| `CONFIGURATION_UNAVAILABLE` | `No existe una ventana de retiro valida para la reserva.` |
| `IDEMPOTENCY_CONFLICT` | `La correlacion ya esta vinculada a otra entrega.` |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` |

## Reglas relevantes

- La confirmacion no recibe el hash del QR ni el metodo de lectura: ambos se
  obtienen de la validacion persistida.
- La validacion debe pertenecer al operador y a la sede recibidos, no estar
  consumida y no haber vencido.
- Antes de mutar, se vuelve a comprobar el QR, la reserva, la planificacion y
  la ventana de retiro con la hora oficial de SQL Server.
- El consumo de la validacion, la insercion de `Entrega`, el consumo del QR y
  la transicion de la reserva ocurren en la misma transaccion.
- La misma correlacion devuelve el resultado idempotente solo si corresponde a
  la misma reserva, QR y operador; en otro caso retorna
  `IDEMPOTENCY_CONFLICT`.
- Los errores inesperados se auditan y devuelven unicamente `INTERNAL_ERROR`.
