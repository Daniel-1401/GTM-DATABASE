# `alimentacion.usp_ValidarCodigoQRReserva`

## Propósito

Valida, sin modificar estado, un QR opaco asociado a una reserva para retiro en
una sede. Devuelve la información de presentación del colaborador y del menú
solo si el QR, la reserva y la ventana de retiro son válidos según la hora
oficial de SQL Server.

## Firma

```sql
@HashCodigoQR VARBINARY(64),
@IdSede INT,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

El backend convierte el valor QR leído a su hash antes de invocar el procedure.
SQL Server no recibe, persiste ni devuelve el QR en texto claro.

## Parámetros

| Parámetro | Descripción |
|---|---|
| `@HashCodigoQR` | Hash no vacío del QR leído; admite hasta 64 bytes. |
| `@IdSede` | Identificador interno de la sede en la que se produjo la lectura. |
| `@Codigo` | Código de resultado de salida. |
| `@Mensaje` | Mensaje seguro de salida. |

## Recordset de éxito

Cuando `@Codigo = OK`, retorna exactamente una fila.

| Columna | Tipo | Descripción |
|---|---|---|
| `NombreColaborador` | `NVARCHAR` | Nombres y apellidos del colaborador titular de la reserva. |
| `CodigoSAPColaborador` | `NVARCHAR(30)` | Código SAP del colaborador. |
| `CargoColaborador` | `NVARCHAR(150)` o `null` | Cargo de la relación laboral vigente en la sede de la reserva. |
| `Avatar` | `NVARCHAR(500)` o `null` | Siempre `null`: el modelo actual no persiste un avatar de colaborador. |
| `NombreMenu` | `NVARCHAR(200)` | Nombre del menú reservado. |
| `TipoServicio` | `NVARCHAR(20)` | Tipo de servicio de la reserva. |
| `ReferenciaImagenMenu` | `NVARCHAR(500)` o `null` | Referencia de imagen del menú. |

No se devuelve recordset para resultados funcionales distintos de `OK`.

## Códigos y mensajes seguros

| Código | Mensaje |
|---|---|
| `OK` | `null` |
| `VALIDATION_ERROR` | `El codigo QR y la sede son obligatorios y validos.` |
| `QR_NOT_FOUND` | `El codigo QR indicado no existe.` |
| `SITE_FORBIDDEN` | `El codigo QR no corresponde a la sede indicada.` |
| `QR_REVOKED` | `El codigo QR fue revocado.` |
| `QR_ALREADY_USED` | `El codigo QR ya fue utilizado.` |
| `QR_EXPIRED` | `El codigo QR ya vencio.` |
| `QR_INVALID` | `El codigo QR no es valido.` o `El codigo QR no es valido para el retiro actual.` |
| `ALREADY_DELIVERED` | `La reserva ya fue entregada.` |
| `STATE_CONFLICT` | `La reserva no puede retirarse desde su estado actual.` |
| `PLAN_NOT_FOUND` | `La planificacion de la reserva no existe.` |
| `CONFIGURATION_UNAVAILABLE` | `No existe una ventana de retiro valida para la reserva.` |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` |

## Reglas relevantes

- Es una lectura: no crea una entrega, no crea una validación temporal, no usa
  el QR y no actualiza estados de QR o reserva.
- El QR debe existir, estar `VIGENTE` y no haber superado `FechaVencimiento`
  frente a `SYSDATETIME()`.
- La reserva debe pertenecer a la sede indicada, estar `RESERVADA`, corresponder
  a la fecha oficial y tener una planificación `CONSOLIDADA`.
- Debe existir una `VentanaRetiroServicio` vigente para la sede, fecha y tipo de
  servicio; la hora oficial debe estar dentro de ella. Las ventanas que cruzan
  medianoche se consideran configuración no disponible, coherente con la
  emisión de QR existente.
- Para evitar duplicar cargos con relaciones laborales simultáneas, se expone el
  cargo de la relación vigente en la sede de la reserva con inicio más reciente.
- `Avatar` se devuelve como `NULL` tipado por decisión explícita: no
  hay una fuente física de avatar autorizada en el modelo actual.
- Los errores inesperados se registran mediante
  `auditoria.usp_RegistrarErrorProcedimiento` y solo se devuelve
  `INTERNAL_ERROR`.
