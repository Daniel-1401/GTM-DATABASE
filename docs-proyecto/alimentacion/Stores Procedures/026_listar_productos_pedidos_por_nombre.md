# Contrato — `alimentacion.usp_ListarProductosPedidosPorNombre`

## Propósito

Busca productos de la base de datos externa `PEDIDOS` para ofrecerlos al
usuario durante la creación de un menú de planificación. Consulta
`[PEDIDOS].[ayb].[Producto]` y no modifica datos ni usa paginación.

Script fuente: `db/migrations/alimentacion/Stores Procedures/026_listar_productos_pedidos_por_nombre.sql`.

## Firma

```sql
CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarProductosPedidosPorNombre]
    @Nombre NVARCHAR(500),
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
```

## Parámetros

| Parámetro | Tipo | Descripción |
|---|---|---|
| `@Nombre` | `NVARCHAR(500)` | Texto obligatorio que se busca como coincidencia parcial y literal dentro del nombre del producto. Se recortan espacios en los extremos. |
| `@Codigo` | `NVARCHAR(50) OUTPUT` | Resultado de la operación. |
| `@Mensaje` | `NVARCHAR(500) OUTPUT` | Mensaje seguro asociado al resultado. |

## Recordset de salida

Con `@Codigo = 'OK'`, devuelve un único recordset, posiblemente vacío, ordenado
por `Nombre` e `IdProducto`.

| Columna | Tipo SQL / lógico | Descripción |
|---|---|---|
| `IdProducto` | `INT` / integer | Identificador de `[PEDIDOS].[ayb].[Producto].[ProductoID]`. |
| `Nombre` | `VARCHAR(500)` / string | Nombre del producto. |
| `Descripcion` | `VARCHAR(1200)` / string nullable | Descripción del producto, si está registrada. |

## Códigos de salida

| Código | Mensaje seguro | Condición |
|---|---|---|
| `OK` | `NULL` | Lectura correcta; el recordset puede estar vacío. |
| `INVALID_FILTER` | `El filtro de nombre es obligatorio.` | `@Nombre` es nulo, vacío o contiene solo espacios. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado, registrado internamente. |

## Reglas relevantes

- Es una lectura: no inicia transacciones de negocio ni modifica estado.
- Los caracteres `%`, `_`, `[` y `\` enviados en `@Nombre` se tratan como texto
  literal, no como comodines de `LIKE`.
- No filtra por disponibilidad, estado u otros atributos porque el alcance solo
  define el filtro por nombre.
- Requiere que la cuenta SQL que ejecuta el procedure tenga permiso `SELECT` sobre
  `[PEDIDOS].[ayb].[Producto]`.
