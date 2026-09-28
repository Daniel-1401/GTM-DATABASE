# `alimentacion.usp_EmitirCodigoQRReservaPropia`

## Proposito

Emite o reemite de forma atomica un QR opaco para una reserva propia. El
backend genera el valor claro, calcula `@HashCodigo` y entrega el valor claro al
movil; SQL Server solo recibe y persiste el hash.

## Firma

```sql
@IdColaboradorCorporativo UNIQUEIDENTIFIER,
@IdReserva UNIQUEIDENTIFIER,
@HashCodigo VARBINARY(64),
@IdCorrelacion UNIQUEIDENTIFIER,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

Ejemplo ilustrativo (el hash es ficticio y no representa un QR real):

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_EmitirCodigoQRReservaPropia]
    @IdColaboradorCorporativo = '00000000-0000-0000-0000-000000000001',
    @IdReserva = '00000000-0000-0000-0000-000000000001',
    @HashCodigo = 0x01020304,
    @IdCorrelacion = '00000000-0000-0000-0000-000000000002',
    @Codigo = @Codigo OUTPUT, @Mensaje = @Mensaje OUTPUT;
```

## Parametros

| Parametro | Tipo | Entrada | Descripcion |
|---|---|---:|---|
| `@IdColaboradorCorporativo` | `UNIQUEIDENTIFIER` | Si | UUID corporativo autenticado del propietario de la reserva. |
| `@IdReserva` | `UNIQUEIDENTIFIER` | Si | Identificador publico de la reserva propia. |
| `@HashCodigo` | `VARBINARY(64)` | Si | Hash no vacio del QR generado por el backend; el QR claro nunca llega a SQL Server. |
| `@IdCorrelacion` | `UNIQUEIDENTIFIER` | Si | Identificador de idempotencia de la emision. |
| `@Codigo` | `NVARCHAR(50)` | Salida | Codigo seguro del resultado. |
| `@Mensaje` | `NVARCHAR(500)` | Salida | Mensaje seguro; es `NULL` solo cuando el resultado lo especifica. |

## Resultado

En `CREATED` o `IDEMPOTENT_REPLAY` devuelve solo `IdCodigoQR`, `IdReserva` publico, `Estado`, `FechaEmision`, `FechaVencimiento` y `VigenciaMinutos`. `VigenciaMinutos` se calcula por el store a partir de las fechas persistidas. Nunca devuelve hash, correlacion ni QR claro.

## Codigos y mensajes seguros

| Codigo | Mensaje seguro | Cuando ocurre |
|---|---|---|
| `CREATED` | `El QR fue emitido correctamente.` | Se emitio un QR nuevo. |
| `IDEMPOTENT_REPLAY` | `La emision ya habia sido procesada.` | La correlacion ya corresponde a la misma reserva. |
| `VALIDATION_ERROR` | `Los datos de emision son obligatorios y validos.` | Falta o es invalido un parametro obligatorio. |
| `RESERVATION_NOT_FOUND` | `La reserva indicada no existe.` | No existe la reserva recibida. |
| `NOT_OWNER` | `La reserva no pertenece al colaborador indicado.` | El UUID corporativo no es el propietario de la reserva. |
| `PLAN_NOT_FOUND` | `La planificacion de la reserva no existe.` | Falta la planificacion asociada. |
| `STATE_CONFLICT` | Mensaje seguro de estado o fecha oficial. | La reserva no esta disponible o no corresponde a la fecha oficial. |
| `INVALID_PLAN_STATE` | `La planificacion no esta consolidada para emitir el QR.` | La planificacion no esta consolidada. |
| `CONFIGURATION_UNAVAILABLE` | `No existe una ventana de retiro valida para la emision.` | No hay ventana de retiro utilizable. |
| `CONFLICT` | Mensaje seguro de correlacion o QR existente. | La correlacion pertenece a otra reserva o ocurre una colision concurrente. |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` | Error inesperado, registrado por auditoria. |

## Reglas y seguridad

- `@IdColaboradorCorporativo` es el UUID corporativo autenticado y autorizado que entrega el backend. El procedure no consulta la base de datos CO ni `rrhh`; compara ese UUID con `Reserva.IdColaboradorCorporativo`. La reserva debe pertenecer al colaborador, estar `RESERVADA`, tener planificacion `CONSOLIDADA` y `FechaServicio` igual a la fecha oficial (`SYSDATETIME()`).
- El hash es obligatorio, no vacio y compatible con `VARBINARY(64)`. El store genera `FechaVencimiento` como cinco minutos posteriores al instante oficial de emision; el backend no puede proporcionarla.
- Debe existir una `VentanaRetiroServicio` vigente para sede, tipo y fecha, y el instante oficial debe estar dentro de ella. El modelo no define de forma segura una ventana que cruce medianoche (`HoraFin < HoraInicio`); por ello se rechaza con `CONFIGURATION_UNAVAILABLE`.
- Una emision nueva revoca el QR `VIGENTE` anterior de la misma reserva con motivo seguro `REEMISION` y crea uno nuevo, manteniendo maximo uno vigente.
- La correlacion se busca bajo bloqueos: repetida para la misma reserva devuelve `IDEMPOTENT_REPLAY`; vinculada a otra reserva devuelve `CONFLICT`. No existe unicidad fisica sobre `IdCorrelacion`, por lo que la garantia de idempotencia depende del bloqueo transaccional y no sustituye una restriccion unica.
- No valida BLE/proximidad ni crea `ValidacionEntrega`; esos pasos pertenecen a otros casos de uso.

La operacion usa una transaccion con bloqueos sobre planificacion, reserva y QR. Las violaciones concurrentes de unicidad de hash o QR se reconsultan y se devuelven como repeticion o conflicto cuando el estado permite determinarlo.
