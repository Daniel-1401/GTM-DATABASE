# `alimentacion.usp_ObtenerResumenServicioHoyColaborador`

## Proposito

Entrega el resumen del servicio correspondiente a la fecha oficial del servidor
SQL para la pantalla inicial movil del colaborador. Busca exclusivamente su
reserva activa (`Estado = RESERVADA`) y devuelve siempre exactamente una fila,
incluyendo cuando no exista reserva para hoy.

El procedimiento es de lectura: no abre transacciones de negocio, no usa locks
de actualizacion, no ejecuta DML ni emite QR, valida proximidad o cambia estados.
La autenticacion y autorizacion pertenecen al backend.

## Firma

```sql
CREATE OR ALTER PROCEDURE [alimentacion].[usp_ObtenerResumenServicioHoyColaborador]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
```

Ejemplo:

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);

EXEC [alimentacion].[usp_ObtenerResumenServicioHoyColaborador]
    @IdColaboradorCorporativo = '00000000-0000-0000-0000-000000000001',
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;

SELECT @Codigo AS [Codigo], @Mensaje AS [Mensaje];
```

## Parametros

| Parametro | Tipo | Entrada/salida | Descripcion |
|---|---|---|---|
| `@IdColaboradorCorporativo` | `UNIQUEIDENTIFIER` | Entrada | UUID corporativo autenticado y autorizado por el backend. |
| `@Codigo` | `NVARCHAR(50)` | Salida | Codigo estandar del resultado. |
| `@Mensaje` | `NVARCHAR(500)` | Salida | Mensaje seguro; `NULL` cuando el resultado es `OK`. |

## Recordset

Con entrada valida devuelve exactamente una fila, ordenada de forma
determinista. Si no hay reserva activa, los campos contextuales de reserva,
menu, planificacion y sede son `NULL`; `TieneReservaHoy`, `PuedeCancelar`,
`PuedeGenerarQR` y `PuedeRecoger` valen `0`.

| Columna | Tipo | Nulo | Descripcion |
|---|---|---:|---|
| `FechaOficial` | `DATE` | No | Fecha oficial calculada una sola vez en el servidor SQL. |
| `IdReserva` | `UNIQUEIDENTIFIER` | Si | Identificador publico de `Reserva`. |
| `IdPlanificacion` | `UNIQUEIDENTIFIER` | Si | Identificador publico de `Planificacion`. |
| `IdMenu` | `UNIQUEIDENTIFIER` | Si | Identificador publico de `Menu`. |
| `IdSede` | `INT` | Si | Identificador numerico existente de `Sede`. |
| `IdSedePublico` | `UNIQUEIDENTIFIER` | Si | Identificador publico de `Sede`. |
| `NombreSede` | `NVARCHAR(150)` | Si | Nombre persistido de la sede. |
| `FechaServicio` | `DATE` | Si | Fecha de la reserva; coincide con `FechaOficial` cuando existe. |
| `TipoServicio` | `NVARCHAR(20)` | Si | `DESAYUNO`, `ALMUERZO` o `CENA`. |
| `EstadoReserva` | `NVARCHAR(20)` | Si | `RESERVADA` cuando existe reserva activa. |
| `EstadoPlanificacion` | `NVARCHAR(25)` | Si | Estado persistido de la planificacion. |
| `EstaDisponible` | `BIT` | Si | Disponibilidad persistida del menu. |
| `NombreMenu` | `NVARCHAR(200)` | Si | Nombre del menu para presentacion. |
| `DescripcionMenu` | `NVARCHAR(1000)` | Si | Descripcion del menu para presentacion. |
| `ReferenciaImagen` | `NVARCHAR(500)` | Si | Referencia persistida de imagen del menu. |
| `TieneReservaHoy` | `BIT` | No | `1` solo si existe reserva propia activa para la fecha oficial. |
| `PuedeCancelar` | `BIT` | No | `1` unicamente si existe la reserva y su planificacion esta `PUBLICADA_ABIERTA`. |
| `PuedeGenerarQR` | `BIT` | No | `1` unicamente si existe reserva activa de hoy y su planificacion esta `CONSOLIDADA`. Es elegibilidad preliminar; no valida ventana, proximidad ni emite QR. |
| `PuedeRecoger` | `BIT` | No | `1` unicamente si existe reserva activa de hoy y su planificacion esta `CONSOLIDADA`. No valida/crea QR ni modifica estado. |

Los identificadores publicos se exponen para reserva, planificacion, menu y
sede; `IdSede` se conserva adicionalmente como identificador numerico por la
convencion fisica vigente del modulo.

## Codigos y mensajes seguros

| Codigo | Mensaje seguro | Recordset |
|---|---|---|
| `OK` | `NULL` | Si, una fila. |
| `VALIDATION_ERROR` | `El colaborador es obligatorio.` | No. |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` | No. |

Los errores inesperados se registran mediante
`[auditoria].[usp_RegistrarErrorProcedimiento]`; el detalle interno no se
expone al cliente.

## Fecha oficial, filtros y limitaciones

La fecha oficial se obtiene una sola vez como `CONVERT(DATE, SYSDATETIME())`,
siguiendo la convencion vigente en los procedures del repositorio. El modelo
documenta `America/Lima`, pero no existe un mecanismo SQL aprobado para
convertir esa zona IANA en esta instancia; por ello el resultado depende de
que el reloj del servidor SQL mantenga la hora oficial del proyecto. La fecha
no se recibe del cliente.

La reserva se filtra por `IdColaboradorCorporativo`, `FechaServicio = FechaOficial` y
`Estado = RESERVADA`. La unicidad filtrada existente garantiza como maximo una
reserva activa por colaborador y fecha. El backend entrega el UUID corporativo autenticado y autorizado; el SP no consulta la base de datos CO ni `rrhh`. Nunca se consultan ni exponen reservas de otros colaboradores. Cuando existe la reserva, sus relaciones determinan
el menu, la planificacion y la sede devueltos.
