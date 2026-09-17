# Contrato — `alimentacion.usp_EliminarPlanificacion`

## Propósito

Elimina lógicamente una planificación que se encuentre en `BORRADOR`. La
operación conserva la cabecera, sus menús, componentes y cualquier relación histórica: cambia
el estado a `ELIMINADA`, desactiva la planificación, sus menús y sus componentes, aumenta
la versión de los registros modificables y registra la fecha de modificación local.

Script fuente: `db/migrations/alimentacion/Stores Procedures/007_eliminar_planificacion.sql`.

## Ejecución

```sql
EXEC [alimentacion].[usp_EliminarPlanificacion]
    @IdPlanificacion = @IdPlanificacion;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | UUID público de la planificación que se retirará. |

## Reglas de negocio

- Solo una planificación con estado `BORRADOR` puede eliminarse.
- La transición es terminal: `BORRADOR` → `ELIMINADA`.
- La misma transacción desactiva los `Menu` y `ComponenteMenu` asociados; los menús también incrementan su versión y registran su fecha de modificación.
- El procedimiento usa bloqueo de actualización para serializar eliminaciones concurrentes sobre la misma planificación.
- Las planificaciones eliminadas quedan excluidas de los procedimientos de listado, resumen y consulta de menús activos.

## Salida

Devuelve un único recordset con una fila:

| Columna | Tipo lógico backend | Descripción |
|---|---|---|
| `IdPlanificacion` | UUID | Identificador público de la planificación eliminada. |
| `Estado` | string | Siempre `ELIMINADA`. |
| `VersionRegistro` | integer de 64 bits | Versión incrementada tras la eliminación lógica. |
| `FechaModificacion` | timestamp local | Instante local en que se realizó la eliminación. |

## Manejo de errores

| Error SQL | Condición |
|---:|---|
| `50250` | `IdPlanificacion` ausente. |
| `50251` | La planificación no existe. |
| `50252` | La planificación ya está eliminada. |
| `50253` | La planificación no está en estado `BORRADOR`. |
