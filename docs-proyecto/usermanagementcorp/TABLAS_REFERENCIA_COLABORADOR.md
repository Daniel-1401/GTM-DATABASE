# Referencia USERMANAGEMENTCORP → núcleo GTM

La extensión agrega `dbo.UsuarioReferenciaColaborador`, un procedure API nuevo de
lectura y una auditoría local exclusiva de su `CATCH`. No cambia `dbo.Usuario`,
procedimientos legacy, roles, permisos, sistemas ni locales.

```text
Backend autenticado
  → valida identidad externa y obtiene UsuarioAcceso legacy fuera de UMC
  → dbo.usp_ResolverContextoUsuarioNucleoPorAcceso (búsqueda exacta)
  → USERMANAGEMENTCORP.dbo.UsuarioReferenciaColaborador
  → IdUsuarioCorporativo / IdColaboradorCorporativo lógico
  → CO.rrhh.Colaborador, si corresponde
```

Microsoft Entra ID, Active Directory y cualquier otro proveedor de identidad se
validan y resuelven en el backend. Esta base no recibe datos de identidad
externa, tokens ni crea una equivalencia entre una identidad externa y
`Usuario.UsuarioAcceso`.

El único procedure API nuevo es
`dbo.usp_ResolverContextoUsuarioNucleoPorAcceso`. Recibe un `UsuarioAcceso`
legacy ya obtenido por el backend, no recibe ni resuelve `tid`, `oid`, UPN ni
tokens. Su contrato está en
`docs-proyecto/usermanagementcorp/Stores Procedures/001_resolver_contexto_usuario_nucleo_por_acceso.md`.

La auditoría `auditoria.ErrorProcedimiento` y su logger interno se crean solo
para contener errores inesperados de ese procedure nuevo. No instrumentan ni
alteran procedures legacy.

## Tabla

| Columna | Uso |
|---|---|
| `UsuarioId` | PK y FK local hacia el usuario legacy. |
| `IdUsuarioCorporativo` | GUID estable y único del operador; se genera al crear el vínculo. |
| `IdColaboradorCorporativo` | GUID opcional y lógico hacia CO; no posee FK distribuida. |
| `EstaActiva` | Vigencia del vínculo; un colaborador solo puede figurar en una referencia activa. |
| `FechaCrea`, `FechaModifica` | Trazabilidad temporal local. |

## Resolución de contexto

La búsqueda de `UsuarioAcceso` usa igualdad exacta, nunca `LIKE`. El procedure
rechaza valores vacíos, usuario ausente, usuario inactivo o una multiplicidad
anómala antes de devolver datos. Para un usuario activo único entrega sus datos
legacy, los GUID del vínculo si existe y su vigencia. Una cuenta activa sin
`IdColaboradorCorporativo` es válida.

El backend valida previamente la existencia del colaborador CO y la
conciliación por documento de identidad antes de asignar
`IdColaboradorCorporativo`. El cliente nunca suministra estos GUID como una
identidad confiable.

## Scripts operativos

| Artefacto | Uso |
|---|---|
| `db/migrations/usermanagementcorp/001_crear_usuario_referencia_colaborador.sql` | Migración incremental aditiva. |
| `db/migrations/usermanagementcorp/002_crear_resolucion_contexto_usuario_nucleo.sql` | Auditoría local y procedure API nuevos. |
| `db/data_prueba/usermanagementcorp/001_semilla_usuario_referencia_colaborador.sql` | Semilla parametrizada por `UsuarioId` e `IdColaboradorCorporativo`; el UUID de usuario se genera en la tabla. |
| `db/data_prueba/limpieza/limpiar_datos_usermanagementcorp_referencia_colaborador.sql` | Limpieza de la referencia exacta indicada por los mismos dos parámetros. |
| `db/reversiones/revertir_usermanagementcorp_referencia_colaborador.sql` | Reversión protegida de los objetos UMC nuevos. |
| `db/pruebas/usermanagementcorp/001_probar_usuario_referencia_colaborador.sql` | Pruebas de FK, unicidad, vigencia, resolución, auditoría, semilla y limpieza. |
| `db/pruebas/usermanagementcorp/002_probar_instalacion_auditoria_preexistente.sql` | Instala 002 una vez con schema `auditoria` preexistente en base desechable. |

## Ejecución de pruebas

Ejecutar únicamente sobre una base desechable SQL Server 2017 creada desde
`ScriptCreacion_v1.sql` y con la migración aplicada. Desde la raíz del
repositorio:

```powershell
sqlcmd -S <servidor-desechable> -d <base-desechable> -b `
  -i db/pruebas/usermanagementcorp/001_probar_usuario_referencia_colaborador.sql `
  -v ConfirmarPruebasUMC="SI"
```

Las pruebas y sus datos legacy de apoyo se revierten mediante transacción. No
deben ejecutarse en una base con datos reales.

## Instalación con schema `auditoria` preexistente

Este caso no usa el snapshot actual, porque `ScriptCreacion_v1.sql` ya contiene
la migración `002`. Preparar una base desechable desde el baseline UMC anterior
a `002`, aplicar `001_crear_usuario_referencia_colaborador.sql` y ejecutar, desde la
raíz del repositorio:

```powershell
sqlcmd -S <servidor-desechable> -d <base-desechable> -b `
  -i db/pruebas/usermanagementcorp/002_probar_instalacion_auditoria_preexistente.sql `
  -v ConfirmarPruebaInstalacionUMC="SI" BaseDatosEsperada="<base-desechable>"
```

La prueba crea solamente el schema vacío `auditoria`, aplica `002` una vez y
verifica sus objetos UMC. No crea ni elimina bases de datos; la base desechable
se descarta por el operador después de la comprobación.

La prueba invoca directamente el logger interno únicamente dentro de esa
transacción revertida para comprobar su disponibilidad. En producción, el
logger solo es llamado desde el `CATCH` de
`dbo.usp_ResolverContextoUsuarioNucleoPorAcceso`.

La migración reutiliza un schema `auditoria` existente, pero no omite ni
reemplaza una tabla o procedure homónimo. La reversión elimina solo los objetos
UMC creados (`ErrorProcedimiento` y su logger) y conserva el schema, incluso si
queda vacío o contiene objetos de otros alcances.
