# Contrato — `alimentacion.usp_ActualizarMenuPlanificacion`

## Propósito

Actualiza la fecha, tipo de servicio, disponibilidad y contenido de un menú de
una planificación en estado `BORRADOR`. El colaborador que registró el menú no
se modifica.

Script fuente: `db/migrations/alimentacion/Stores Procedures/015_actualizar_menu_planificacion.sql`.

## Firma

```sql
@IdPlanificacion UNIQUEIDENTIFIER,
@IdMenu UNIQUEIDENTIFIER,
@FechaServicio DATE,
@TipoServicio NVARCHAR(20),
@EstaDisponible BIT,
@Nombre NVARCHAR(200) = NULL,
@Descripcion NVARCHAR(1000) = NULL,
@ReferenciaImagen NVARCHAR(500) = NULL,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

## Contrato de salida

La firma termina con `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `UPDATED` | `null` | El menú fue actualizado. |
| `VALIDATION_ERROR` | Mensaje de validación seguro. | Falta un dato requerido, el tipo no es válido o falta nombre para un servicio disponible. |
| `BUSINESS_RULE_VIOLATION` | Mensaje de regla de negocio seguro. | El contenido no corresponde a la disponibilidad o la fecha queda fuera del período. |
| `PLAN_NOT_FOUND` | `La planificación indicada no existe.` | No existe la planificación. |
| `STATE_CONFLICT` | `La planificación ya fue eliminada.` | La planificación fue eliminada. |
| `INVALID_PLAN_STATE` | `La planificación no permite editar menús.` | La planificación no está en borrador. |
| `MENU_NOT_FOUND` | `El menú indicado no existe en la planificación.` | El menú no existe o no pertenece a la planificación. |
| `MENU_ALREADY_EXISTS` | Mensaje de conflicto seguro. | Otro menú ocupa la misma fecha y tipo de servicio. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | UUID público de la planificación en borrador. |
| `@IdMenu` | `UNIQUEIDENTIFIER` | Sí | UUID público del menú a editar. |
| `@FechaServicio` | `DATE` | Sí | Nueva fecha, dentro del período de la planificación. |
| `@TipoServicio` | `NVARCHAR(20)` | Sí | Código activo de `alimentacion.TipoServicio`. |
| `@EstaDisponible` | `BIT` | Sí | `1` para menú disponible; `0` para servicio sin atención. |
| `@Nombre` | `NVARCHAR(200)` | Condicional | Obligatorio si el servicio está disponible. |
| `@Descripcion` | `NVARCHAR(1000)` | No | Descripción opcional del menú disponible. |
| `@ReferenciaImagen` | `NVARCHAR(500)` | No | Referencia opcional de imagen. |

## Reglas de negocio

- Solo los menús de una planificación en `BORRADOR` pueden editarse.
- La fecha debe pertenecer al período de la planificación y el tipo debe estar activo.
- Si `EstaDisponible = 0`, nombre, descripción e imagen deben estar vacíos.
- La combinación planificación, fecha y tipo de servicio debe permanecer única.
- La operación bloquea planificación y menús involucrados durante la transacción,
  incrementa `VersionRegistro` y actualiza `FechaModificacion`.

## Salida

Devuelve una fila con los UUID públicos, contenido actualizado, vigencia,
`Menu.IdColaboradorRegistroCorporativo`, versión, fecha de creación y fecha de modificación.
