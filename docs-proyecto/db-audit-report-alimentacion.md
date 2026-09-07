# Auditoría estática DB-ALIMENTACION-009

Fecha: 2026-09-04
Motor objetivo: Microsoft SQL Server 2017
Schema: `[alimentacion]`
Evidencia: archivos locales; sin conexión, compilación ni ejecución en motor.

## Resultado

| Migración | Resultado estático | Alcance |
|---|---|---|
| `009` | Conforme para Review | Crea el schema exacto y cuatro tablas de configuración; enlaza solo HorarioLaboral y Sede del núcleo. |
| `010` | Conforme para Review | Crea cinco tablas para planificación, menú, componentes y snapshot de consolidación. |
| `011` | Conforme para Review | Crea Reserva, CodigoQR y Entrega con unicidades activas y relaciones compuestas. |
| `012` | Conforme para Review | Crea RegistroIdempotencia y EventoAuditoria sin almacenar QR claro, secretos ni perfil personal. |

El paquete conserva sin cambios las migraciones `001..008`; la secuencia total
es `001..012` y `017`; las migraciones del módulo crean 15 tablas con 15 claves
primarias. Las únicas FKs hacia el núcleo apuntan a `organizacion.Sede`,
`rrhh.Colaborador` y `rrhh.HorarioLaboral` usando sus PK reales.

## Trazabilidad funcional

- Planificación con fechas elegidas, estados y copia independiente: `01_MENUS_Y_PUBLICACION.md`.
- Reserva individual y unicidad colaborador + fecha: `02_RESERVAS.md`.
- QR opaco, un uso, cinco minutos y revocación: `03_QR_Y_BLE.md`.
- Entrega normal en dos pasos y confirmación atómica: `04_ENTREGA_PRESENCIAL.md`.
- Auditoría minimizada y retención funcional indefinida: `05_AUDITORIA_Y_REPORTES.md`.
- Idempotencia y control de versión: `contratos/API_REST.md`.
- Propiedad de datos, invariantes y límites: `referencias-tecnicas/SQL_SERVER_BASELINE.md`.

## Límites y riesgos visibles

1. Los índices filtrados garantizan solo una fila abierta o activa; no impiden
   solapamientos entre intervalos históricos cerrados.
2. Sin triggers/procedures no es posible garantizar solo por DDL las máquinas
   completas de estados, la inmutabilidad posterior a consolidar ni la operación
   atómica Reserva + QR + Entrega + Auditoría.
3. El carácter append-only de `EventoAuditoria` requiere privilegios de mínimo
   acceso, fuera del alcance actual de tablas/constraints/índices.
4. No se persiste `validationId` de entrega como entidad funcional: la lectura
   se audita y su soporte temporal pertenece al contrato técnico/idempotencia.
5. La retención de `RegistroIdempotencia` es técnica y acotada; el paquete no
   crea jobs ni DML de purga.
6. No hay evidencia runtime, de compilación, aplicación desde cero, rollback,
   concurrencia, rendimiento o seguridad de permisos en SQL Server 2017.

## Controles estáticos ejecutados

- `db/validar_paquete.ps1`: código 0; confirmó `001..008`.
- `db/validar_paquete_alimentacion.ps1`: código 0; confirmó secuencia `001..012`,
  15 tablas, schema exacto, FKs autorizadas, ausencia de DML y objetos
  excluidos, consolidado, rollback y artefactos documentales.
- Inventario estático: 14 PK, 21 FK y 24 índices en `009..012`.
- `git diff --check`: código 0. Como el árbol completo todavía está sin rastrear,
  se complementó con `git diff --no-index --check` sobre los 13 archivos de la
  entrega; no se detectaron errores de whitespace.

## Checkpoints

- Pendiente: gate obligatorio de `orchestrator-review`.
- Pendiente: aprobación humana del schema del módulo antes de Backend.
- Pendiente y separado: autorización explícita antes de ejecutar DDL en una base
  vacía concreta. Esta entrega no solicita ni presupone esa ejecución.
