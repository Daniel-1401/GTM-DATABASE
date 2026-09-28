# `alimentacion.usp_ListarHistorialRetiros`

## Proposito

Lista reservas y su resultado de retiro con los mismos filtros para el listado
paginado y la exportacion completa.

## Firma

```sql
@NombreColaborador NVARCHAR(200) = NULL,
@TipoServicio NVARCHAR(20) = NULL,
@EstadoRetiro NVARCHAR(20) = NULL,
@IdSede INT = NULL,
@Fecha DATE = NULL,
@FechaDesde DATE = NULL,
@FechaHasta DATE = NULL,
@Exportar BIT = 0,
@NumeroPagina INT = 1,
@TamanoPagina INT = 20,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

## Parametros, filtros y paginacion

- Todos los filtros son opcionales. `@Fecha` filtra un unico dia; no puede
  combinarse con `@FechaDesde` ni `@FechaHasta`. El rango es inclusivo.
- `@NombreColaborador` busca coincidencias parciales y literales en
  `NombreCompleto` de la vista corporativa `rrhh.vw_ColaboradorConsulta`.
  Los caracteres `%`, `_`, `[` y `\` se tratan como texto, no como comodines.
- `@TipoServicio` admite `DESAYUNO`, `ALMUERZO` o `CENA`.
- `@EstadoRetiro` admite `ENTREGADO`, `CANCELADO` o `SIN_ENTREGAR`.
- Con `@Exportar = 0`, pagina usando `@NumeroPagina` (desde uno) y
  `@TamanoPagina` (1 a 100). Con `@Exportar = 1`, ignora ambos valores y
  devuelve todas las filas que cumplen los mismos filtros.

## Recordset

Devuelve `IdReserva`, `IdEntrega`, `FechaServicio`, `TipoServicio`,
`EstadoReserva`, `EstadoRetiro`, `FechaEntrega`, `MecanismoLectura`, datos de
sede, `IdColaboradorCorporativo`, `NombreColaborador`, datos del menu y
`TotalRegistros`. No devuelve documentos ni `CodigoSAP`.

`EstadoRetiro` se deriva sin alterar datos: es `ENTREGADO` cuando existe
`Entrega`, `CANCELADO` cuando la reserva esta cancelada y `SIN_ENTREGAR` en los
demas casos sin entrega.

## Filtro corporativo

Cuando se recibe `@NombreColaborador`, el SP consulta exclusivamente la
proyeccion minima `[GSBEDEV01\CO].[PERSONALMANEGEMENTCORP].[rrhh].[vw_ColaboradorConsulta]`
mediante el linked server de desarrollo `GSBEDEV01\CO`. El filtro se aplica
antes del conteo y la paginacion. La misma vista aporta `NombreColaborador` al
recordset; si no existe una proyeccion corporativa para el UUID de la reserva,
el nombre se devuelve como `NULL` cuando no se aplico el filtro.

La ejecucion requiere que el linked server y el permiso de lectura a esa vista
esten configurados. Si la dependencia no esta disponible, el contrato devuelve
el error seguro `INTERNAL_ERROR` y la auditoria registra el detalle interno.

## Codigos y mensajes seguros

| Codigo | Mensaje |
|---|---|
| `OK` | `null` |
| `INVALID_FILTER` | `Los filtros de historial no son validos.` |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` |

Es una lectura: no abre transacciones ni modifica reservas, QR o entregas. Los
errores inesperados se registran mediante la auditoria existente.
