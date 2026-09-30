# `dbo.usp_ResolverContextoUsuarioNucleoPorAcceso`

## Proposito

Resuelve por `UsuarioAcceso` exacto o por `UsuarioId` el contexto de un usuario
legacy activo de `USERMANAGEMENTCORP` y, si existe, su vinculo logico con el
nucleo GTM. Es una lectura para backend: no autentica, autoriza, crea vinculos
ni resuelve identidades de Microsoft Entra, Active Directory u otro proveedor
externo.

Script fuente:
`db/migrations/usermanagementcorp/Stores_Procedures/001_resolver_contexto_usuario_nucleo_por_acceso.sql`.

## Firma

```sql
@UsuarioAcceso VARCHAR(100) = NULL,
@UsuarioId INT = NULL,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

## Parametros

| Parametro | Tipo | Entrada | Descripcion |
|---|---|---:|---|
| `@UsuarioAcceso` | `VARCHAR(100)` | No | Acceso legacy que el backend ya resolvio. Si se informa, se consulta mediante igualdad exacta; no usa `LIKE`. |
| `@UsuarioId` | `INT` | No | Identificador local legacy. Debe ser mayor que cero cuando se informa. Puede usarse sin `@UsuarioAcceso`; si ambos se informan, deben corresponder a la misma fila. |
| `@Codigo` | `NVARCHAR(50)` | Salida | Codigo seguro del resultado. |
| `@Mensaje` | `NVARCHAR(500)` | Salida | Mensaje seguro para backend; es `NULL` en `OK`. |

## Recordset en `OK`

Devuelve una sola fila cuando existe exactamente un usuario activo. Una cuenta
activa sin referencia al nucleo es valida; sus columnas de referencia se
devuelven como `NULL` y `TieneVinculoNucleo = 0`. En errores funcionales no
devuelve recordset.

| Columna | Descripcion |
|---|---|
| `UsuarioId` | Identificador local legacy. |
| `CodigoColaborador` | Codigo de colaborador legacy, si existe. |
| `UsuarioAcceso` | Valor legacy resuelto. |
| `Correo` | Correo registrado en el usuario legacy. |
| `EsActivoUsuario` | Estado del usuario local. |
| `IdUsuarioCorporativo` | GUID estable del operador; es `NULL` si no existe vinculo. |
| `IdColaboradorCorporativo` | GUID logico del colaborador CO; puede ser `NULL`. |
| `TieneVinculoNucleo` | Indica si existe `dbo.UsuarioReferenciaColaborador`. |
| `EstaActivoVinculo` | Vigencia del vinculo; es `NULL` si no existe. |

## Codigos y mensajes seguros

| Codigo | Mensaje | Condicion |
|---|---|---|
| `OK` | `NULL` | Existe exactamente un usuario activo. |
| `BAD_REQUEST` | `UsuarioAcceso o UsuarioId es obligatorio.` | Ambos identificadores son `NULL`, vacios o solo contienen espacios; o `UsuarioId` no es mayor que cero. |
| `NOT_FOUND` | `El usuario no fue encontrado.` | No existe un usuario que coincida con los identificadores informados. |
| `FORBIDDEN` | `El usuario no está activo.` | Existe un unico usuario, pero esta inactivo. |
| `CONFLICT` | `La identidad de usuario es ambigua.` | Hay mas de una fila para el acceso exacto. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

## Reglas de seguridad y auditoria

- El backend es la autoridad de autenticacion y autorizacion; los clientes no
  se conectan directamente a SQL Server.
- El procedure inicia con `SET NOCOUNT ON`, `SET XACT_ABORT ON`,
  `@Codigo = N'OK'` y `@Mensaje = NULL`. La lectura no abre una transaccion.
- La rama `CONFLICT` es defensiva: no selecciona arbitrariamente una fila con
  `TOP (1)` si el acceso legacy es ambiguo. `UsuarioId` identifica como maximo
  una fila por ser la clave primaria local.
- Si se informan ambos identificadores, la consulta exige que coincidan con la
  misma fila; no se da preferencia silenciosa a uno de ellos.
- Los GUID devueltos son referencias logicas; el procedure no consulta CO ni
  valida proveedores de identidad externos.
- Ante un error inesperado, intenta registrar el detalle mediante
  `auditoria.usp_RegistrarErrorProcedimiento` y devuelve solamente
  `INTERNAL_ERROR` con su mensaje seguro. Una falla de auditoria no cambia la
  respuesta API.
- No persiste tokens, secretos, `tid`, `oid`, UPN ni otros datos de identidad
  externa.
