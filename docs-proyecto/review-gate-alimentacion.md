# Gate Review — DB Alimentación

Fecha: 2026-09-04

Task revisada: `DB-ALIMENTACION-009`

Veredicto: **fail**

## Blockers

0. El contrato vigente de Backend aún define `usp_Seguridad_ResolverActor` como fail-closed; se bloquea únicamente ese procedure hasta recibir la publicación corregida.

1. `Planificacion` y `Menu` solo poseen identificadores internos
   `BIGINT`, mientras el OpenAPI oficial expone `planId` y `menuId` como UUID.
2. El DDL usa `organizacion.Sede.IdSede INT` y
   `rrhh.Colaborador.IdColaborador BIGINT`, mientras el OpenAPI oficial expone
   `siteId` y `actorId` como UUID. No existe un mapeo aprobado y el núcleo no
   puede modificarse silenciosamente.
3. `RegistroIdempotencia` no conserva `IdCorrelacion`, requerido por el baseline
   oficial y por la correlación contractual de resultados y errores.

## Warnings

- El README conserva una declaración histórica que ubica Alimentación fuera del
  alcance inicial y debe aclararse frente a la extensión `009..012`.
- El validador no comprueba directamente todas las invariantes que el DoD marca
  como satisfechas.
- No existe evidencia runtime en SQL Server 2017; requiere un checkpoint de
  ejecución posterior y separado.

## Estado de corrección

## Entrega DB-ALIMENTACION-009-CORR-2

- Se preparó `017_crear_validacion_entrega.sql` y su reversión aislada.
- Se prepararon validador estático, casos SQL de contrato/concurrencia y guardas de seed/limpieza.
- El gate permanece en fail: los 11 stubs siguen presentes y los procedures existentes aún no demuestran idempotencia, auditoría y recordsets contractuales completos.
- No existe evidencia de compilación o ejecución en SQL Server Local.

`DB-ALIMENTACION-009-CORR-1` quedó bloqueada sin modificar archivos. Agregar UUID
públicos a Planificación/Menú y `IdCorrelacion` a idempotencia es directo. La
estrategia para `siteId` y `actorId` requiere decisión humana antes de corregir y
repetir este gate.
