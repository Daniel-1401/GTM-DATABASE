# Contrato — `alimentacion.usp_CrearPlanificacionBorrador`

## Propósito

Crea la cabecera de una planificación con estado inicial `BORRADOR`. El UUID
devuelto debe usarse al registrar sus menús.

Script fuente: `db/migrations/alimentacion/Stores Procedures/004_crear_planificacion_borrador.sql`.

## Firma

```sql
@IdSede INT,
@IdColaboradorRegistroCorporativo UNIQUEIDENTIFIER,
@Nombre NVARCHAR(200),
@FechaInicio DATE,
@FechaFin DATE,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

## Contrato de salida

Firma adicional obligatoria: `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`. El recordset de creación se conserva sin
cambios.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `CREATED` | `null` | La planificación fue creada. |
| `VALIDATION_ERROR` | Mensaje de validación seguro | Falta un dato requerido o el período es inválido. |
| `NOT_FOUND` | `La sede indicada no existe.` | No existe la sede recibida en la UO. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

La inserción se ejecuta de forma atómica con `SET XACT_ABORT ON` y `TRY/CATCH`.
Ante un error inesperado se revierte solo si `XACT_STATE() <> 0`. El backend
proporciona la identidad corporativa autorizada y el procedure valida la sede
contra `PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA.organizacion.Sede`.

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdSede` | `INT` | Sí | Sede existente de la UO. |
| `@IdColaboradorRegistroCorporativo` | `UNIQUEIDENTIFIER` | Sí | UUID corporativo de quien registra la planificación. |
| `@Nombre` | `NVARCHAR(200)` | Sí | Nombre funcional; se eliminan espacios externos. |
| `@FechaInicio` | `DATE` | Sí | Inicio inclusivo del período. |
| `@FechaFin` | `DATE` | Sí | Fin inclusivo; no puede ser anterior al inicio. |

## Salida

Devuelve una fila con `IdPlanificacion` (UUID público), sede, nombre, período,
estado `BORRADOR`, vigencia, UUID corporativo del registrador, versión y fecha de creación local.

## Reglas de salida

Los códigos funcionales y sus mensajes seguros están definidos en el contrato
de salida. El backend debe usar `@Codigo` y `@Mensaje`; los detalles internos
de SQL Server no se exponen.
