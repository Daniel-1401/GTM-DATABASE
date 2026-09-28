# Definition of Done — reestructuración del núcleo GTM y compatibilidad USERMANAGEMENTCORP

Fecha: 2026-09-25
Alcance: scripts y documentación del núcleo y extensión aditiva de
`USERMANAGEMENTCORP`; Alimentación permanece excluida

Los criterios siguientes son binarios. Los comandos concretos podrán adaptarse
al runner disponible, pero no se sustituye una verificación ejecutable por una
apreciación manual.

Estado de esta consolidación: las casillas marcadas abajo se comprobaron por
inspección estática del repositorio. Todas las casillas que exigen ejecutar SQL
permanecen sin marcar: no se autorizó ni se realizó DDL/DML en una instancia.

## 1. Trazabilidad funcional

- [ ] Cada `REQ-*` de `docs-proyecto/requirements.md` está trazado a una
  migración, restricción, prueba o limitación documentada — verificado por:
  matriz requerimiento → artefacto del informe de DB — owner: DB Agent.
- [ ] No se modificó ningún archivo de Alimentación y los cambios en
  `USERMANAGEMENTCORP` son exclusivamente los aprobados para compatibilidad —
  verificado por: `git diff --name-only` e inventario de objetos — owner: Review
  Agent.
- [x] No se añadió promoción desde staging al núcleo — verificado por: revisión
  de `db/migrations/nucleo/` y búsqueda de DML staging → tablas maestras — owner:
  Review Agent.

## 2. Base de datos corporativa CO

- [ ] La secuencia corporativa aplica sin errores desde una base vacía en SQL
  Server 2017 — verificado por: ejecución autorizada de migraciones en base
  desechable — owner: DB Agent.
- [ ] CO contiene catálogos, UO, empresas, personas, documentos, colaboradores,
  integración SAP y auditoría interna definidos — verificado por: consulta a
  `sys.schemas`, `sys.tables`, `sys.table_types`, `sys.procedures` y
  `sys.indexes` — owner: DB Agent.
- [ ] CO no contiene tablas de usuario, rol, permiso, sesión, contraseña o token
  — verificado por: inventario de objetos y revisión del diff — owner: Review
  Agent.
- [ ] Las unicidades de persona, colaborador y documentos cumplen
  `REQ-RN-001` a `REQ-RN-003` — verificado por: casos SQL positivos y negativos
  en base desechable — owner: DB Agent.

## 3. Base de datos hija de UO

- [ ] La secuencia UO aplica sin errores desde una base vacía en SQL Server
  2017 — verificado por: ejecución autorizada de migraciones en base desechable
  — owner: DB Agent.
- [ ] La configuración admite exactamente una UO y varias
  `EmpresaReferencia` pertenecientes a ella — verificado por: casos SQL
  positivos y negativos — owner: DB Agent.
- [ ] Sede, área, cargo, cargo SAP, relación laboral, asignación y horario
  conservan integridad por empresa local — verificado por: inspección de FKs e
  intentos de cruce entre empresas — owner: DB Agent.
- [ ] `AsignacionOrganizacional.IdEmpresaReferencia` tiene FK local a
  `EmpresaReferencia`, además de la consistencia de sede y área — verificado
  por: consulta a `sys.foreign_keys` y caso SQL negativo — owner: DB Agent.
- [ ] La combinación colaborador–empresa no puede duplicarse y una fila cesada
  puede reactivarse sin insertar otra relación — verificado por: casos SQL de
  cese/reingreso — owner: DB Agent.
- [ ] Una relación corporativa no admite dos asignaciones dentro de una misma
  hija y la limitación de unicidad global entre hijas está documentada —
  verificado por: índice/restricción local + revisión documental — owner: Review
  Agent.
- [ ] Existe como máximo un horario por relación y fecha — verificado por: caso
  SQL de duplicado — owner: DB Agent.
- [ ] Los objetos de selección continúan aplicando y revierten junto con la UO —
  verificado por: inventario antes/después de la reversión — owner: DB Agent.

## 4. Integración SAP por Kafka

- [x] `integracion.PersonalSAPStaging` contiene metadatos Kafka,
  `PayloadOriginal` y las 63 columnas normalizadas de `FROMSAP.xlsx` —
  verificado por: consulta a `sys.columns` comparada con el inventario de
  `requirements.md` — owner: DB Agent.
- [ ] Los 63 valores de origen aceptan texto o `NULL` sin conversión de dominio
  — verificado por: inserción de evento de prueba con formatos heterogéneos —
  owner: DB Agent.
- [ ] El TVP permite enviar una o varias filas en una llamada — verificado por:
  prueba del stored procedure con lotes de 1 y más de 1 evento — owner: DB
  Agent.
- [ ] Un reintento con el mismo topic/partición/offset no duplica la fila y
  devuelve resultado exitoso — verificado por: prueba de doble ejecución —
  owner: DB Agent.
- [ ] Un `IdEventoOrigen` republicado en otro offset tampoco duplica la fila —
  verificado por: prueba de doble ejecución con distinto offset — owner: DB
  Agent.
- [ ] Un evento nuevo del mismo colaborador crea otra fila y no sobrescribe la
  anterior — verificado por: conteo e inspección posterior a dos eventos —
  owner: DB Agent.
- [x] No existe tabla persistente separada `EventoIntegracion` o `CargaSAP` —
  verificado por: inventario de `sys.tables` — owner: Review Agent.
- [ ] El stored procedure finaliza su firma con `@Codigo` y `@Mensaje`, usa
  códigos aprobados y tiene contrato Markdown — verificado por: revisión contra
  `docs-proyecto/alimentacion/Stores Procedures/000_contrato_resultados_y_errores.md`
  — owner: Review Agent.
- [ ] La mutación de recepción usa transacción `TRY/CATCH`, `SET NOCOUNT ON` y
  `SET XACT_ABORT ON`, y no expone errores internos — verificado por: revisión
  estática del procedure y pruebas de error — owner: Review Agent.
- [ ] Los errores inesperados de procedures API CO se registran en
  `auditoria.ErrorProcedimiento` y se devuelven al backend solo como
  `INTERNAL_ERROR` seguro — verificado por: revisión estática y prueba de error
  en base desechable — owner: Review Agent.

## 5. Semilla, limpieza y reversión

- [ ] La semilla CO puede ejecutarse dos veces sin duplicar datos — verificado
  por: doble ejecución y comparación de conteos — owner: DB Agent.
- [ ] La semilla UO puede ejecutarse dos veces sin duplicar datos — verificado
  por: doble ejecución y comparación de conteos — owner: DB Agent.
- [ ] La semilla cubre al menos una UO, más de una empresa, persona, documento,
  colaborador, relación laboral, asignación y dependencias organizacionales del
  schema final — verificado por: consultas de conteo y relaciones — owner: DB
  Agent.
- [ ] La semilla de integración cubre un evento SAP completo sintético y un
  reintento idempotente — verificado por: ejecución del TVP/procedure en base
  desechable — owner: DB Agent.
- [ ] La limpieza CO elimina datos de prueba, incluido staging, sin eliminar
  objetos — verificado por: ejecución y conteos en cero — owner: DB Agent.
- [ ] La limpieza UO elimina datos respetando FKs y conserva los objetos —
  verificado por: ejecución y conteos en cero — owner: DB Agent.
- [ ] La reversión CO elimina procedures, tipos, tablas y schemas del núcleo en
  orden válido — verificado por: ejecución posterior a una instalación completa
  — owner: DB Agent.
- [ ] La reversión UO elimina todos los objetos creados por su secuencia —
  verificado por: ejecución posterior a una instalación completa — owner: DB
  Agent.

## 6. Documentación y consistencia

- [ ] `docs-proyecto/nucleo/TABLAS_NUCLEO.md` coincide con el schema final y
  describe una hija por UO — verificado por: comparación ER/schema/documento —
  owner: Review Agent.
- [ ] El diagrama ER final del DB Agent conserva las entidades y relaciones
  aprobadas en `docs-proyecto/nucleo/er-diagram-v1.md` o documenta cada cambio
  aprobado — verificado por: diff de diagramas — owner: Review Agent.
- [x] `docs-proyecto/db-scripts-log.md` registra cada script modificado o creado,
  entidades afectadas y motivo — verificado por: comparación contra
  `git diff --name-only` — owner: Review Agent.
- [ ] Las referencias a scripts eliminados o al modelo anterior fueron
  retiradas de la documentación vigente — verificado por: `rg` sobre rutas y
  nombres obsoletos — owner: Review Agent.
- [ ] `git diff --check` finaliza sin errores — verificado por:
  `git diff --check` — owner: DB Agent.
- [ ] Graphify se actualiza y no reporta `GRAPH HEALTH WARNING` — verificado por:
  `graphify --update` y diagnóstico — owner: Orquestador.

## 7. Categorías no aplicables en esta fase

- Backend funcional: no aplica; solo se define el límite de integración que el
  backend implementará en otra fase.
- Frontend: no aplica; no hay plataformas ni prototipos dentro de este alcance.
- API de módulos: no aplica; no se selecciona ni modifica un paradigma de API.
- Alimentación: no aplica hasta que el núcleo sea validado y aprobado.
  Las migraciones vigentes de Alimentación aún requieren `rrhh.Colaborador` y
  no son compatibles con la nueva instancia UO; su migración coordinada es una
  condición previa de despliegue y corresponde a la siguiente fase.

## 8. Compatibilidad USERMANAGEMENTCORP ↔ Núcleo

- [ ] La migración incremental UMC aplica sin errores en SQL Server 2017 sobre
  la estructura legacy — verificado por: ejecución autorizada en base
  desechable con `ScriptCreacion_v1.sql` como precondición — owner: DB Agent.
- [ ] `dbo.UsuarioReferenciaColaborador` existe con FK local correcta hacia
  `dbo.Usuario`, sin FK entre UMC y CO — verificado por: `sys.tables` y
  `sys.foreign_keys` — owner: DB Agent.
- [ ] Un `UsuarioId` obtiene una referencia corporativa única y un usuario sin
  colaborador puede resolverse correctamente — verificado por: casos SQL con y
  sin `IdColaboradorCorporativo` — owner: DB Agent.
- [ ] No se puede vincular un mismo colaborador a dos referencias vigentes sin
  una regla aprobada que lo permita — verificado por: caso SQL negativo —
  owner: DB Agent.
- [ ] La semilla UMC nueva es repetible y no modifica datos legacy; limpieza y
  reversión eliminan exclusivamente objetos/datos de esta extensión en orden
  válido — verificado por: ejecución doble, conteos e inventario antes/después
  — owner: DB Agent.
- [ ] Existe una prueba SQL versionada para base desechable que cubre FK,
  conflictos de unicidad, usuario sin colaborador, vigencia y repetibilidad de
  semilla, y el procedure de resolución — verificado por: ejecución con
  `db/pruebas/usermanagementcorp/001_probar_usuario_referencia_colaborador.sql`
  — owner: DB Agent.
- [ ] El procedure UMC nuevo resuelve exactamente un usuario legacy activo por
  `UsuarioAcceso`, no devuelve datos ante entrada inválida, ausencia,
  inactividad o multiplicidad y retorna el vínculo nullable — verificado por:
  casos SQL en base desechable — owner: DB Agent.
- [ ] Los errores inesperados del procedure UMC nuevo se intentan registrar en
  `auditoria.ErrorProcedimiento` sin alterar la respuesta `INTERNAL_ERROR`
  segura; ningún procedure legacy queda instrumentado — verificado por:
  revisión estática y prueba de logger en base desechable — owner: Review Agent.
- [ ] La migración UMC 002 se instala una vez sobre un schema `auditoria`
  preexistente y conserva dicho schema; los objetos homónimos incompatibles no
  se omiten — verificado por:
  `db/pruebas/usermanagementcorp/002_probar_instalacion_auditoria_preexistente.sql`
  en base desechable preparada desde el baseline previo a 002 — owner: DB Agent.
- [ ] La documentación describe que el backend resuelve la identidad externa
  fuera de UMC y concilia colaboradores por documento de identidad, no por
  correo/nombre/código SAP — verificado por: revisión cruzada de requisitos,
  ER y scripts — owner: Review Agent.

## Checkpoints humanos obligatorios

- [ ] **Aprobación del schema:** el humano aprueba explícitamente el diagrama,
  migraciones y relaciones finales antes de iniciar la modificación de
  Alimentación.
- [ ] **Aprobación de ejecución:** el humano autoriza expresamente cualquier
  aplicación de DDL/DML en una instancia real; la generación de scripts no
  equivale a autorización de ejecución.
