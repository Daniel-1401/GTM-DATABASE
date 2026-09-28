# `alimentacion.usp_ListarCalendarioReservableColaborador`

## Proposito

Alimenta el calendario mensual de almuerzos o servicios de un colaborador para
una sede seleccionada y un tipo de servicio resuelto previamente por el
backend. Devuelve exactamente una fila por cada fecha del mes solicitado,
incluidos los dias sin planificacion, menu o reserva. Cuando se indica
opcionalmente `@Dia`, devuelve solo la fila de ese dia del mes.

El procedimiento es de lectura: no abre una transaccion de negocio, no cambia
reservas ni planificaciones y no aplica cupos, listas de espera ni cortes
horarios fijos.

## Firma

```sql
CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarCalendarioReservableColaborador]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @IdSede INT,
    @Anio SMALLINT,
    @Mes TINYINT,
    @TipoServicio NVARCHAR(20),
    @Dia TINYINT = NULL,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
```

## Ejemplo de ejecucion

```sql
DECLARE @Codigo NVARCHAR(50),
        @Mensaje NVARCHAR(500);

EXEC [alimentacion].[usp_ListarCalendarioReservableColaborador]
    @IdColaboradorCorporativo = '00000000-0000-0000-0000-000000000000',
    @IdSede = 3,
    @Anio = 2026,
    @Mes = 9,
    @Dia = 21,
    @TipoServicio = N'almuerzo',
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;

SELECT @Codigo AS [Codigo], @Mensaje AS [Mensaje];
```

El resultado de datos se entrega como un unico recordset cuando `@Codigo =
N'OK'`. En errores funcionales no se devuelve recordset.

## Parametros

| Parametro | Tipo | Entrada/salida | Descripcion |
|---|---|---|---|
| `@IdColaboradorCorporativo` | `UNIQUEIDENTIFIER` | Entrada | Identidad corporativa UUID del colaborador, resuelta por el backend; debe ser no nula. |
| `@IdSede` | `INT` | Entrada | Sede seleccionada. Debe existir en `PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA.organizacion.Sede`. Se usa la convencion existente del proyecto: `IdSede` es el identificador numerico de la sede. |
| `@Anio` | `SMALLINT` | Entrada | Ano del calendario. Debe estar entre 1 y 9999 para `DATEFROMPARTS`. |
| `@Mes` | `TINYINT` | Entrada | Mes del calendario, entre 1 y 12. |
| `@Dia` | `TINYINT` | Entrada opcional | Dia especifico del mes a consultar. Si es `NULL`, se devuelve el mes completo; si tiene valor, debe existir en el mes y estar entre 1 y 31. |
| `@TipoServicio` | `NVARCHAR(20)` | Entrada | Codigo de `alimentacion.TipoServicio`; se normaliza con `UPPER(NULLIF(LTRIM(RTRIM(...)), N''))` y debe estar activo. |
| `@Codigo` | `NVARCHAR(50)` | Salida | Codigo estandar del resultado. |
| `@Mensaje` | `NVARCHAR(500)` | Salida | Mensaje seguro del resultado o `NULL` cuando corresponde. |

El backend autentica, autoriza al colaborador, valida la sede en la que puede
operar y resuelve el tipo de servicio aplicable. Este procedimiento no inventa
ni persiste reglas de autorizacion que el modelo actual no materializa.

## Codigos de salida y mensajes

| Codigo | Mensaje posible | Recordset |
|---|---|---|
| `OK` | `NULL` | Si. Devuelve el calendario completo. |
| `VALIDATION_ERROR` | `La identidad corporativa del colaborador es obligatoria.` | No. |
| `VALIDATION_ERROR` | `La sede es obligatoria.` | No. |
| `VALIDATION_ERROR` | `El año indicado no es válido para el calendario solicitado.` | No. |
| `VALIDATION_ERROR` | `El mes indicado debe estar entre 1 y 12.` | No. |
| `VALIDATION_ERROR` | `El día indicado debe estar entre 1 y 31.` | No. |
| `VALIDATION_ERROR` | `El día indicado no existe en el mes solicitado.` | No. |
| `VALIDATION_ERROR` | `El tipo de servicio es obligatorio.` | No. |
| `VALIDATION_ERROR` | `El tipo de servicio indicado no existe o está inactivo.` | No. |
| `NOT_FOUND` | `La sede indicada no existe.` | No. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | No. |

Los errores inesperados se registran mediante
`[auditoria].[usp_RegistrarErrorProcedimiento]`. El detalle interno no se
expone al cliente.

## Recordset

Siempre que la entrada sea valida, se devuelve una fila por cada dia del mes,
ordenada por `FechaServicio`; cuando se especifica `@Dia`, se devuelve solo la
fila de ese dia. Las claves de planificacion, menu y reserva son identificadores
publicos UUID; para sedes se mantiene la convencion fisica existente de `INT`.

| Columna | Tipo | Nulo | Descripcion |
|---|---|---:|---|
| `FechaServicio` | `DATE` | No | Dia del mes solicitado. |
| `FechaInicioSemana` | `DATE` | No | Lunes de la semana de `FechaServicio`. |
| `EsFechaActual` | `BIT` | No | 1 si la fecha coincide con la fecha oficial del servidor SQL; de lo contrario 0. |
| `EsPrimeraFechaRelevanteDelMes` | `BIT` | No | 1 solo en la primera fecha del mes con menu visible o reserva activa propia; de lo contrario 0. |
| `IdSede` | `INT` | No | Sede seleccionada en la solicitud. |
| `NombreSede` | `NVARCHAR(150)` | No | Nombre de la sede seleccionada. |
| `TipoServicio` | `NVARCHAR(20)` | No | Codigo normalizado del servicio solicitado. |
| `NombreTipoServicio` | `NVARCHAR(100)` | No | Nombre vigente del tipo de servicio. |
| `IdPlanificacion` | `UNIQUEIDENTIFIER` | Si | Identificador publico de la planificacion visible para la fecha. |
| `EstadoPlanificacion` | `NVARCHAR(25)` | Si | `PUBLICADA_ABIERTA`, `PUBLICADA_CERRADA` o `CONSOLIDADA`, cuando existe contenido visible. |
| `IdMenu` | `UNIQUEIDENTIFIER` | Si | Identificador publico del menu visible. |
| `TieneMenu` | `BIT` | No | 1 si existe un menu activo visible para la fecha y servicio; de lo contrario 0. |
| `EstaDisponible` | `BIT` | Si | Disponibilidad persistida del menu. Es `NULL` si no existe menu visible. |
| `NombreMenu` | `NVARCHAR(200)` | Si | Nombre del menu. |
| `DescripcionMenu` | `NVARCHAR(1000)` | Si | Descripcion del menu. |
| `ReferenciaImagen` | `NVARCHAR(500)` | Si | Referencia persistida de la imagen del menu. |
| `IdReserva` | `UNIQUEIDENTIFIER` | Si | Identificador publico de la reserva activa del colaborador para la fecha. |
| `EstadoReserva` | `NVARCHAR(20)` | Si | `RESERVADA` cuando existe reserva activa; en otro caso `NULL`. |
| `IdSedeReservaActiva` | `INT` | Si | Sede de la reserva activa propia, si existe. Es obligatorio cuando la reserva pertenece a otra sede. |
| `NombreSedeReservaActiva` | `NVARCHAR(150)` | Si | Nombre de la sede de la reserva activa propia. |
| `EstadoCard` | `NVARCHAR(25)` | No | Estado funcional de la tarjeta. |
| `PuedeReservar` | `BIT` | No | 1 solo con menu activo y disponible, planificacion `PUBLICADA_ABIERTA` y sin reserva activa propia en ninguna sede. |
| `PuedeCancelar` | `BIT` | No | 1 solo para reserva propia en la sede seleccionada cuya planificacion sigue `PUBLICADA_ABIERTA`. |
| `PuedeGenerarQR` | `BIT` | No | 1 solo para reserva propia activa en la sede seleccionada, planificacion `CONSOLIDADA` y fecha igual a la fecha oficial del servidor. |

Los identificadores y datos de menu o planificacion pueden ser `NULL` si no
existe contenido visible para la fecha. Los campos de reserva son `NULL` si no
hay una reserva activa propia. Nunca se devuelven datos de reservas de otros
colaboradores.

## Reglas de lectura

1. Se genera el rango completo desde el primer hasta el ultimo dia del mes con
    una CTE recursiva y `MAXRECURSION 0`. Esto incluye correctamente febrero en
    anos bisiestos. Si `@Dia` tiene valor, se filtra el recordset final a esa
    fecha despues de calcular el calendario mensual; asi
    `EsPrimeraFechaRelevanteDelMes` conserva su significado mensual.
2. Solo se consideran menus activos de planificaciones activas en estados
   `PUBLICADA_ABIERTA`, `PUBLICADA_CERRADA` o `CONSOLIDADA`. Nunca se muestran
   menus de `BORRADOR` o `ELIMINADA`.
3. La busqueda del menu se limita a la sede, fecha y tipo de servicio
   solicitados. `EstaDisponible = 0` se conserva para distinguir un dia sin
   atencion de un dia no configurado.
4. La reserva activa se busca por `Reserva.IdColaboradorCorporativo` y fecha, sin filtrar por sede,
   usando exclusivamente `Reserva.Estado = N'RESERVADA'`. La unicidad filtrada
   existente en la base garantiza como maximo una fila activa por colaborador y
   fecha.
5. No se implementan cupos, listas de espera ni un corte horario fijo.

## Estados de card y precedencia

La precedencia aplicada es la siguiente:

1. `RESERVA_EN_OTRA_SEDE`: existe una reserva activa propia para la fecha y su
   sede es distinta de la sede solicitada. Se informa la sede de esa reserva.
2. `RESERVA_PROPIA`: existe una reserva activa propia en la sede seleccionada.
3. `NO_CONFIGURADO`: no existe menu activo visible para la fecha y servicio.
4. `SIN_ATENCION`: existe menu visible, pero `EstaDisponible = 0`.
5. `RESERVABLE`: el menu esta disponible, la planificacion esta
   `PUBLICADA_ABIERTA` y no existe reserva activa propia.
6. `RESERVAS_CERRADAS`: la planificacion esta `PUBLICADA_CERRADA`.
7. `CONSOLIDADA`: la planificacion esta `CONSOLIDADA`.

La reserva propia tiene prioridad incluso cuando exista contenido de la sede
seleccionada. La reserva activa en otra sede tambien bloquea `PuedeReservar`.

## Fecha relevante y fecha oficial

`EsPrimeraFechaRelevanteDelMes` se calcula despues de construir todas las filas
del mes. La fecha relevante es la primera que tiene un menu visible o cualquier
reserva activa propia del colaborador, incluida una reserva en otra sede. Si el
mes no tiene ninguna de esas condiciones, todas las filas llevan 0.

El repositorio define conceptualmente `America/Lima`, pero no contiene una
convencion SQL aprobada para convertir una zona IANA a la hora local en este
motor. Los objetos existentes usan `SYSDATETIME()`, por lo que este
procedimiento usa `CONVERT(DATE, SYSDATETIME())` como fecha oficial vigente del
servidor SQL. En consecuencia, `EsFechaActual` y `PuedeGenerarQR` dependen de
que la instancia SQL mantenga la hora oficial del proyecto. No se usa el reloj
del dispositivo ni el del cliente.

`PuedeGenerarQR` no emite ni modifica un QR; solo informa 1 cuando la reserva
propia sigue activa, su planificacion esta consolidada y `FechaServicio` es la
fecha oficial.

## Transacciones y seguridad

El SP no abre transacciones ni ejecuta `INSERT`, `UPDATE` o `DELETE` sobre las
tablas funcionales. Mantiene `SET NOCOUNT ON`, `SET XACT_ABORT ON` y el patron
estandar `TRY/CATCH`. En el `CATCH` registra el detalle interno en auditoria y
devuelve unicamente `INTERNAL_ERROR` con un mensaje seguro.
