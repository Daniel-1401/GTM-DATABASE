# Contrato — `alimentacion.usp_ListarMenusPlanificacionPorTipoServicio`

## Propósito

Lista todos los días del período de una planificación para un único tipo de
servicio. Incluye los días que no tienen una fila registrada en `Menu`.

Script fuente: `db/migrations/alimentacion/Stores Procedures/003_listar_menus_planificacion_por_tipo_servicio.sql`.

## Contrato de salida

Firma adicional obligatoria: `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`. Mantiene sin cambios el recordset existente.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `OK` | `null` | Consulta ejecutada correctamente, incluso si no existe la planificación. |
| `VALIDATION_ERROR` | Mensaje de validación seguro | Identificador ausente o tipo de servicio inválido. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

Usa `SET XACT_ABORT ON` y `TRY/CATCH`; no abre una transacción de escritura.

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ListarMenusPlanificacionPorTipoServicio]
    @IdPlanificacion = @IdPlanificacion,
    @TipoServicio = @TipoServicio,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Valores / descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | Identificador público de la planificación. |
| `@TipoServicio` | `NVARCHAR(20)` | Sí | `DESAYUNO`, `ALMUERZO` o `CENA`. Se eliminan espacios externos y el valor se normaliza a mayúsculas. |

## Recordsets de salida

Devuelve **un único recordset** ordenado por `FechaServicio` ascendente. Si la
planificación no existe, devuelve un recordset vacío.

| Columna | Tipo SQL / lógico | Descripción |
|---|---|---|
| `FechaServicio` | `DATE` / date | Día del período de planificación. |
| `TipoServicio` | string | Tipo solicitado. |
| `TieneMenu` | `BIT` / boolean | `0` cuando no existe fila `Menu`; `1` cuando existe. |
| `IdMenu` | `UNIQUEIDENTIFIER` / UUID o `null` | Identificador público del menú. Es `null` si no existe fila. |
| `EstaDisponible` | `BIT` / boolean o `null` | `null` sin fila `Menu`; `0` sin atención; `1` con menú disponible. |
| `Nombre` | string o `null` | Nombre del menú disponible. |
| `Descripcion` | string o `null` | Descripción del menú. |
| `ReferenciaImagen` | string o `null` | Referencia de imagen del menú. |
| `VersionRegistro` | `BIGINT` / integer de 64 bits o `null` | Versión del menú. |
| `FechaCreacion` | `DATETIME2(3)` / timestamp local o `null` | Fecha de creación del menú. |
| `FechaModificacion` | `DATETIME2(3)` / timestamp local o `null` | Fecha de última modificación del menú. |

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
| `50101` | `TipoServicio` es nulo, vacío o distinto de los valores permitidos. |
