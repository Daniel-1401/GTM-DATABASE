# Contrato backend — `alimentacion.usp_ListarPlanificaciones`

## Propósito

Procedimiento de solo lectura para el listado maestro paginado de planificaciones
de Alimentación. Devuelve exclusivamente la cabecera de cada planificación; no
incluye menús, componentes, reservas ni consolidaciones.

Script fuente: `db/migrations/alimentacion/Stores Procedures/001_listar_planificaciones.sql`.

## Ejecución

```sql
EXEC [alimentacion].[usp_ListarPlanificaciones]
    @IdSede = @IdSede,
    @Estado = @Estado,
    @FechaDesde = @FechaDesde,
    @FechaHasta = @FechaHasta,
    @TerminoBusqueda = @TerminoBusqueda,
    @NumeroPagina = @NumeroPagina,
    @TamanoPagina = @TamanoPagina;
```

Todos los filtros son opcionales. Una llamada sin parámetros devuelve la primera
página de todas las planificaciones activas. Las que tienen estado `ELIMINADA`
no se exponen mediante este procedimiento.

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Predeterminado | Contrato para backend |
|---|---|---:|---|---|
| `@IdSede` | `INT` | No | `NULL` | Filtra por sede. |
| `@Estado` | `NVARCHAR(25)` | No | `NULL` | Uno de: `BORRADOR`, `PUBLICADA_ABIERTA`, `PUBLICADA_CERRADA`, `CONSOLIDADA`. |
| `@FechaDesde` | `DATE` | No | `NULL` | Inicio inclusive del período de consulta. |
| `@FechaHasta` | `DATE` | No | `NULL` | Fin inclusive del período de consulta. |
| `@TerminoBusqueda` | `NVARCHAR(200)` | No | `NULL` | Texto contenido en `Nombre`. Una cadena vacía o con solo espacios se trata como `NULL`. |
| `@NumeroPagina` | `INT` | No | `1` | Página basada en uno. Debe ser mayor o igual a `1`. |
| `@TamanoPagina` | `INT` | No | `20` | Filas por página, entre `1` y `100`. |

### Semántica del período

Los filtros de fecha son de solapamiento, no solo por fecha de inicio. Una
planificación se devuelve cuando su intervalo inclusivo `[FechaInicio, FechaFin]`
intersecta el intervalo solicitado `[FechaDesde, FechaHasta]`.

## Recordsets de salida

Devuelve **un único recordset**. Las filas se ordenan por `FechaInicio DESC`,
`FechaFin DESC`, `Nombre ASC` e identificador interno descendente.

| Columna | Tipo lógico backend | Descripción |
|---|---|---|
| `IdPlanificacion` | UUID | Identificador público de la planificación. |
| `Nombre` | string | Nombre funcional de la planificación. |
| `IdSede` | integer | Identificador interno de la sede. |
| `CodigoSede` | string | Código de sede para el listado. |
| `NombreSede` | string | Nombre legible de la sede. |
| `FechaInicio` | date | Primer día del período, sin conversión horaria. |
| `FechaFin` | date | Último día del período, sin conversión horaria. |
| `CantidadDias` | integer | Días calendario inclusivos del período. |
| `Estado` | string | Estado actual de la planificación. |
| `VersionRegistro` | integer de 64 bits | Versión para control de concurrencia; devolverla si el cliente la necesitará en operaciones posteriores. |
| `FechaCreacionUtc` | timestamp UTC | Fecha de creación. |
| `FechaModificacionUtc` | timestamp UTC o `null` | Última modificación, si existe. |
| `TotalRegistros` | integer de 64 bits | Total de planificaciones que cumplen los filtros, antes de paginar. Se repite en cada fila de la página. |

Si no hay filas, el recordset está vacío y no contiene `TotalRegistros`.

## Manejo de errores

| Error SQL | Condición |
|---:|---|
| `50001` | `NumeroPagina < 1` |
| `50002` | `TamanoPagina` fuera de `1..100` |
| `50003` | Estado fuera del catálogo permitido |
| `50004` | `FechaDesde > FechaHasta` |
