# Registro de aprobaciones — núcleo general GTM

## 2026-09-04 03:41:39 -05:00

- **Checkpoint:** confirmación de stack y aprobación del modelo conceptual v1.
- **Artefactos revisados:**
  - `docs-proyecto/STACK.md`;
  - `docs-proyecto/requirements.md`;
  - `docs-proyecto/er-diagram-v1.md`.
- **Decisión:** aprobado.
- **Respuesta humana:** “Apruebo el stack y modelo conceptual v1; difiero las preguntas materiales. No iniciar DB Agent.”
- **Preguntas materiales:** diferidas expresamente; deberán resolverse o volver a diferirse con alcance y responsable antes de iniciar el diseño físico.
- **Efecto:** se cierra el checkpoint Analyst. Esta aprobación no autoriza al DB Agent, SQL, DDL, DML, migraciones ni conexiones a bases de datos.

## 2026-09-04 — autorización de inicio del diseño DB

- **Decisión:** el usuario autorizó iniciar el diseño de base de datos mediante
  `$orquestador` dentro de `projects/gtm-database`.
- **Convención adicional:** tablas, columnas, vistas, procedimientos
  almacenados y demás objetos propios de SQL Server deben nombrarse en español.
- **Límite:** se autoriza generar el diseño, schema propuesto y migraciones
  versionadas como archivos; no se autoriza ejecutar DDL ni conectarse a una
  instancia SQL Server.

## 2026-09-04 — autorizacion de correccion fisica y generacion de procedures

- **Decision:** autorizada la correccion fisica con UUID publicos en Planificacion, Menu, Sede y Colaborador, manteniendo claves internas; agregado de `IdCorrelacion`; schema `[alimentacion]`; y reconciliacion de `ResolverActor` con Seguridad externa.
- **Alcance:** generar stored procedures como archivos, sin ejecutar DDL ni conectarse a SQL Server.
- **Checkpoint pendiente:** la ejecucion contra un motor real requiere aprobacion posterior separada.
