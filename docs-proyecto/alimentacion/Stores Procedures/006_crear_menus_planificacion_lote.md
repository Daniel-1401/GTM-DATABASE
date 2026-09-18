# Contrato — `alimentacion.usp_CrearMenusPlanificacionLote`

## Propósito

Configura el mismo menú para cada fecha de un rango de una planificación en
`BORRADOR`. Las fechas que ya poseen un menú para el tipo de servicio solicitado
se conservan sin cambios y se reportan como omitidas.

Script fuente: `db/migrations/alimentacion/Stores Procedures/006_crear_menus_planificacion_lote.sql`.

## Contrato de salida

Firma adicional obligatoria: `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `CREATED` | Resumen de menús creados y fechas omitidas. | El rango se procesó; puede no haber nuevas filas si todas las fechas ya estaban configuradas. |
| `VALIDATION_ERROR` | Mensaje de validación seguro. | Datos obligatorios, rango, tipo de servicio o contenido inválidos. |
| `BUSINESS_RULE_VIOLATION` | Mensaje de regla de negocio seguro. | El rango está fuera de la planificación o un servicio sin atención tiene contenido. |
| `PLAN_NOT_FOUND` | `La planificación indicada no existe.` | No existe la planificación. |
| `INVALID_PLAN_STATE` | `La planificación no permite crear menús.` | La planificación no está en `BORRADOR`. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_CrearMenusPlanificacionLote]
    @IdPlanificacion = @IdPlanificacion,
    @IdColaboradorRegistro = @IdColaboradorRegistro,
    @FechaInicio = '2026-09-08',
    @FechaFin = '2026-09-13',
    @TipoServicio = N'ALMUERZO',
    @EstaDisponible = 1,
    @Nombre = N'Pollo al horno',
    @Descripcion = N'Pollo al horno con acompañamiento.',
    @ReferenciaImagen = NULL,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Descripción |
|---|---|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de una planificación en `BORRADOR`. |
| `@IdColaboradorRegistro` | `BIGINT` | Colaborador que registra los menús creados. |
| `@FechaInicio`, `@FechaFin` | `DATE` | Rango inclusivo a configurar; debe pertenecer íntegramente al período de la planificación. |
| `@TipoServicio` | `NVARCHAR(20)` | Código activo de `alimentacion.TipoServicio`; se normaliza a mayúsculas. |
| `@EstaDisponible` | `BIT` | `1` para registrar el menú indicado; `0` para registrar el servicio sin atención. |
| `@Nombre` | `NVARCHAR(200)` | Obligatorio cuando `@EstaDisponible = 1`; debe ser `NULL` o vacío cuando vale `0`. |
| `@Descripcion` | `NVARCHAR(1000)` | Opcional para un servicio disponible; debe ser `NULL` o vacía cuando no hay atención. |
| `@ReferenciaImagen` | `NVARCHAR(500)` | Opcional para un servicio disponible; debe ser `NULL` o vacía cuando no hay atención. |

## Recordset de salida

En una ejecución exitosa devuelve una fila por fecha solicitada, ordenada de
forma ascendente. No devuelve datos ante un error funcional.

| Columna | Descripción |
|---|---|
| `FechaServicio`, `TipoServicio` | Fecha y tipo configurados. |
| `FueCreado` | `1` si el store insertó el menú; `0` si ya existía. |
| `Resultado` | `CREADO` u `OMITIDO_EXISTENTE`. |
| `IdMenu` | UUID público del menú creado o del menú existente que se preservó. |
| `EstaDisponible`, `Nombre`, `Descripcion`, `ReferenciaImagen` | Datos efectivos que quedaron para esa fecha. |
| `VersionRegistro`, `FechaCreacion` | Metadatos del menú efectivo. |

## Reglas transaccionales

La operación usa una única transacción con bloqueos de actualización y de rango.
Antes de cada inserción vuelve a verificar la combinación única
planificación–fecha–tipo de servicio. Por ello, una fecha ya configurada nunca
se actualiza ni elimina, incluso si el popup fue abierto antes de que otro
usuario configurara esa fecha.
