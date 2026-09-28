# Contrato: `alimentacion.usp_CrearReservaPropia`

## Propósito

Crea una reserva propia para un colaborador autenticado cuando el menú indicado
está activo, disponible y pertenece a una planificación `PUBLICADA_ABIERTA`.
El procedure deriva del menú la planificación, sede, fecha de servicio y tipo
de servicio. No recibe esos valores como parámetros.

El backend mantiene la autenticación y autorización; este procedure recibe el
UUID corporativo del colaborador ya resuelto por el backend.

## Firma

```sql
CREATE OR ALTER PROCEDURE [alimentacion].[usp_CrearReservaPropia]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @IdMenu UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
```

Ejemplo:

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);

EXEC [alimentacion].[usp_CrearReservaPropia]
    @IdColaboradorCorporativo = '00000000-0000-0000-0000-000000000000',
    @IdMenu = '00000000-0000-0000-0000-000000000000',
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;

SELECT @Codigo AS [Codigo], @Mensaje AS [Mensaje];
```

El ejemplo usa valores ilustrativos y no ejecuta ninguna operación por sí mismo
en este documento.

## Parámetros

| Parámetro | Tipo | Entrada | Descripción |
|---|---|---:|---|
| `@IdColaboradorCorporativo` | `UNIQUEIDENTIFIER` | Sí | Identidad corporativa UUID, resuelta por el backend autenticado; no puede ser `NULL`. |
| `@IdMenu` | `UNIQUEIDENTIFIER` | Sí | `Menu.IdentificadorPublico` del menú solicitado. |
| `@Codigo` | `NVARCHAR(50)` | Salida | Código seguro del resultado. |
| `@Mensaje` | `NVARCHAR(500)` | Salida | Mensaje seguro; es `NULL` en éxito. |

No se aceptan como entrada sede, planificación, fecha ni tipo de servicio.

## Recordset de éxito

Para `CREATED` e `IDEMPOTENT_REPLAY` se devuelve un único recordset con estas
columnas y orden:

| Columna | Tipo | Descripción |
|---|---|---|
| `IdReserva` | `UNIQUEIDENTIFIER` | `Reserva.IdentificadorPublico`. |
| `IdMenu` | `UNIQUEIDENTIFIER` | `Menu.IdentificadorPublico`. |
| `IdPlanificacion` | `UNIQUEIDENTIFIER` | `Planificacion.IdentificadorPublico`. |
| `IdSede` | `INT` | Sede derivada del menú mediante su planificación. |
| `FechaServicio` | `DATE` | Fecha persistida en el menú. |
| `TipoServicio` | `NVARCHAR(20)` | Tipo persistido en el menú. |
| `Estado` | `NVARCHAR(20)` | `RESERVADA`. |
| `FechaCreacion` | `DATETIME2(3)` | Fecha generada por el default de `Reserva`. |
| `FechaModificacion` | `DATETIME2(3)` nullable | Fecha de modificación, inicialmente `NULL`. |

En errores funcionales no se devuelve recordset.

## Códigos y mensajes seguros

| Código | Mensaje seguro | Resultado |
|---|---|---|
| `CREATED` | `NULL` | Reserva creada; devuelve el recordset de éxito. |
| `IDEMPOTENT_REPLAY` | `NULL` | Ya existía la reserva activa para el mismo menú; devuelve el recordset de éxito. |
| `VALIDATION_ERROR` | `La identidad corporativa del colaborador y el menu son obligatorios.` | Faltó un parámetro obligatorio. |
| `MENU_NOT_FOUND` | `El menu indicado no existe.` | No existe un menú con ese identificador público. |
| `SERVICE_NOT_AVAILABLE` | `El servicio no esta disponible para reserva.` | El menú está inactivo o no disponible. |
| `RESERVATIONS_CLOSED` | `Las reservas estan cerradas para esta planificacion.` | Planificación `PUBLICADA_CERRADA`. |
| `PLAN_CONSOLIDATED` | `La planificacion ya fue consolidada.` | Planificación `CONSOLIDADA`. |
| `INVALID_PLAN_STATE` | `La planificacion no permite crear reservas.` | Estado distinto de `PUBLICADA_ABIERTA`, incluidos `BORRADOR` y `ELIMINADA`. |
| `ACTIVE_RESERVATION_EXISTS` | `Ya existe una reserva activa del colaborador para la fecha indicada.` | Existe otra reserva `RESERVADA` para el colaborador y fecha, sin importar sede o servicio. |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` | Error inesperado; no expone detalles internos. |

## Reglas de negocio

1. El backend autentica, autoriza y resuelve la identidad corporativa; este
   procedure solo exige UUID no nulo y lo usa para propiedad y auditoría.
2. El menú se busca por `alimentacion.Menu.IdentificadorPublico`.
3. El menú debe estar activo y disponible.
4. La planificación se obtiene mediante `Menu.IdPlanificacion`; su sede se
   obtiene mediante `Planificacion.IdSede`. La fecha y el servicio se toman de
   `Menu.FechaServicio` y `Menu.TipoServicio`.
5. Solo se crea la reserva con planificación `PUBLICADA_ABIERTA`. No existen
   cupos, lista de espera ni corte horario fijo.
6. La nueva fila usa `Estado = RESERVADA` y deja que los defaults existentes de
   `Reserva` generen `IdentificadorPublico`, `FechaCreacion` y
   `FechaModificacion`.

### Unicidad entre sedes

Solo puede existir una reserva activa por `IdColaboradorCorporativo + FechaServicio`, sin
importar sede, planificación o tipo de servicio. La garantía física es el
índice único existente
`IN_Reserva_ActivaColaboradorFecha`, aplicado a filas con
`Estado = RESERVADA` y usando `(IdColaboradorCorporativo, FechaServicio)`. Por eso una reserva activa de otra sede también produce
`ACTIVE_RESERVATION_EXISTS`.

## Concurrencia

La creación es transaccional (`XACT_ABORT ON`, `TRY/CATCH`) y mantiene una
única transacción desde las validaciones bloqueadas hasta la inserción. El orden
de bloqueo de tablas GTM es `Planificacion` → `Menu` → `Reserva`. Una lectura inicial sin bloqueos obtiene el `IdPlanificacion` del menú público; dentro de la transacción se bloquea primero la planificación, luego se vuelve a leer y bloquear el menú y se valida otra vez su asociación; finalmente se consulta la reserva activa. La búsqueda usa `UPDLOCK`, `HOLDLOCK` y el índice único
único para proteger también el caso en que todavía no existe una fila.

Los errores SQL Server `2601` y `2627` se tratan como colisiones esperables: el
procedure vuelve a consultar la reserva activa. Si es del mismo menú devuelve
`IDEMPOTENT_REPLAY`; si es de otro menú devuelve
`ACTIVE_RESERVATION_EXISTS`. Otros errores se registran mediante la auditoría
interna y devuelven solamente `INTERNAL_ERROR`.

## Reintentos e idempotencia

Una repetición del mismo menú mientras su reserva `RESERVADA` siga existiendo
es funcionalmente idempotente y devuelve la reserva original sin insertar otra
fila. Si existe una reserva activa distinta para la misma fecha, el reintento
no devuelve recordset y produce `ACTIVE_RESERVATION_EXISTS`.

La idempotencia solo puede reconocerse mientras exista esa misma reserva activa.
El esquema actual no persiste una clave de idempotencia ni una correlación de
solicitud para este caso; por tanto, no se agregan parámetros, columnas ni
tablas para ampliar esa garantía.
