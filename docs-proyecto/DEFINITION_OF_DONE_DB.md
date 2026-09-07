# Definition of Done — etapa DB del núcleo general GTM

Esta extensión no reemplaza ni invalida `DEFINITION_OF_DONE.md` de la etapa
Analyst. Instancia la categoría Base de datos para DB-NUCLEO-002 y separa los
controles estáticos ya verificables de los checkpoints y pruebas de motor aún no
autorizados.

## 1. Cobertura del schema

- [x] El ER físico modela las entidades del núcleo conceptual aprobado sin
  introducir entidades internas de módulos consumidores — verificado por:
  `docs-proyecto/er-diagram-fisico-v1.md` y
  `db/validar_paquete.ps1` — owner: DB Agent.
- [x] Los objetos pertenecen únicamente a `catalogo`, `rrhh`, `organizacion` e
  `integracion` y no crean/seleccionan una base ni referencian otra base —
  verificado por: `db/validar_paquete.ps1` — owner: DB Agent.
- [x] Las PM-01..PM-17 no se resuelven por supuesto y sus efectos físicos están
  declarados — verificado por: sección 5 de `er-diagram-fisico-v1.md` y
  `db-audit-report.md` — owner: DB Agent.

## 2. Migraciones y reversión

- [x] Existen exactamente ocho migraciones consecutivas `001..008`, con
  encabezados, `UP`, `DOWN`, entidad, motivo y referencia — verificado por:
  `db/validar_paquete.ps1` — owner: DB Agent.
- [x] Existe un consolidado SQLCMD que referencia una vez cada migración en
  orden — verificado por: `db/validar_paquete.ps1` — owner: DB Agent.
- [x] Existe una reversión integral en orden inverso, transaccional y bloqueada
  por confirmación, nombre exacto de base, rechazo de bases de sistema y huella
  estructural — verificado por: `db/validar_paquete.ps1` — owner: DB Agent.
- [ ] Las migraciones compilan y aplican limpiamente desde cero en Microsoft SQL
  Server 2017 — verificado por: ejecución futura sobre una base vacía autorizada
  — owner: Review Agent / humano autorizado.
- [ ] La reversión se prueba sobre una base efímera creada para QA — verificado
  por: ejecución futura autorizada y reinicio posterior desde cero — owner:
  Review Agent / humano autorizado.

## 3. Integridad y límites

- [x] Las vigencias por rango validan `FechaFin > FechaInicio`; las asignaciones
  de horario son diarias y únicas por relación/fecha — verificado por:
  inspección estática de migraciones `003..008` — owner: DB Agent.
- [ ] Contención entre tablas, cobertura continua y ausencia de solapamientos
  históricos cerrados — pendiente de una fase posterior con mecanismos aún no
  autorizados — owner: DB Agent futuro / usuario.
- [x] No existen tablas de Seguridad, Alimentación, Evaluaciones, Marcaciones,
  Notificaciones o Declaraciones Juradas — verificado por:
  `db/validar_paquete.ps1` — owner: DB Agent.
- [x] No se almacenan contraseñas, sesiones, tokens, roles ni permisos —
  verificado por: inventario de columnas y objetos en `db/migrations` — owner:
  DB Agent.
- [x] La fase inicial no crea vistas, disparadores, funciones ni procedimientos
  almacenados — verificado por: `db/validar_paquete.ps1` — owner: DB Agent.

## 4. Documentación y trazabilidad

- [x] Existe ER físico final, auditoría de `001..008`, README operativo y log de
  cada script con timestamp, entidades y motivo — verificado por: existencia de
  archivos y tabla completa en `db-scripts-log.md` — owner: DB Agent.
- [x] La validación estática termina con código 0 — verificado por:
  `db/validar_paquete.ps1` — owner: DB Agent.
- [ ] El grafo del proyecto se actualiza después de la revisión y no presenta
  `GRAPH HEALTH WARNING` — verificado por: `graphify update .` — owner:
  Orquestador. El DB Agent no escribe `graphify-out` por límite de ownership.

## 5. Checkpoints humanos no automatizables

- [ ] **Aprobación de schema:** el usuario aprueba entidades, relaciones,
  migraciones, decisiones conservadoras y preguntas abiertas antes de iniciar
  Backend.
- [ ] **Aprobación de creación física:** en un checkpoint posterior y separado,
  el usuario autoriza aplicar el DDL inicial a una base vacía concreta.
- [ ] **Aprobación estricta fuera de alcance:** solo si alguna futura tarea
  necesitara otra base, schema compartido, usuario o rol externo; esta entrega no
  lo requiere.

## Condición de esta entrega

El paquete queda listo para Review Agent y revisión humana del schema. No puede
marcarse como “migraciones aplicadas limpio” ni habilitar Backend hasta completar
los criterios y checkpoints pendientes.
