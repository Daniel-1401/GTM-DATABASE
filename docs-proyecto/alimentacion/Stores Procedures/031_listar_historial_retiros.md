# `alimentacion.usp_ListarHistorialRetiros`

## Propósito

Lista todas las reservas de colaboradores y su resultado de retiro. Usa los
mismos filtros tanto para el listado paginado como para la exportación completa.

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

## Filtros y paginación

- Todos los filtros son opcionales. `@Fecha` filtra un único día; no puede
  combinarse con `@FechaDesde` ni `@FechaHasta`. El rango es inclusivo.
- `@TipoServicio` admite `DESAYUNO`, `ALMUERZO` o `CENA`.
- `@EstadoRetiro` admite `ENTREGADO`, `CANCELADO` o `SIN_ENTREGAR`.
- Con `@Exportar = 0`, pagina usando `@NumeroPagina` (desde uno) y
  `@TamanoPagina` (1 a 100). Con `@Exportar = 1`, ignora ambos valores y
  devuelve todas las filas que cumplen los mismos filtros.

## Recordset

Devuelve `IdReserva`, `IdEntrega`, `FechaServicio`, `TipoServicio`,
`EstadoReserva`, `EstadoRetiro`, `FechaEntrega`, `MecanismoLectura`, datos de
sede, nombre y código SAP del colaborador, datos del menú y `TotalRegistros`.

`EstadoRetiro` se deriva sin alterar datos: es `ENTREGADO` cuando existe
`Entrega`, `CANCELADO` cuando la reserva está cancelada y `SIN_ENTREGAR` en los
demás casos sin entrega.

## Códigos y mensajes seguros

| Código | Mensaje |
|---|---|
| `OK` | `null` |
| `INVALID_FILTER` | `Los filtros de historial no son validos.` |
| `INTERNAL_ERROR` | `No fue posible completar la operacion.` |

Es una lectura: no abre transacciones ni modifica reservas, QR o entregas. Los
errores inesperados se registran mediante la auditoría existente.
