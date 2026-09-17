# Contrato — `alimentacion.usp_CrearMenusPlanificacionLote`

## Propósito

Crea varios menús de una planificación en `BORRADOR` y sus componentes en una
única transacción. Si falla cualquier validación, no se crea ningún menú.

Scripts fuente: `db/migrations/alimentacion/015_crear_tipos_tabla_lote_menus.sql` y
`db/migrations/alimentacion/Stores Procedures/006_crear_menus_planificacion_lote.sql`.

## Contrato de salida

Firma adicional obligatoria: `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`. El recordset por menú creado se conserva sin
cambios.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `CREATED` | `null` | El lote fue creado de forma completa. |
| `VALIDATION_ERROR` | Mensaje de validación seguro | Lote, menús o componentes inválidos. |
| `BUSINESS_RULE_VIOLATION` | Mensaje de regla de negocio seguro | Servicio sin atención incompatible o fecha fuera del período. |
| `PLAN_NOT_FOUND` | `La planificación indicada no existe.` | No existe la planificación. |
| `INVALID_PLAN_STATE` | `La planificación no permite crear menús.` | La planificación no está en borrador. |
| `MENU_ALREADY_EXISTS` | Mensaje de conflicto seguro | El lote contiene un menú ya registrado. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

El lote y sus componentes se insertan en una sola transacción con
`SET XACT_ABORT ON` y `TRY/CATCH`; cualquier error posterior al inicio revierte
solo si `XACT_STATE() <> 0`. La existencia del colaborador no se valida aquí.

## Parámetros de entrada

| Parámetro | Tipo SQL | Descripción |
|---|---|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de una planificación en `BORRADOR`. |
| `@IdColaboradorRegistro` | `BIGINT` | Identificador que registra todos los menús y componentes del lote. |
| `@Menus` | `alimentacion.TipoMenuPlanificacionLoteCreacion READONLY` | Uno o más menús; cada fila debe tener un `IdReferencia` temporal único. |
| `@Componentes` | `alimentacion.TipoComponenteMenuLoteCreacion READONLY` | Componentes opcionales, asociados mediante `IdReferenciaMenu`. |

Cada fila de `@Menus` contiene `IdReferencia`, `FechaServicio`, `TipoServicio`,
`EstaDisponible`, `Nombre`, `Descripcion` y `ReferenciaImagen`. Cada fila de
`@Componentes` contiene `IdReferenciaMenu`, `Orden` y `DescripcionComponente`.

## Salida

Devuelve una fila por menú creado, incluyendo `IdReferenciaMenu` para que el
backend relacione cada fila enviada con su UUID público `IdMenu` resultante.

## Errores SQL

Los códigos funcionales posibles son `VALIDATION_ERROR`,
`BUSINESS_RULE_VIOLATION`, `PLAN_NOT_FOUND`, `INVALID_PLAN_STATE`,
`MENU_ALREADY_EXISTS` e `INTERNAL_ERROR`, conforme a la tabla anterior.
