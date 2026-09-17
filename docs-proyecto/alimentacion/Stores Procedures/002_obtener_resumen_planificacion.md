# Contrato — `alimentacion.usp_ObtenerResumenPlanificacion`

## Propósito

Obtiene la cabecera de una planificación y sus conteos globales de menús para
todo el período comprendido entre `FechaInicio` y `FechaFin`.

Script fuente: `db/migrations/alimentacion/Stores Procedures/002_obtener_resumen_planificacion.sql`.

## Ejecución

```sql
EXEC [alimentacion].[usp_ObtenerResumenPlanificacion]
    @IdPlanificacion = @IdPlanificacion;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | Identificador público de la planificación. |

## Recordsets de salida

Devuelve **un único recordset** con una fila cuando existe la planificación. Si
no existe, devuelve un recordset vacío.

| Columna | Tipo SQL / lógico | Descripción |
|---|---|---|
| `IdPlanificacion` | `UNIQUEIDENTIFIER` / UUID | Identificador público de la planificación. |
| `Nombre` | `NVARCHAR(200)` / string | Nombre de la planificación. |
| `IdSede` | `INT` / integer | Identificador de la sede. |
| `CodigoSede` | string | Código de la sede. |
| `NombreSede` | string | Nombre de la sede. |
| `FechaInicio` | `DATE` / date | Inicio inclusivo del período. |
| `FechaFin` | `DATE` / date | Fin inclusivo del período. |
| `CantidadDias` | integer | Días calendario inclusivos del período. |
| `Estado` | string | `BORRADOR`, `PUBLICADA_ABIERTA`, `PUBLICADA_CERRADA` o `CONSOLIDADA`. |
| `VersionRegistro` | `BIGINT` / integer de 64 bits | Versión de la planificación. |
| `CantidadMenusRegistrados` | integer | Filas existentes en `Menu`, sin importar disponibilidad. |
| `CantidadMenusCreados` | integer | Menús con `EstaDisponible = 1`. |
| `CantidadServiciosSinAtencion` | integer | Registros con `EstaDisponible = 0`. |
| `FechaCreacion` | `DATETIME2(3)` / timestamp local | Fecha de creación. |
| `FechaModificacion` | `DATETIME2(3)` / timestamp local o `null` | Fecha de última modificación. |

## Errores SQL

| Error SQL | Condición |
|---:|---|
| `50100` | `IdPlanificacion` es `NULL`. |
