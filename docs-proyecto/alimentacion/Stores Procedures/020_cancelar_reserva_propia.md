# `alimentacion.usp_CancelarReservaPropia`

## Propósito

Cancela una reserva propia activa del colaborador, conservando la fila de
`alimentacion.Reserva` para trazabilidad. No elimina la reserva, no modifica el
menú, la planificación, el QR ni la entrega, y nunca reactiva una reserva
cancelada.

## Firma

```sql
CREATE OR ALTER PROCEDURE [alimentacion].[usp_CancelarReservaPropia]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @IdReserva UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
```

`@IdReserva` es `Reserva.IdentificadorPublico`; el móvil no envía el
identificador interno `IdReserva`.

Ejemplo:

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_CancelarReservaPropia]
    @IdColaboradorCorporativo = '00000000-0000-0000-0000-000000000000',
    @IdReserva = '00000000-0000-0000-0000-000000000000',
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
SELECT @Codigo AS [Codigo], @Mensaje AS [Mensaje];
```

## Parámetros

- `@IdColaboradorCorporativo`: identidad corporativa UUID del colaborador,
  resuelta por el backend autenticado. Es obligatoria y se usa para comprobar
  propiedad.
- `@IdReserva`: GUID público de la reserva. Es obligatorio.
- `@Codigo` y `@Mensaje`: salidas del contrato estándar de procedures API.

## Recordset de éxito

Con `UPDATED` o `IDEMPOTENT_REPLAY` devuelve un único recordset con este orden:

| Columna | Origen / significado |
|---|---|
| `IdReserva` | `Reserva.IdentificadorPublico` |
| `IdMenu` | `Menu.IdentificadorPublico` |
| `IdPlanificacion` | `Planificacion.IdentificadorPublico` |
| `IdSede` | Sede registrada en la reserva |
| `FechaServicio` | Fecha de servicio registrada |
| `TipoServicio` | `DESAYUNO`, `ALMUERZO` o `CENA` |
| `Estado` | `CANCELADA` |
| `FechaCreacion` | Instante de creación de la reserva |
| `FechaModificacion` | Instante oficial de la cancelación, o su valor histórico en una repetición |

Los errores funcionales no devuelven recordset.

## Códigos y mensajes seguros

| Código | Mensaje seguro |
|---|---|
| `UPDATED` | `NULL` en `@Mensaje`; la reserva fue cancelada. |
| `IDEMPOTENT_REPLAY` | `La reserva ya estaba cancelada.` |
| `VALIDATION_ERROR` | `El colaborador y la reserva son obligatorios.` |
| `RESERVATION_NOT_FOUND` | `La reserva indicada no existe.` |
| `NOT_OWNER` | `La reserva no pertenece al colaborador indicado.` |
| `STATE_CONFLICT` | `La reserva se encuentra en un estado terminal y no puede cancelarse.` |
| `RESERVATIONS_CLOSED` | `La planificación ya no acepta cambios de reservas.` |
| `PLAN_CONSOLIDATED` | `La planificación ya fue consolidada.` |
| `INVALID_PLAN_STATE` | `La planificación no está abierta para cancelar reservas.` |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` |

En una carrera que impida la actualización se devuelve `STATE_CONFLICT` de
forma segura; si la lectura protegida observa que la reserva ya es
`CANCELADA`, devuelve `IDEMPOTENT_REPLAY`.

## Reglas de propiedad y estado

La reserva se busca por su identificador público. Solo el colaborador cuyo
`Reserva.IdColaboradorCorporativo` coincide con `@IdColaboradorCorporativo` puede cancelarla.

Solo se cancela una reserva `RESERVADA` cuando la planificación asociada está
exactamente en `PUBLICADA_ABIERTA`. La reserva `CANCELADA` es un historial y
reproduce el resultado mediante `IDEMPOTENT_REPLAY`. Los estados `ENTREGADA` y
`NO_RECOGIDA` son terminales y devuelven `STATE_CONFLICT`.

Para una reserva `RESERVADA`, los estados de planificación se tratan así:

- `PUBLICADA_CERRADA` → `RESERVATIONS_CLOSED`.
- `CONSOLIDADA` → `PLAN_CONSOLIDATED`.
- `BORRADOR`, `ELIMINADA` u otro estado no permitido → `INVALID_PLAN_STATE`.

La actualización solo cambia `Reserva.Estado` a `CANCELADA` y
`Reserva.FechaModificacion` con `SYSDATETIME()`, la hora oficial vigente del
motor según la convención existente. La fila permanece conservada. Una reserva
futura para la misma fecha debe ser una nueva fila; este procedure no reactiva
la cancelada.

## Concurrencia y límites operativos

La operación usa una única transacción `TRY/CATCH`, con `UPDLOCK, HOLDLOCK` y
orden de bloqueo `Planificacion` → `Reserva`, consistente con cierre y
consolidación. Los estados se vuelven a leer dentro de los bloqueos y se
mantienen hasta el `UPDATE`, por lo que un cierre, consolidación o reintento
concurrente no puede producir una cancelación basada en un estado obsoleto.

No existen cupos ni lista de espera. Tampoco existe un corte fijo por hora:
la cancelación depende del estado manual de la planificación (`PUBLICADA_ABIERTA`);
las ventanas horarias corresponden a la operación de retiro y QR según la
configuración vigente.

Los detalles técnicos de errores inesperados se registran mediante
`auditoria.usp_RegistrarErrorProcedimiento` y nunca se exponen al consumidor.
