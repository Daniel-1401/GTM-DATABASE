# Contrato — `alimentacion.usp_ListarMenusPlanificacionPorTipoServicio`

## Propósito

Lista todos los días del período de una planificación para un tipo de servicio específico o para **todos** los tipos de servicio. Incluye las fechas que aún no tienen una fila registrada en `Menu`.

El popup de configuración por rango usa este store con el tipo de servicio
seleccionado para identificar las fechas ya configuradas: `TieneMenu = 1`.
No requiere un store adicional de disponibilidad.

Script fuente: `db/migrations/alimentacion/Stores Procedures/003_listar_menus_planificacion_por_tipo_servicio.sql`.

## Contrato de salida

Firma adicional obligatoria: `@Codigo NVARCHAR(50) OUTPUT` y `@Mensaje NVARCHAR(500) OUTPUT`. Mantiene sin cambios el recordset existente.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `OK` | `null` | Consulta ejecutada correctamente, incluso si no existe la planificación. |
| `VALIDATION_ERROR` | Mensaje de validación seguro | Identificador ausente o tipo de servicio inválido. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ListarMenusPlanificacionPorTipoServicio]
    @IdPlanificacion = @IdPlanificacion,
    @TipoServicio = N'TODOS', -- o DESAYUNO, ALMUERZO, CENA
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Valores / descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | Identificador público de la planificación. |
| `@TipoServicio` | `NVARCHAR(20)` | Sí | Código activo de `alimentacion.TipoServicio` o `TODOS`. `TODOS` lista los menús de todos los tipos. Se eliminan espacios externos y el valor se normaliza a mayúsculas. |

## Recordsets de salida

Devuelve un único recordset ordenado por `FechaServicio` y orden de servicio.
Para un tipo específico devuelve una fila por cada fecha del período. Con
`TODOS` devuelve la matriz completa fecha × tipo de servicio activo, incluso
cuando no existe un menú. Si la planificación no existe, devuelve un recordset
vacío.

| Columna | Tipo SQL / lógico | Descripción |
|---|---|---|
| `FechaServicio` | `DATE` / date | Día del período de planificación. |
| `TipoServicio`, `NombreTipoServicio`, `OrdenPresentacion` | string, string, integer | Identidad y orden de visualización del servicio de la fila. |
| `TieneMenu` | `BIT` / boolean | `0` cuando no existe fila `Menu`; `1` cuando existe. |
| `IdMenu` | `UNIQUEIDENTIFIER` / UUID o `null` | Identificador público del menú; `null` si no existe fila. |
| `EstaDisponible` | `BIT` / boolean o `null` | `null` sin fila `Menu`; `0` sin atención; `1` con menú disponible. |
| `Nombre`, `Descripcion`, `ReferenciaImagen` | string o `null` | Datos del menú. |
| `VersionRegistro` | `BIGINT` o `null` | Versión del menú. |
| `FechaCreacion`, `FechaModificacion` | `DATETIME2(3)` o `null` | Fechas de creación y modificación. |
| `CantidadReservasRegistradas` | integer | Total de filas `Reserva` vinculadas al menú, sin excluir estados; es `0` si no hay menú o reservas. |

## Estados de una fecha

| TieneMenu | EstaDisponible | Significado |
|---:|---:|---|
| `0` | `null` | No hay menú registrado para la fecha y tipo de servicio. |
| `1` | `0` | La fecha y tipo fueron registrados sin atención. |
| `1` | `1` | Existe un menú disponible. |

## Errores SQL

| Error SQL | Condición |
|---:|---|
| `50100` | `IdPlanificacion` es `NULL`. |
| `50101` | `TipoServicio` es nulo, vacío, inactivo, inexistente o distinto de `TODOS`. |
