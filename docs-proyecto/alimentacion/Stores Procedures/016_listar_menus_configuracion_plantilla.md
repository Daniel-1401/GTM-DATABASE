# Contrato — `alimentacion.usp_ListarMenusConfiguracionPlantilla`

## Propósito

Expone para sistemas consumidores la configuración diaria de menús de una
planificación, ordenada por día y tipo de servicio, con el total de reservas
asociadas a cada menú.

Solo devuelve filas existentes en `alimentacion.Menu`; por ello no incluye días
o tipos de servicio aún no configurados. El conteo incluye todas las reservas,
sin filtrar por estado.

Script fuente: `db/migrations/alimentacion/Stores Procedures/016_listar_menus_configuracion_plantilla.sql`.

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ListarMenusConfiguracionPlantilla]
    @IdPlanificacion = @IdPlanificacion,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | UUID público de la planificación. |

## Resultado

Devuelve un único recordset ordenado por `FechaServicio`, `TipoServicio` e
identificador interno de menú. Si la planificación no existe, fue eliminada o
no tiene menús configurados, el recordset es vacío.

| Columna | Tipo SQL / lógico | Descripción |
|---|---|---|
| `FechaServicio` | `DATE` | Día configurado. |
| `TipoServicio` | `NVARCHAR(20)` | Tipo de servicio del menú. |
| `IdMenu` | `UNIQUEIDENTIFIER` | UUID público del menú. |
| `NombreMenu` | `NVARCHAR(200)` o `null` | Nombre del menú; es nulo para un servicio sin atención. |
| `CantidadReservas` | `BIGINT` | Total de reservas asociadas al menú, incluso canceladas, entregadas o no recogidas. |

## Códigos de salida

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `OK` | `null` | Consulta ejecutada correctamente, incluso sin menús. |
| `VALIDATION_ERROR` | Mensaje de validación seguro. | Falta `@IdPlanificacion`. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |
