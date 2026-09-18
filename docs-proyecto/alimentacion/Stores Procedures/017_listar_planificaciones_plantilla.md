# Contrato — `alimentacion.usp_ListarPlanificacionesPlantilla`

## Propósito

Expone a sistemas consumidores un listado simple de las planificaciones
activas y consolidadas, para utilizarlas como plantillas de consulta de menús.
No incluye planificaciones no consolidadas, eliminadas ni información de sedes,
menús o reservas.

Script fuente: `db/migrations/alimentacion/Stores Procedures/017_listar_planificaciones_plantilla.sql`.

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ListarPlanificacionesPlantilla]
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Resultado

Devuelve un único recordset ordenado por fecha de inicio y fecha de fin
descendentes, nombre ascendente e identificador interno descendente. Puede estar
vacío si no existen planificaciones activas y consolidadas.

| Columna | Tipo SQL / lógico | Descripción |
|---|---|---|
| `IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de la planificación. |
| `Nombre` | `NVARCHAR(200)` | Nombre de la planificación. |
| `FechaInicio` | `DATE` | Primer día del período. |
| `FechaFin` | `DATE` | Último día del período. |

## Códigos de salida

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `OK` | `null` | Consulta ejecutada correctamente, incluso sin filas. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |
