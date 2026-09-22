# `alimentacion.usp_RevocarCodigoQRReservaPropia`

## Proposito

Revoca de forma atomica un codigo QR de una reserva propia. No elimina registros ni vuelve a emitir codigos QR.

## Firma

```sql
@IdColaborador BIGINT,
@IdCodigoQR UNIQUEIDENTIFIER,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

## Parametros

| Parametro | Descripcion |
|---|---|
| `@IdColaborador` | Identidad del colaborador autenticado; debe ser propietario de la reserva asociada al QR. |
| `@IdCodigoQR` | Identificador del QR a revocar, obtenido al emitirlo. |
| `@Codigo` | Codigo de resultado de salida. |
| `@Mensaje` | Mensaje seguro de salida. |

Ejemplo ilustrativo:

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_RevocarCodigoQRReservaPropia]
    @IdColaborador = 1,
    @IdCodigoQR = '00000000-0000-0000-0000-000000000001',
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Recordset de exito

En `UPDATED` o `IDEMPOTENT_REPLAY` devuelve una fila con `IdCodigoQR`, `IdReserva` publico, `Estado`, `FechaRevocacion` y `MotivoRevocacion`. No devuelve el hash ni el valor claro del QR.

## Codigos y mensajes seguros

| Codigo | Mensaje |
|---|---|
| `UPDATED` | `El codigo QR fue revocado correctamente.` |
| `IDEMPOTENT_REPLAY` | `El codigo QR ya estaba revocado.` |
| `VALIDATION_ERROR` | `El colaborador y el codigo QR son obligatorios.` |
| `NOT_FOUND` | `El colaborador indicado no existe.` |
| `QR_NOT_FOUND` | `El codigo QR indicado no existe.` |
| `RESERVATION_NOT_FOUND` | `La reserva asociada al codigo QR no existe.` |
| `NOT_OWNER` | `El codigo QR no pertenece al colaborador indicado.` |
| `QR_EXPIRED` | `El codigo QR ya vencio y no puede revocarse.` |
| `QR_ALREADY_USED` | `El codigo QR ya fue utilizado y no puede revocarse.` |
| `STATE_CONFLICT` | `El codigo QR no puede revocarse desde su estado actual.` o `El codigo QR cambio de estado y no puede revocarse.` |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` |

## Reglas y concurrencia

- Solo el propietario de la reserva asociada puede revocar el QR.
- Solo un QR en estado `VIGENTE` cambia a `REVOCADO`; se registra el instante oficial `SYSDATETIME()` y el motivo fijo seguro `REVOCACION_USUARIO`.
- Un QR que ya esta `REVOCADO` devuelve `IDEMPOTENT_REPLAY` con su estado persistido. Un QR `VENCIDO` o `UTILIZADO` no cambia de estado.
- La operacion bloquea primero la reserva y despues el QR, dentro de una transaccion. Los errores inesperados se auditan y devuelven exclusivamente `INTERNAL_ERROR`.
