# Contrato — `proximidad.usp_ObtenerConfiguracionBeaconsSede`

## Propósito

Obtiene las configuraciones de proximidad vigentes de una sede y los beacons
autorizados que las usan. El procedure entrega recordsets normalizados; el
backend es responsable de agruparlos y transformarlos al contrato de la app.

## Firma

```sql
CREATE OR ALTER PROCEDURE [proximidad].[usp_ObtenerConfiguracionBeaconsSede]
    @IdSede INT,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
```

## Parámetros

| Parámetro | Tipo | Descripción |
|---|---|---|
| `@IdSede` | `INT` | Sede cuya configuración se consulta. Debe ser mayor que cero y existir. |
| `@Codigo` | `NVARCHAR(50) OUTPUT` | Resultado de la operación. |
| `@Mensaje` | `NVARCHAR(500) OUTPUT` | Mensaje seguro asociado al resultado. |

## Recordsets de salida

Con `@Codigo = 'OK'`, el procedure devuelve siempre dos recordsets, incluso si
no existe una configuración vigente o no hay beacons asociados.

### 1. Configuraciones vigentes

Una fila por política vigente de la sede, determinada con `SYSDATETIME()` y el
intervalo `[FechaInicioVigencia, FechaFinVigencia)`.

| Columna | Descripción |
|---|---|
| `IdSede`, `EstaActivaSede` | Contexto y estado de la sede. |
| `IdConfiguracionProximidadBeacon`, `CodigoVersion` | Identificador interno y versión de la política. |
| `CantidadMinimaEmisiones` | Mínimo de observaciones. |
| `VentanaConfirmacionMilisegundos` | Ventana de observación. |
| `IntervaloEvaluacionMilisegundos` | Intervalo de evaluación. |
| `TiempoSalidaRangoMilisegundos` | Tiempo de salida de rango. |
| `UmbralRssi` | RSSI mínimo; puede ser nulo. |
| `FechaInicioVigencia`, `FechaFinVigencia` | Vigencia de la política. |

### 2. Beacons asociados

Una fila por beacon que referencia una configuración del primer recordset.

| Columna | Descripción |
|---|---|
| `IdSede`, `IdConfiguracionProximidadBeacon` | Claves para asociarlo con la política. |
| `IdBeaconAutorizado`, `ReferenciaBeacon` | Identificador interno y valor funcional `beaconRef`. |
| `DireccionMac` | MAC registrada, si aplica. |
| `IdentificadorUuid`, `NumeroMajor`, `NumeroMinor` | Identidad BLE del beacon. |
| `EstaActivoBeacon` | Estado operativo del beacon. |
| `IdMajorAreaBeacon`, `CodigoAreaFisica`, `NombreAreaFisica`, `UbicacionReferencia`, `Observacion` | Contexto físico del área major. |

## Códigos de salida

| Código | Mensaje seguro | Condición |
|---|---|---|
| `OK` | `NULL` | Lectura correcta; los recordsets pueden estar vacíos. |
| `VALIDATION_ERROR` | `La sede es obligatoria y debe ser válida.` | `@IdSede` es nulo o no es positivo. |
| `NOT_FOUND` | `La sede indicada no existe.` | No existe la sede solicitada. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado, registrado internamente. |

## Reglas relevantes

- Es una lectura: no modifica estado ni inicia transacciones de negocio.
- La existencia y el estado activo de la sede se consultan en `[PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA].[organizacion].[Sede]`, la fuente GI de sedes.
- No filtra beacons inactivos; devuelve `EstaActivoBeacon` para que el backend
  aplique el contrato de exposición correspondiente.
- `ReferenciaBeacon` es el valor para `beaconRef`; no se genera JSON en SQL.
