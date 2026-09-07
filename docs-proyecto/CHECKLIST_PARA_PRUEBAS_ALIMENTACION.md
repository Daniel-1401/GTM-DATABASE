# Checklist urgente para llegar a pruebas — Alimentación

Fecha de corte: 2026-09-04

Estado actual verificado: 22 procedures declarados, 11 en `fail-closed`, sin
tabla `ValidacionEntrega`, sin seed de datos y con el Review Gate DB todavía en
`fail`. La validación disponible es estática; no existe evidencia de compilación
o ejecución en SQL Server 2017.

## P0 — Bloqueantes antes de desplegar en Local

- [ ] **Recibir y congelar el contrato corregido de Seguridad desde Backend.**
  - Debe definir la firma final de `usp_Seguridad_ResolverActor` y confirmar que
    roles y sedes provienen de Seguridad externa.
  - Evidencia: `hub-gtm/docs-proyecto/STORED_PROCEDURES_REQUERIDOS.md` actualizado
    y pruebas del repository/guard en verde.

- [ ] **Agregar una migración versionada para `alimentacion.ValidacionEntrega`.**
  - Debe conservar `ValidationId`, QR/reserva, operador, sede, método de lectura,
    creación, vencimiento, consumo y correlación, sin guardar el QR en claro.
  - Debe permitir consumo único y expiración corta.
  - Evidencia: migración, reversión, ER físico y validador actualizados.

- [ ] **Eliminar los 11 `fail-closed` reemplazándolos por lógica funcional.**
  - [ ] `usp_Planificaciones_CopiarMenu`
  - [ ] `usp_Planificaciones_Consolidar`
  - [ ] `usp_Qr_Emitir`
  - [ ] `usp_Qr_Revocar`
  - [ ] `usp_Entregas_ValidarQr`
  - [ ] `usp_Entregas_Confirmar`
  - [ ] `usp_Reportes_ObtenerReservas`
  - [ ] `usp_Reportes_ExportarReservas`
  - [ ] `usp_Auditoria_ListarEventos`
  - [ ] `usp_Seguridad_ResolverActor`
  - [ ] `usp_Reservas_MarcarNoRecogidas`
  - Evidencia: cero coincidencias de `DEPENDENCY_UNAVAILABLE` o “pendiente de
    implementación” en `db/procedures/`.

- [ ] **Completar idempotencia en todas las mutaciones.**
  - Misma clave + misma huella: devolver resultado previo sin repetir efectos.
  - Misma clave + payload diferente: `IDEMPOTENCY_CONFLICT`.
  - Persistir finalización, código, resultado, expiración e `IdCorrelacion`.
  - Evidencia: cada procedure con `@IdempotencyKey` usa
    `alimentacion.RegistroIdempotencia`; pruebas de replay y conflicto.

- [ ] **Completar auditoría atómica de mutaciones y rechazos relevantes.**
  - Registrar actor, aplicación, sede, objeto, resultado, correlación y huella
    no reversible; nunca QR, BLE o tokens en claro.
  - Evidencia: uso de `alimentacion.EventoAuditoria` dentro de las transacciones
    críticas y pruebas de minimización.

- [ ] **Corregir concurrencia y transacciones.**
  - Versión optimista para menú/plan.
  - Bloqueo seguro al emitir/revocar/consumir QR.
  - Confirmar entrega, consumir QR y cambiar reserva en una sola transacción.
  - Consolidación irreversible y snapshot consistente.
  - Evidencia: `UPDLOCK`/`HOLDLOCK` o estrategia equivalente y pruebas de dos
    sesiones concurrentes.

- [ ] **Reconciliar las 22 firmas y recordsets con Backend.**
  - Validar nombre, tipo, nullability y orden lógico de parámetros.
  - Validar todos los recordsets requeridos, incluidos conteos y paginación.
  - Evidencia: comparación automática contra el catálogo y tests de repository.

- [ ] **Repetir el Review Gate DB hasta obtener `pass`.**
  - Cerrar UUID públicos, `IdCorrelacion`, schema `[alimentacion]`, contrato,
    seguridad y cobertura del validador.
  - Evidencia: nuevo `review-gate-alimentacion.md` con `verdict: pass` y cero
    blockers.

## P1 — Preparar ejecución y datos de prueba

- [ ] **Crear un validador procedural estático.**
  - Comprobar 22 nombres exactos, ausencia de fail-closed, uso de idempotencia,
    auditoría, transacciones y objetos requeridos.

- [ ] **Crear pruebas SQL automatizadas.**
  - Happy path y errores contractuales.
  - Transiciones inválidas, propiedad, sede/rol, replay idempotente, conflicto,
    QR vencido/revocado/usado y doble entrega.

- [ ] **Crear seed Local versionado y repetible.**
  - Empresas, sedes, colaboradores/identidad, horarios, configuración de
    servicio, ventanas, beacon y plan/menús mínimos.
  - Prohibido usar datos personales o secretos reales.
  - El seed debe fallar fuera del ambiente/base Local esperada.

- [ ] **Crear script de limpieza del seed.**
  - Solo datos identificados por una marca/correlación de prueba.
  - No debe eliminar datos ajenos ni objetos del schema.

- [ ] **Documentar orden de ejecución Local.**
  - Migraciones → procedures → verificación estructural → seed → pruebas.
  - Registrar versión de SQL Server y resultado de cada paso.

## Checkpoints humanos pendientes

- [ ] **Aprobación de creación DB:** antes de ejecutar el DDL en SQL Server.
- [ ] **Aprobación de DML de prueba:** antes de ejecutar el seed Local.
- [ ] **Confirmación de objetivo exacto:** nombre de servidor, instancia y base
  Local; nunca inferir Producción/QAS.

## Condición de “listo para pruebas”

Solo se considera listo cuando se cumplen simultáneamente:

1. Review Gate DB en `pass`.
2. Cero procedures en `fail-closed`.
3. Las 22 firmas coinciden con Backend.
4. Pruebas estáticas y SQL en verde.
5. DDL aplicado únicamente en Local con aprobación registrada.
6. Seed Local aplicado y verificable sin datos reales.

