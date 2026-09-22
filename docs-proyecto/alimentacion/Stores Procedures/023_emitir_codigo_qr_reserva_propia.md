# `alimentacion.usp_EmitirCodigoQRReservaPropia`

Emite o reemite de forma atomica un QR opaco para una reserva propia. El backend genera el valor claro, calcula `@HashCodigo` y entrega el valor claro al movil; SQL Server solo recibe y persiste el hash.

## Firma

```sql
@IdColaborador BIGINT,
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
    @IdColaborador = 1,
    @IdReserva = '00000000-0000-0000-0000-000000000001',
    @HashCodigo = 0x01020304,
    @IdCorrelacion = '00000000-0000-0000-0000-000000000002',
    @Codigo = @Codigo OUTPUT, @Mensaje = @Mensaje OUTPUT;
```

## Resultado

En `CREATED` o `IDEMPOTENT_REPLAY` devuelve solo `IdCodigoQR`, `IdReserva` publico, `Estado`, `FechaEmision`, `FechaVencimiento` y `VigenciaMinutos`. `VigenciaMinutos` se calcula por el store a partir de las fechas persistidas. Nunca devuelve hash, correlacion ni QR claro.

## Codigos

`CREATED`, `IDEMPOTENT_REPLAY`, `VALIDATION_ERROR`, `NOT_FOUND`, `PLAN_NOT_FOUND`, `RESERVATION_NOT_FOUND`, `NOT_OWNER`, `STATE_CONFLICT`, `INVALID_PLAN_STATE`, `CONFIGURATION_UNAVAILABLE`, `CONFLICT` e `INTERNAL_ERROR`.

Los mensajes no exponen detalles internos ni secretos. `INTERNAL_ERROR` se registra mediante la auditoria existente y usa el mensaje seguro estandar.

## Reglas y seguridad

- La reserva debe pertenecer al colaborador, estar `RESERVADA`, tener planificacion `CONSOLIDADA` y `FechaServicio` igual a la fecha oficial (`SYSDATETIME()`).
- El hash es obligatorio, no vacio y compatible con `VARBINARY(64)`. El store genera `FechaVencimiento` como cinco minutos posteriores al instante oficial de emision; el backend no puede proporcionarla.
- Debe existir una `VentanaRetiroServicio` vigente para sede, tipo y fecha, y el instante oficial debe estar dentro de ella. El modelo no define de forma segura una ventana que cruce medianoche (`HoraFin < HoraInicio`); por ello se rechaza con `CONFIGURATION_UNAVAILABLE`.
- Una emision nueva revoca el QR `VIGENTE` anterior de la misma reserva con motivo seguro `REEMISION` y crea uno nuevo, manteniendo maximo uno vigente.
- La correlacion se busca bajo bloqueos: repetida para la misma reserva devuelve `IDEMPOTENT_REPLAY`; vinculada a otra reserva devuelve `CONFLICT`. No existe unicidad fisica sobre `IdCorrelacion`, por lo que la garantia de idempotencia depende del bloqueo transaccional y no sustituye una restriccion unica.
- No valida BLE/proximidad ni crea `ValidacionEntrega`; esos pasos pertenecen a otros casos de uso.

La operacion usa una transaccion con bloqueos sobre planificacion, reserva y QR. Las violaciones concurrentes de unicidad de hash o QR se reconsultan y se devuelven como repeticion o conflicto cuando el estado permite determinarlo.
