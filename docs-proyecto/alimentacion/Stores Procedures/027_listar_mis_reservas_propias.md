# Contrato: `alimentacion.usp_ListarMisReservasPropias`

## Proposito

Devuelve las reservas activas propias del colaborador desde la fecha oficial
del servidor en adelante, para la opcion movil **Mis Reservas**. Solo incluye
filas con estado persistido `RESERVADA`; las reservas canceladas y las de fecha
anterior pertenecen a **Mi Historial**.

Es una lectura pura: no ejecuta DML ni abre transacciones de negocio. La
autenticacion y autorizacion corresponden al backend.

## Firma

```sql
CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarMisReservasPropias]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @NumeroPagina INT,
    @TamanoPagina INT,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
```

La paginacion es 1-based y el tamano permitido es de 1 a 100.

## Parametros

| Parametro | Tipo | Entrada/salida | Descripcion |
|---|---|---:|---|
| `@IdColaboradorCorporativo` | `UNIQUEIDENTIFIER` | Entrada | UUID corporativo del usuario autenticado, validado y suministrado por el backend. |
| `@NumeroPagina` | `INT` | Entrada | Pagina solicitada, mayor o igual a 1. |
| `@TamanoPagina` | `INT` | Entrada | Filas por pagina, entre 1 y 100. |
| `@Codigo` | `NVARCHAR(50)` | Salida | Codigo estandar del resultado. |
| `@Mensaje` | `NVARCHAR(500)` | Salida | Mensaje seguro; `NULL` cuando el resultado es `OK`. |

## Recordset de exito

Con `OK` devuelve un unico recordset, vacio si no hay reservas activas. Se
ordena por `FechaServicio` ascendente e identificador publico ascendente.

| Columna | Descripcion |
|---|---|
| `IdReserva`, `IdMenu`, `IdPlanificacion` | Identificadores publicos de la reserva y su contexto. |
| `IdSede`, `IdSedePublico`, `NombreSede` | Sede persistida de la reserva. |
| `FechaServicio`, `TipoServicio` | Fecha y tipo del servicio reservado. |
| `NombrePlanificacion`, `EstadoPlanificacion` | Datos persistidos de la planificacion asociada. |
| `NombreMenu`, `DescripcionMenu`, `ReferenciaImagenMenu` | Datos de presentacion del menu reservado. |
| `EstadoReserva` | Siempre `RESERVADA`. |
| `FechaCreacionReserva`, `FechaModificacionReserva` | Trazabilidad temporal persistida. |
| `PuedeCancelar` | `1` solo si la planificacion esta `PUBLICADA_ABIERTA`; es una elegibilidad de UI y la cancelacion vuelve a validar el estado. |

## Reglas de lectura

La fecha oficial se calcula una vez con `CONVERT(DATE, SYSDATETIME())`, segun
la convencion vigente. Filtra por `IdColaboradorCorporativo`, validado por el backend,
`FechaServicio >= FechaOficial` y `Estado = RESERVADA`. No muestra reservas de
otros colaboradores ni reservas canceladas, entregadas o no recogidas.

## Codigos y mensajes seguros

| Codigo | Mensaje seguro | Recordset |
|---|---|---|
| `OK` | `NULL` | Si, incluso vacio. |
| `VALIDATION_ERROR` | `El colaborador es obligatorio.` | No. |
| `INVALID_FILTER` | `La pagina debe ser mayor o igual a 1 y el tamano debe estar entre 1 y 100.` | No. |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` | No. |

Los errores inesperados se registran mediante
`[auditoria].[usp_RegistrarErrorProcedimiento]`; sus detalles no se exponen al
consumidor.
