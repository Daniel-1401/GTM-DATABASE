# Contrato — `alimentacion.usp_CrearMenuPlanificacion`

## Propósito

Registra un menú —o un servicio sin atención— para una fecha y tipo de servicio
de una planificación en `BORRADOR`. Inserta sus componentes opcionales dentro de
la misma transacción.

Scripts fuente: `db/migrations/alimentacion/014_crear_tipo_tabla_componentes_menu.sql` y
`db/migrations/alimentacion/Stores Procedures/005_crear_menu_planificacion.sql`.

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | UUID público devuelto al crear la planificación. |
| `@IdColaboradorRegistro` | `BIGINT` | Sí | Colaborador existente que registra el menú y sus componentes. |
| `@FechaServicio` | `DATE` | Sí | Debe estar dentro del período de la planificación. |
| `@TipoServicio` | `NVARCHAR(20)` | Sí | `DESAYUNO`, `ALMUERZO` o `CENA`. |
| `@EstaDisponible` | `BIT` | Sí | `1` para menú disponible; `0` para servicio sin atención. |
| `@Nombre` | `NVARCHAR(200)` | Condicional | Obligatorio si está disponible. |
| `@Descripcion` | `NVARCHAR(1000)` | No | Descripción del menú disponible. |
| `@ReferenciaImagen` | `NVARCHAR(500)` | No | Referencia opcional de imagen. |
| `@Componentes` | `alimentacion.TipoComponenteMenuCreacion READONLY` | Sí | TVP con `Orden` y `DescripcionComponente`; puede enviarse vacío. |

Si `EstaDisponible = 0`, nombre, descripción, imagen y componentes deben estar
vacíos. La combinación planificación, fecha y servicio se puede crear una sola vez.

## Salida

Devuelve una fila con el UUID público del menú, UUID de planificación, contenido,
vigencia, colaborador registrador, versión y fecha de creación local.

## Errores SQL

Los códigos `50210` a `50224` cubren datos obligatorios, servicio inválido,
contenido inconsistente, componentes inválidos, planificación inexistente o
fuera de `BORRADOR`, fecha fuera del período y menú duplicado.
