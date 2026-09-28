# `alimentacion.usp_ConfirmarEntregaQR`

## Propósito

Confirma una entrega presencial normal posterior a la validación visual del QR.
En una única transacción registra la entrega, consume el QR y cambia la reserva
a `ENTREGADA`.

## Firma

```sql
@HashCodigoQR VARBINARY(64),
@IdSede INT,
@IdOperadorColaborador BIGINT,
@MetodoLectura NVARCHAR(20), -- CAMARA o LECTOR_HID
@IdCorrelacion UNIQUEIDENTIFIER,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

El backend calcula el hash del QR y resuelve la identidad autenticada del
operador antes de ejecutar el procedure.

## Resultado

En `CREATED` o `IDEMPOTENT_REPLAY` devuelve `IdEntrega`, `EstadoReserva` y
`EstadoQR`. No devuelve el QR ni su hash.

## Códigos y mensajes seguros

| Código | Mensaje |
|---|---|
| `CREATED` | `La entrega fue confirmada correctamente.` |
| `IDEMPOTENT_REPLAY` | `La entrega ya habia sido confirmada.` |
| `VALIDATION_ERROR` | `Los datos de confirmacion son obligatorios y validos.` |
| `NOT_FOUND` | `El operador indicado no existe.` |
| `QR_NOT_FOUND` | `El codigo QR indicado no existe.` |
| `SITE_FORBIDDEN` | `El codigo QR no corresponde a la sede indicada.` |
| `QR_REVOKED` | `El codigo QR fue revocado.` |
| `QR_ALREADY_USED` | `El codigo QR ya fue utilizado.` |
| `QR_EXPIRED` | `El codigo QR ya vencio.` |
| `STATE_CONFLICT` | `La reserva no puede confirmarse desde su estado actual.` |
| `ALREADY_DELIVERED` | `La reserva ya fue entregada.` |
| `CONFIGURATION_UNAVAILABLE` | `No existe una ventana de retiro valida para la reserva.` |
| `IDEMPOTENCY_CONFLICT` | `La correlacion ya esta vinculada a otra entrega.` |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` |

## Reglas

- El QR debe estar vigente, no vencido y pertenecer a una reserva `RESERVADA`
  de la sede recibida, para la fecha oficial, con planificación consolidada y
  dentro de su ventana de retiro.
- Inserta una sola `Entrega`, cambia el QR a `UTILIZADO` y la reserva a
  `ENTREGADA` dentro de la misma transacción.
- `@IdCorrelacion` hace idempotente el reintento para la misma entrega; si se
  reutiliza con otra entrega retorna `IDEMPOTENCY_CONFLICT`.
- Los errores inesperados se auditan y devuelven únicamente `INTERNAL_ERROR`.
