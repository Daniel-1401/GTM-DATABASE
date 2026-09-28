# `alimentacion.usp_MarcarReservasNoRecogidas`

## Propósito y alcance

Procedimiento interno para backend/job autorizado. Marca masivamente e
idempotentemente reservas `RESERVADA` como `NO_RECOGIDA` cuando el servicio de
una planificación `CONSOLIDADA` ya terminó y no existe una fila en
`alimentacion.Entrega`. No se invoca desde móvil ni se expone como operación de
usuario.

## Firma

```sql
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

## Parametros

| Parametro | Tipo | Entrada | Descripcion |
|---|---|---:|---|
| `@Codigo` | `NVARCHAR(50)` | Salida | Codigo seguro del resultado. |
| `@Mensaje` | `NVARCHAR(500)` | Salida | Mensaje seguro; es `NULL` en `OK` o `UPDATED`. |

## Ejemplo

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_MarcarReservasNoRecogidas]
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
SELECT @Codigo AS [Codigo], @Mensaje AS [Mensaje];
```

## Tiempo oficial

El procedimiento captura `SYSDATETIME()` una sola vez y deriva de ese instante
`FechaOficial`, la hora usada para la ventana y `FechaModificacion`. Esta es la
convención vigente del repositorio. 

`HoraInicio` y `HoraFin` se interpretan como una ventana dentro del mismo día
solo cuando `HoraInicio < HoraFin`. No existe una regla física aprobada para
interpretar una ventana que cruce medianoche; una configuración nocturna se
omite como ventana ambigua y nunca se procesa especulativamente.

## Criterios de inclusión y exclusión

Se consideran únicamente reservas con:

- `Reserva.Estado = RESERVADA`;
- `Planificacion.Estado = CONSOLIDADA`;
- ninguna fila correspondiente en `alimentacion.Entrega`; y
- `FechaServicio` anterior a `FechaOficial`, o igual a la fecha oficial con
  exactamente una ventana vigente, no nocturna, cuya `HoraFin` ya ocurrió.

No se modifican reservas `CANCELADA`, `ENTREGADA`, `NO_RECOGIDA` o cualquier
otro estado, ni reservas futuras, ni `CodigoQR`, `Entrega`, `Menu`,
`Planificacion` o datos de otras entidades.

Para reservas de hoy, una configuración ausente se omite y se cuenta en
`CantidadOmitidaSinVentana`. Más de una ventana vigente, o una única ventana
nocturna, se omite y se cuenta en `CantidadOmitidaVentanaAmbigua`. Una ventana
única válida cuyo fin todavía no ocurrió permanece sin cambios y no se cuenta
como error de configuración.

## Concurrencia e idempotencia

La selección y el cambio de estado ocurren en una única transacción. Se usan
bloqueos `UPDLOCK, HOLDLOCK` sobre reservas y comprobaciones de entrega para
serializar la decisión con una entrega concurrente. El `UPDATE` vuelve a exigir
`RESERVADA` y ausencia de entrega. Una segunda ejecución no modifica filas ya
convertidas; si no hay candidatas, termina correctamente con `OK`.

## Recordset de salida

En éxito se devuelve un único recordset, sin reservas ni datos personales:

| Columna | Tipo | Semántica |
|---|---|---|
| `FechaOficial` | `DATE` | Fecha derivada del instante oficial capturado. |
| `CantidadMarcadaNoRecogida` | `INT` | Filas convertidas en esta ejecución. |
| `CantidadOmitidaSinVentana` | `INT` | Reservas de hoy sin ventana vigente. |
| `CantidadOmitidaVentanaAmbigua` | `INT` | Reservas de hoy con ventanas múltiples o nocturnas. |

## Códigos y mensajes

| Código | Mensaje |
|---|---|
| `UPDATED` | `NULL`; se marcó al menos una reserva. |
| `OK` | `NULL`; no hubo filas para cambiar. |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` |

Ante un error inesperado se registra el detalle mediante
`auditoria.usp_RegistrarErrorProcedimiento` y solo se devuelve el código y
mensaje seguros anteriores. No se ejecuta DDL ni se requiere alterar el modelo.
