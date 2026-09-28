# Registro de aprobaciones

## 2026-09-24T11:51:30-05:00 — Confirmación de stack

- Checkpoint: confirmación de stack.
- Artefactos revisados:
  - `docs-proyecto/STACK.md`
  - `docs-proyecto/requirements.md`
  - `docs-proyecto/nucleo/er-diagram-v1.md`
  - `docs-proyecto/DEFINITION_OF_DONE.md`
- Decisión: aprobado.
- Respuesta del usuario: `OK` y autorización posterior para iniciar los cambios.
- Alcance autorizado: modificación y validación de los scripts del núcleo mediante subagentes; Alimentación permanece fuera hasta aprobar el núcleo.
- Ejecución sobre instancia real: no autorizada.

## 2026-09-24 — Autorización de auditoría interna de procedures CO

- Checkpoint: capacidad física de auditoría requerida por el contrato de
  resultados y errores de procedures API.
- Decisión: aprobada la creación de `auditoria.ErrorProcedimiento` y
  `auditoria.usp_RegistrarErrorProcedimiento` en CO.
- Solicitud presentada: autorización para crear en CO el schema `auditoria`, la
  tabla `ErrorProcedimiento` y el procedimiento interno de registro, siguiendo
  el patrón existente en Alimentación.
- Respuesta literal del usuario: `Confirmo 'ErrorProcedimiento'`.
- Fuente de evidencia: historial de esta conversación, checkpoint humano del
  2026-09-24. No se registra una hora ni un identificador externo porque no
  fueron proporcionados por el canal.
- Alcance: registrar internamente el detalle de errores inesperados del
  procedure de recepción SAP y devolver al backend solo `INTERNAL_ERROR` con
  mensaje seguro.
- No autoriza: ejecución contra instancia real ni cambios al módulo
  Alimentación.

## 2026-09-25 — Auditoría de procedures nuevos de USERMANAGEMENTCORP

- Checkpoint: mecanismo local de auditoría requerido por los nuevos procedures
  API de identidad Entra y referencia al núcleo.
- Decisión: aprobada la creación aditiva de `auditoria.ErrorProcedimiento` y
  su procedure interno de registro en `USERMANAGEMENTCORP`.
- Respuesta literal del usuario: `Sobre la auditoria de errores, solo aplicaria
  para los stores nuevos que se crean, para los stores que existian antes no.`
- Alcance: el mecanismo solo será invocado por los nuevos procedures creados en
  esta fase; no modifica ni audita procedures legacy.
- No autoriza: ejecución contra instancia real ni cambio de comportamiento de
  autenticación AD, usuarios, roles, permisos o procedures existentes.

## 2026-09-25 — Corrección de alcance UMC: solo referencia al núcleo

- Decisión: no se agrega una tabla, schema, procedure ni auditoría para
  Microsoft Entra ID en `USERMANAGEMENTCORP`.
- Respuesta del usuario: la base conserva exclusivamente la unión aditiva
  `USERMANAGEMENTCORP.dbo.Usuario` → núcleo GTM.
- Alcance resultante: `dbo.UsuarioReferenciaColaborador`, sus scripts operativos y
  documentación. La validación de Entra y la resolución del `UsuarioId` legacy
  quedan fuera de la base, a cargo del backend.
- Sustituye para UMC la autorización anterior de auditoría e identidad Entra;
  no afecta la auditoría previamente aprobada para CO.

## 2026-09-25 — Resolución de contexto legacy UMC

- Decisión: aprobada la creación de un procedure nuevo que resuelve por
  `UsuarioAcceso` exacto un usuario legacy y su vínculo al núcleo, sin modificar
  procedures existentes.
- Alcance: `dbo.usp_ResolverContextoUsuarioNucleoPorAcceso` y la auditoría local
  `auditoria.ErrorProcedimiento` con su logger interno, invocados únicamente por
  el `CATCH` de ese procedure nuevo.
- No autoriza: datos o mapeos Microsoft Entra, cambios a `up_ObtieneUsuario` u
  otros procedures legacy, ni ejecución contra una instancia real.
