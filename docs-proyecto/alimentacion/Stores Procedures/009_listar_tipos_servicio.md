# Contrato — `alimentacion.usp_ListarTiposServicio`

## Propósito

Lista los tipos de servicio activos que el frontend puede ofrecer al registrar o consultar menús.

Script fuente: `db/migrations/alimentacion/Stores Procedures/009_listar_tipos_servicio.sql`.

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ListarTiposServicio]
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Contrato de salida

Siempre devuelve un único recordset, posiblemente vacío. No recibe parámetros de entrada.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `OK` | `null` | Consulta ejecutada correctamente. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

| Columna | Tipo SQL / lógico | Descripción |
|---|---|---|
| `Codigo` | `NVARCHAR(20)` / string | Código que se envía como `TipoServicio` en las operaciones de menú. |
| `Nombre` | `NVARCHAR(100)` / string | Nombre para mostrar. |
| `OrdenPresentacion` | `TINYINT` / integer | Orden sugerido para la interfaz. |
