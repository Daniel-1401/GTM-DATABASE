# Definition of Done — DB módulo Alimentación

Task: `DB-ALIMENTACION-009`
Motor: Microsoft SQL Server 2017
Schema: `[alimentacion]`

## 1. Modelo y alcance

- [x] El ER físico identifica 15 tablas, relaciones, cardinalidades, estados,
  temporalidad, idempotencia y límites transaccionales.
- [x] Las únicas relaciones con el núcleo usan las PK existentes de Sede,
  Colaborador y HorarioLaboral.
- [x] No se modelan inventario, compras, recetas, costos, capacidad, identidad
  paralela, entregas excepcionales ni exportaciones persistidas.
- [x] No se crean vistas, triggers, procedures, funciones, DML ni base física.

## 2. Migraciones y reversión

- [x] Existen migraciones consecutivas `009..012` sin modificar `001..008`.
- [x] Cada migración contiene encabezado, `UP`, `DOWN`, entidad, motivo y fuente.
- [x] El consolidado SQLCMD incluye las migraciones declaradas (`001..012` y `017`) una vez y en orden.
- [x] La reversión exige confirmación, base esperada, rechazo de bases de sistema
  y huella estructural, y solo elimina objetos de `[alimentacion]`.
- [ ] Las migraciones compilan y aplican desde cero en SQL Server 2017 — requiere
  checkpoint separado y ejecución futura autorizada.
- [ ] La reversión se prueba sobre una base efímera — requiere checkpoint separado.

## 3. Integridad

- [x] Las PK, FK, checks, constraints únicas e índices están declarados.
- [x] Se garantiza una planificación por sede con fechas elegidas libremente y un menú por planificación/fecha/servicio,
  una reserva activa por colaborador/fecha, un QR vigente y una entrega por reserva.
- [x] El QR conserva hash y no el contenido claro reutilizable.
- [x] El snapshot de cantidades queda separado del conteo operativo mutable.
- [ ] Máquinas de estado, consolidación inmutable y confirmación atómica completa
  se validarán con la futura transacción del backend; no son demostrables solo
  con los objetos autorizados.
- [ ] Auditoría append-only frente a acceso SQL directo se validará con el futuro
  modelo de privilegios; roles y GRANT/DENY no están autorizados ahora.

## 4. Trazabilidad y validación

- [x] ER físico, log de scripts, auditoría DB, README y validador están actualizados.
- [x] `db/validar_paquete_alimentacion.ps1` terminó con código 0 el 2026-09-04.
- [x] `git diff --check` terminó con código 0; los 13 archivos de la entrega,
  todavía no rastreados por Git, también pasaron `git diff --no-index --check`.
- [ ] Graphify actualizado y saludable — responsabilidad del Orquestador después de Review.

## 5. Gates humanos

- [ ] Gate `orchestrator-review` en pass.
- [ ] Aprobación humana del schema antes de trabajo Backend.
- [ ] Aprobación humana separada antes de ejecutar DDL.
- [ ] Checkpoint estricto si una tarea futura requiere otra base, schema u objeto
  externo; esta entrega no lo requiere.

## Condición

El paquete solo puede declararse listo para el checkpoint de schema después de
la validación estática y del gate Review. Ningún checkbox runtime se marca sin
evidencia de una instancia SQL Server autorizada.
