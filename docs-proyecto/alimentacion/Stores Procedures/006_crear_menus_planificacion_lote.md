# Contrato — `alimentacion.usp_CrearMenusPlanificacionLote`

## Propósito

Crea varios menús de una planificación en `BORRADOR` y sus componentes en una
única transacción. Si falla cualquier validación, no se crea ningún menú.

Scripts fuente: `db/migrations/alimentacion/015_crear_tipos_tabla_lote_menus.sql` y
`db/migrations/alimentacion/Stores Procedures/006_crear_menus_planificacion_lote.sql`.

## Parámetros de entrada

| Parámetro | Tipo SQL | Descripción |
|---|---|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de una planificación en `BORRADOR`. |
| `@IdColaboradorRegistro` | `BIGINT` | Colaborador existente que registra todos los menús y componentes del lote. |
| `@Menus` | `alimentacion.TipoMenuPlanificacionLoteCreacion READONLY` | Uno o más menús; cada fila debe tener un `IdReferencia` temporal único. |
| `@Componentes` | `alimentacion.TipoComponenteMenuLoteCreacion READONLY` | Componentes opcionales, asociados mediante `IdReferenciaMenu`. |

Cada fila de `@Menus` contiene `IdReferencia`, `FechaServicio`, `TipoServicio`,
`EstaDisponible`, `Nombre`, `Descripcion` y `ReferenciaImagen`. Cada fila de
`@Componentes` contiene `IdReferenciaMenu`, `Orden` y `DescripcionComponente`.

## Salida

Devuelve una fila por menú creado, incluyendo `IdReferenciaMenu` para que el
backend relacione cada fila enviada con su UUID público `IdMenu` resultante.

## Errores SQL

Los códigos `50230` a `50243` cubren lote vacío, datos o componentes inválidos,
duplicados internos, planificación inexistente o fuera de `BORRADOR`, fechas
fuera del período y menús ya existentes.
