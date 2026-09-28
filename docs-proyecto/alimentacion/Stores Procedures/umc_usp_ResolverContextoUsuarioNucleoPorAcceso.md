# `dbo.usp_ResolverContextoUsuarioNucleoPorAcceso`

## Propósito

Resolver el contexto de un usuario legacy de `USERMANAGEMENTCORP` por
`UsuarioAcceso` exacto y exponer, si existe, su vínculo lógico al núcleo GTM.
Es un procedure de lectura para backend; no autentica, autoriza, crea vínculos
ni resuelve identidades Microsoft Entra, AD u otro proveedor externo.

## Firma

```sql
dbo.usp_ResolverContextoUsuarioNucleoPorAcceso
    @UsuarioAcceso VARCHAR(100),
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
```

## Parámetros

| Parámetro | Dirección | Regla |
|---|---|---|
| `@UsuarioAcceso` | Entrada | Obligatorio. Se busca con igualdad exacta; no se usa `LIKE`. Es el usuario legacy ya obtenido por el backend. |
| `@Codigo` | Salida | Resultado de la operación. |
| `@Mensaje` | Salida | Mensaje seguro para backend. |

## Recordset en `OK`

| Columna | Descripción |
|---|---|
| `UsuarioId` | Identificador local legacy. |
| `CodigoColaborador` | Código de colaborador legacy, si existe. |
| `UsuarioAcceso` | Valor legacy resuelto. |
| `Correo` | Correo registrado en el usuario legacy. |
| `EsActivoUsuario` | Estado del usuario local. |
| `IdUsuarioCorporativo` | GUID estable del operador; es `NULL` si aún no existe vínculo. |
| `IdColaboradorCorporativo` | GUID lógico de CO; puede ser `NULL`. |
| `TieneVinculoNucleo` | Indica si existe `UsuarioReferenciaColaborador`. |
| `EstaActivoVinculo` | Vigencia del vínculo; es `NULL` si no existe. |

Una cuenta activa sin colaborador, o incluso sin referencia aún aprovisionada,
es una respuesta válida y devuelve `OK`. Los resultados funcionales distintos
de `OK` no devuelven recordset.

## Códigos y mensajes seguros

| Código | Mensaje | Condición |
|---|---|---|
| `OK` | `NULL` | Existe exactamente un usuario activo. |
| `BAD_REQUEST` | `UsuarioAcceso es obligatorio.` | Parámetro `NULL`, vacío o solo espacios. |
| `NOT_FOUND` | `El usuario no fue encontrado.` | No existe usuario con ese valor exacto. |
| `FORBIDDEN` | `El usuario no está activo.` | El usuario único existe pero está inactivo. |
| `CONFLICT` | `La identidad de usuario es ambigua.` | Se detecta más de una fila para el acceso exacto; no se devuelve información. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Falla inesperada. |

`dbo.Usuario.UsuarioAcceso` posee una unicidad legacy; la rama `CONFLICT` es
defensiva ante corrupción o una modificación externa al modelo y nunca usa
`TOP (1)` para escoger una fila.

## Seguridad, transacción y auditoría

- El backend autentica y autoriza; los clientes no se conectan a SQL Server.
- La búsqueda no abre una transacción de lectura. El procedure inicia con
  `SET NOCOUNT ON`, `SET XACT_ABORT ON`, `@Codigo = N'OK'` y `@Mensaje = NULL`.
- En el `CATCH`, captura los metadatos del error, intenta registrarlos mediante
  `auditoria.usp_RegistrarErrorProcedimiento` y devuelve solo
  `INTERNAL_ERROR` con el mensaje seguro.
- La auditoría es local y de mejor esfuerzo: una falla del logger no cambia la
  respuesta del API. Ningún procedure legacy se instrumenta.
- No se persisten tokens, secretos, `tid`, `oid`, UPN ni otros datos de
  identidad externa.
