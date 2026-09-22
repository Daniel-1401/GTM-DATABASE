# Contrato — `alimentacion.usp_CrearMenuPlanificacion`

## Propósito

Registra un menú —o un servicio sin atención— para una fecha y tipo de servicio
de una planificación en `BORRADOR`.

Script fuente: `db/migrations/alimentacion/Stores Procedures/005_crear_menu_planificacion.sql`.

## Contrato de salida

Firma adicional obligatoria: `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`. El recordset de creación se conserva sin
cambios.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `CREATED` | `null` | El menú fue creado. |
| `VALIDATION_ERROR` | Mensaje de validación seguro | Datos requeridos o servicio inválido. |
| `BUSINESS_RULE_VIOLATION` | Mensaje de regla de negocio seguro | Contenido incompatible o fecha fuera del período. |
| `PLAN_NOT_FOUND` | `La planificación indicada no existe.` | No existe la planificación. |
| `INVALID_PLAN_STATE` | `La planificación no permite crear menús.` | La planificación no está en borrador. |
| `MENU_ALREADY_EXISTS` | Mensaje de conflicto seguro | Ya existe menú para la fecha y servicio. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

La creación del menú es atómica con `SET XACT_ABORT ON` y `TRY/CATCH`; todo error después de iniciar la transacción hace rollback solo si
`XACT_STATE() <> 0`. La existencia del colaborador no se valida aquí.

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | UUID público devuelto al crear la planificación. |
| `@IdColaboradorRegistro` | `BIGINT` | Sí | Identificador que registra el menú. |
| `@MenuId` | `BIGINT` | Sí | Referencia externa que se persiste en `[alimentacion].[Menu].[MenuId]`. No se valida su existencia localmente porque pertenece a otra base de datos. |
| `@FechaServicio` | `DATE` | Sí | Debe estar dentro del período de la planificación. |
| `@TipoServicio` | `NVARCHAR(20)` | Sí | Código activo de `alimentacion.TipoServicio`. |
| `@EstaDisponible` | `BIT` | Sí | `1` para menú disponible; `0` para servicio sin atención. |
| `@Nombre` | `NVARCHAR(200)` | Condicional | Obligatorio si está disponible. |
| `@Descripcion` | `NVARCHAR(1000)` | No | Descripción del menú disponible. |
| `@ReferenciaImagen` | `NVARCHAR(500)` | No | Referencia opcional de imagen. |

Si `EstaDisponible = 0`, nombre, descripción e imagen deben estar vacíos. La combinación planificación, fecha y servicio se puede crear una sola vez.

## Salida

Devuelve una fila con el UUID público del menú, UUID de planificación, contenido,
vigencia, colaborador registrador, versión y fecha de creación local.

## Errores SQL

Los códigos funcionales posibles son `VALIDATION_ERROR`,
`BUSINESS_RULE_VIOLATION`, `PLAN_NOT_FOUND`, `INVALID_PLAN_STATE`,
`MENU_ALREADY_EXISTS` e `INTERNAL_ERROR`, conforme a la tabla anterior.
