# Registro de scripts DB — GTM

Alcance: catálogo físico oficial de tablas para SQL Server 2017. Ningún script
de esta tabla ha sido ejecutado contra una instancia. El historial documenta
fuentes de DDL y no acredita tablas desplegadas. Una vez aplicada una versión,
cualquier cambio posterior deberá entregarse como una migración nueva y no
reescribir el historial.

| Script | Fecha | Entidad(es) | Motivo | Migración / artefacto |
|---|---|---|---|---|
| 001_crear_esquemas_nucleo | 2026-09-04T08:00:21-05:00 | `catalogo`, `rrhh`, `organizacion`, `integracion` | Separar los límites lógicos del núcleo sin crear ni seleccionar una base. | `db/migrations/nucleo/001_crear_esquemas_nucleo.sql` |
| 002_crear_catalogos_identidad_y_jefatura | 2026-09-04T08:00:21-05:00 | `catalogo.TipoDocumento`, `catalogo.TipoJefatura` | Crear catálogos extensibles sin sembrar valores no aprobados. | `db/migrations/nucleo/002_crear_catalogos_identidad_y_jefatura.sql` |
| 003_crear_personas_colaboradores_e_identidad_microsoft | 2026-09-04T08:00:21-05:00 | `rrhh.Persona`, `rrhh.Colaborador`, `rrhh.DocumentoPersona`, `integracion.CuentaMicrosoftCorporativa` | Separar identidad civil, registro laboral central y referencia Microsoft sin modelar Seguridad ni afirmar inmutabilidad del código. | `db/migrations/nucleo/003_crear_personas_colaboradores_e_identidad_microsoft.sql` |
| 004_crear_organizacion_y_centros_costo_sap | 2026-09-04T08:00:21-05:00 | `organizacion.Empresa`, `organizacion.Sede`, `organizacion.Area`, `organizacion.Cargo` | Crear los maestros GTM de organización sin tablas SAP. | `db/migrations/nucleo/004_crear_organizacion_y_centros_costo_sap.sql` |
| 005_crear_relaciones_laborales_y_referencias_empleado_sap | 2026-09-04T08:00:21-05:00 | `rrhh.RelacionLaboral` | Conservar reingresos y relaciones simultáneas como relaciones independientes. | `db/migrations/nucleo/005_crear_relaciones_laborales_y_referencias_empleado_sap.sql` |
| 006_crear_asignaciones_organizacionales_y_referencias_posicion_sap | 2026-09-04T08:00:21-05:00 | `rrhh.AsignacionOrganizacional` | Historiar el contexto organizacional sin dependencias hacia tablas SAP. | `db/migrations/nucleo/006_crear_asignaciones_organizacionales_y_referencias_posicion_sap.sql` |
| 007_crear_horarios_laborales_y_vigencias | 2026-09-04T08:00:21-05:00 | `rrhh.HorarioLaboral`, `rrhh.VigenciaHorario` | Mantener códigos y tipo de turno (`MANANA`, `TARDE`, `NOCHE`, `MADRUGADA`) y asignarlos por relación laboral y día, permitiendo repeticiones. | `db/migrations/nucleo/007_crear_horarios_laborales_y_vigencias.sql` |
| 008_crear_jefaturas_relaciones_laborales | 2026-09-04T08:00:21-05:00 | `rrhh.JefaturaRelacionLaboral` | Modelar dos prioridades posibles y conservar vigencias, dejando el máximo histórico para una fase posterior. | `db/migrations/nucleo/008_crear_jefaturas_relaciones_laborales.sql` |
| aplicar_migraciones_nucleo | 2026-09-04T09:42:47-05:00 | Migraciones `001..008` | Fijar una secuencia SQLCMD única y reproducible para una futura base vacía autorizada. | `db/aplicar_migraciones_nucleo.sql` |
| revertir_nucleo_completo | 2026-09-04T09:42:47-05:00 | Todos los objetos del paquete | Proveer reversión integral transaccional, bloqueada por confirmación, base esperada, rechazo de bases de sistema y huella estructural. | `db/reversiones/revertir_nucleo_completo.sql` |
| validar_paquete | 2026-09-04T09:42:47-05:00 | Paquete DB | Validar estáticamente secuencia, trazabilidad y límites sin conectarse a SQL Server. | `db/validar_paquete.ps1` |
| 009_crear_schema_y_configuracion_alimentacion | 2026-09-04T12:00:00-05:00 | `alimentacion`, configuración horario/servicio, ventanas y beacon | Crear el límite lógico y la configuración operativa sin duplicar sedes ni horarios. | `db/migrations/alimentacion/009_crear_schema_y_configuracion_alimentacion.sql` |
| 010_crear_planificaciones_menus_y_consolidacion | 2026-09-04T12:00:00-05:00 | Planificación, menú, componentes y consolidación | Persistir días elegidos sin exigir consecutividad ni mes común y conservar la fotografía irreversible de cantidades. | `db/migrations/alimentacion/010_crear_planificaciones_menus_y_consolidacion.sql` |
| 011_crear_reservas_qr_y_entregas | 2026-09-04T12:00:00-05:00 | Reserva, CodigoQR, Entrega | Persistir reserva individual, QR opaco y entrega normal sin excepciones. | `db/migrations/alimentacion/011_crear_reservas_qr_y_entregas.sql` |
| aplicar_migraciones_gtm_alimentacion | 2026-09-04T12:00:00-05:00 | Migraciones `001..011` y `012` | Construir núcleo y Alimentación de forma reproducible desde una base vacía autorizada. | `db/aplicar_migraciones_gtm_alimentacion.sql` |
| revertir_alimentacion_completo | 2026-09-04T12:00:00-05:00 | 12 tablas y schema `[alimentacion]` | Revertir solo el módulo con confirmación, base exacta y huella estructural. | `db/reversiones/revertir_alimentacion_completo.sql` |

## Ajustes de auditoría DB-NUCLEO-002

- `007`: se retiraron `DiaCicloHorario`, `TramoHorario` y
  `DuracionCicloDias`; PM-11 sigue abierta y el núcleo conserva solo el maestro
  y su vigencia.
- La anotación histórica de retiro de `009` y `010` queda superada por el estado
  oficial del 2026-09-07: las migraciones vigentes `009..011` y `012` forman
  parte del catálogo de 12 tablas de Alimentación. No se definen disparadores.
- `004`: se retiró `NombreCentroCosto`; PM-08 sigue sin respuesta.
- Se añadieron consolidado, reversión protegida por base/huella estructural y
  validación estática. No se ejecutó DDL, DML ni conexión alguna.
## 012_crear_validacion_entrega.sql — 2026-09-04

- Entidades: `alimentacion.ValidacionEntrega`.
- Motivo: validación corta previa al consumo sin persistir el QR en claro.
- Invariantes: `ValidationId` UUID, hash obligatorio, vencimiento máximo de dos minutos, consumo único, correlación única y relaciones con QR/reserva/operador/sede.
- Estado: preparado para revisión; no ejecutado contra SQL Server.
- Ruta: `db/migrations/alimentacion/012_crear_validacion_entrega.sql`.
