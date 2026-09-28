# Contrato: `alimentacion.usp_ListarHistorialReservasPropias`

## Proposito

Devuelve el historial paginado de reservas propias de un colaborador para la
aplicacion movil. Solo incluye reservas con fecha de servicio anterior a la
fecha oficial del servidor y estados persistidos `ENTREGADA`, `NO_RECOGIDA` o
`CANCELADA`; no calcula ni cambia estados.

Es una lectura pura: no ejecuta DML, no abre transacciones de negocio y no usa
SQL dinamico. El backend autentica y autoriza al colaborador antes de invocar el
procedure.

## Firma

```sql
CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarHistorialReservasPropias]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @NumeroPagina INT,
    @TamanoPagina INT,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
```

Ejemplo de la primera pagina:

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);

EXEC [alimentacion].[usp_ListarHistorialReservasPropias]
    @IdColaboradorCorporativo = '00000000-0000-0000-0000-000000000001',
    @NumeroPagina = 1,
    @TamanoPagina = 20,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;

SELECT @Codigo AS [Codigo], @Mensaje AS [Mensaje];
```

La paginacion usa `OFFSET/FETCH` de SQL Server 2017. La pagina es 1-based y el
tamano permitido es de 1 a 100.

## Parametros

| Parametro | Tipo | Entrada/salida | Descripcion |
|---|---|---:|---|
| `@IdColaboradorCorporativo` | `UNIQUEIDENTIFIER` | Entrada | UUID corporativo autenticado y autorizado por el backend. |
| `@NumeroPagina` | `INT` | Entrada | Numero de pagina, mayor o igual a 1. |
| `@TamanoPagina` | `INT` | Entrada | Cantidad solicitada por pagina, entre 1 y 100. |
| `@Codigo` | `NVARCHAR(50)` | Salida | Codigo estandar del resultado. |
| `@Mensaje` | `NVARCHAR(500)` | Salida | Mensaje seguro; es `NULL` cuando corresponde. |

## Recordset de exito

Con `@Codigo = N'OK'` se devuelve un unico recordset. Si no hay coincidencias,
el recordset es vacio y el codigo permanece `OK`.

| Columna | Tipo | Nulo | Descripcion |
|---|---|---:|---|
| `IdReserva` | `UNIQUEIDENTIFIER` | No | Identificador publico de la reserva. |
| `IdMenu` | `UNIQUEIDENTIFIER` | No | Identificador publico del menu. |
| `IdPlanificacion` | `UNIQUEIDENTIFIER` | No | Identificador publico de la planificacion. |
| `IdSede` | `INT` | No | Identificador de sede usado por las relaciones del modulo. |
| `IdSedePublico` | `UNIQUEIDENTIFIER` | No | Identificador publico disponible de la sede. |
| `NombreSede` | `NVARCHAR(150)` | No | Nombre persistido de la sede. |
| `FechaServicio` | `DATE` | No | Fecha del servicio reservado. |
| `TipoServicio` | `NVARCHAR(20)` | No | `DESAYUNO`, `ALMUERZO` o `CENA`. |
| `NombrePlanificacion` | `NVARCHAR(200)` | No | Nombre persistido de la planificacion. |
| `NombreMenu` | `NVARCHAR(200)` | Si | Nombre persistido del menu. |
| `DescripcionMenu` | `NVARCHAR(1000)` | Si | Descripcion persistida del menu. |
| `ReferenciaImagenMenu` | `NVARCHAR(500)` | Si | Referencia persistida de la imagen del menu. |
| `EstadoReserva` | `NVARCHAR(20)` | No | `ENTREGADA`, `NO_RECOGIDA` o `CANCELADA`. |
| `FechaCreacionReserva` | `DATETIME2(3)` | No | Fecha de creacion de la reserva. |
| `FechaModificacionReserva` | `DATETIME2(3)` | Si | Ultima fecha de modificacion de la reserva. |
| `IdEntrega` | `UNIQUEIDENTIFIER` | Si | Identificador publico de la entrega; solo para `ENTREGADA`. |
| `FechaEntrega` | `DATETIME2(3)` | Si | Fecha de entrega; es `NULL` para `NO_RECOGIDA` y `CANCELADA`. |

No se exponen identificadores internos transaccionales ni datos de otros
colaboradores. La entrega se relaciona por la reserva; el procedure no deduce
ni marca `NO_RECOGIDA`.

## Orden y estados

Las filas se ordenan de forma estable por `FechaServicio DESC` y luego por el
identificador publico de reserva `DESC`. Se incluyen exclusivamente reservas
con `FechaServicio < FechaOficial`, donde `FechaOficial` se calcula una vez con
`CONVERT(DATE, SYSDATETIME())`. Los estados incluidos son `ENTREGADA`,
`NO_RECOGIDA` y `CANCELADA`; se excluye `RESERVADA`, que corresponde a **Mis
Reservas** desde la fecha actual en adelante.

## Codigos de salida y mensajes seguros

| Codigo | Mensaje seguro | Recordset |
|---|---|---|
| `OK` | `NULL` | Si, incluso cuando no hay resultados. |
| `VALIDATION_ERROR` | `El colaborador es obligatorio.` | No. |
| `INVALID_FILTER` | `La pagina debe ser mayor o igual a 1 y el tamano debe estar entre 1 y 100.` | No. |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` | No. |

Los errores inesperados se registran mediante
`[auditoria].[usp_RegistrarErrorProcedimiento]`; los detalles internos no se
exponen.

## Limites transaccionales y de seguridad

El procedure solo lee las tablas funcionales y no abre transacciones. Mantiene
`SET NOCOUNT ON`, `SET XACT_ABORT ON`, no usa SQL dinamico y aplica la
paginacion despues del orden estable. `@IdColaboradorCorporativo` representa
el UUID corporativo que el backend entrega tras autenticar y autorizar al
usuario. El procedure no consulta la base de datos CO ni `rrhh`; si el
parámetro es nulo devuelve `VALIDATION_ERROR` con `El colaborador es
obligatorio.`
