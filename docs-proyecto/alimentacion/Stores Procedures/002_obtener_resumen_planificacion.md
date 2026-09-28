# Contrato — `alimentacion.usp_ObtenerResumenPlanificacion`

## Propósito

Obtiene la cabecera de una planificación, los conteos globales y el desglose por
tipo de servicio de menús y reservas para todo el período comprendido entre
`FechaInicio` y `FechaFin`.

Script fuente: `db/migrations/alimentacion/Stores Procedures/002_obtener_resumen_planificacion.sql`.

## Firma

```sql
@IdPlanificacion UNIQUEIDENTIFIER,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

## Contrato de salida

Firma adicional obligatoria: `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`. El recordset se describe más adelante.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `OK` | `null` | Consulta ejecutada correctamente. |
| `VALIDATION_ERROR` | `El identificador de planificación es obligatorio.` | No se recibió identificador. |
| `PLAN_NOT_FOUND` | `La planificacion indicada no existe.` | No existe una planificación activa con el identificador recibido. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

Usa `SET XACT_ABORT ON` y `TRY/CATCH`; no abre una transacción de escritura.

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ObtenerResumenPlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | Identificador público de la planificación. |

## Recordsets de salida

Incluye `IdColaboradorModificacionCorporativo` (`UUID` o `null`): referencia
corporativa de quien realizó la última modificación.

Devuelve dos recordsets cuando existe la planificación. No devuelve recordsets
en un error funcional. El primero conserva las columnas existentes y agrega el
total de reservas.

| Columna | Tipo SQL / lógico | Descripción |
|---|---|---|
| `IdPlanificacion` | `UNIQUEIDENTIFIER` / UUID | Identificador público de la planificación. |
| `Nombre` | `NVARCHAR(200)` / string | Nombre de la planificación. |
| `IdSede` | `INT` / integer | Identificador de la sede de la UO. |
| `CodigoSede` | string | Código de sede obtenido de `PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA.organizacion.Sede`. |
| `NombreSede` | string | Nombre de sede obtenido de `PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA.organizacion.Sede`. |
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
| `CantidadReservasRegistradas` | integer | Todas las filas de `Reserva` de la planificación, sin excluir estados. |

El segundo recordset devuelve una fila por tipo de servicio activo, incluso si
no existen menús ni reservas para ese tipo:

| Columna | Tipo SQL / lógico | Descripción |
|---|---|---|
| `TipoServicio`, `NombreTipoServicio`, `OrdenPresentacion` | string, string, integer | Identidad y orden de visualización del servicio. |
| `CantidadMenusRegistrados` | integer | Filas existentes en `Menu` para el servicio. |
| `CantidadMenusConfigurados` | integer | Menús con `EstaDisponible = 1`. |
| `CantidadServiciosSinAtencion` | integer | Registros con `EstaDisponible = 0`. |
| `CantidadReservasRegistradas` | integer | Todas las filas de `Reserva` del servicio, sin excluir estados. |

## Reglas de lectura

La ausencia del identificador se comunica mediante `VALIDATION_ERROR`. Los
números internos de SQL Server no forman parte del contrato API.
