# Núcleo distribuido de GTM

Fecha de actualización: 2026-09-24
Motor objetivo: Microsoft SQL Server 2017

## Modelo y orden de instalación

GTM usa el Modelo B: una instancia corporativa (CO) y una instancia hija por
unidad organizativa (UO). Una hija representa una UO, no una empresa, y puede
proyectar varias empresas de esa UO. No hay claves foráneas entre bases.

| Destino | Orden de instalación | Responsabilidad |
|---|---|---|
| CO | `corporativo/001` → `002` → `003` → `004` → `005` → `006` | Catálogos, UO, empresas, identidad corporativa, integración SAP, auditoría interna y vista de consulta de colaboradores. |
| Hija UO | `unidad_organizativa/001` → `002` → `003` → `004` → `005` | Proyección local, organización, relación laboral, asignación, horarios, selección y vistas de consulta. |

Los GUID corporativos vinculan lógicamente las bases. El backend de integración
valida y coordina esos vínculos; una hija no debe crear una segunda autoridad
para empresas, personas o colaboradores.

## CO corporativo

| Schema | Tabla u objeto | Propósito e integridad principal |
|---|---|---|
| `catalogo` | `TipoDocumento`, `EstadoCivil`, `Genero`, `Pais` | Catálogos con código único y estado activo. |
| `organizacion` | `UnidadOrganizativa` | Maestro de UO con GUID corporativo y código único. |
| `organizacion` | `Empresa` | Maestro de empresas; pertenece a una UO y expone GUID corporativo único. |
| `rrhh` | `Persona` | Identidad civil con GUID corporativo. |
| `rrhh` | `DocumentoPersona` | Documento histórico; identidad documental única y un principal abierto por persona. |
| `rrhh` | `Colaborador` | Identidad laboral estable: máximo uno por persona y GUID corporativo único. |
| `rrhh` | `vw_ColaboradorConsulta` | Proyección de lectura mínima: UUID corporativo y nombre del colaborador. No expone datos laborales, relación organizacional, documentos ni datos SAP. |
| `integracion` | `PersonalSAPStaging` | Historial append-only de recepción SAP con Kafka, JSON original y 63 campos de origen. |
| `integracion` | `TVP_RecepcionPersonalSAP` | Tipo tabular para lotes estructurados de uno o más eventos SAP. |
| `integracion` | `usp_RegistrarPersonalSAPStaging` | Inserción idempotente de staging; no promueve al núcleo. |
| `auditoria` | `ErrorProcedimiento` | Bitácora interna de errores inesperados de procedures API de CO. |
| `auditoria` | `usp_RegistrarErrorProcedimiento` | Registrador interno que no expone detalles SQL al consumidor API. |

`PersonalSAPStaging` impide duplicados tanto por `IdEventoOrigen` como por
`KafkaTopic + KafkaPartition + KafkaOffset`. Sus 63 columnas son `NVARCHAR(MAX)`
anulables: el contrato SAP v1 exige que cada propiedad esté presente con texto o
`null`; SQL Server conserva el payload sin volver a interpretarlo.

El procedimiento recibe TVP, valida `sap.personal.actualizado` v1 de SAP y
devuelve `CREATED` o `IDEMPOTENT_REPLAY` ante una repetición. El backend confirma
offset Kafka solo después de que la ejecución haya confirmado en SQL Server.

Ante un error inesperado, el procedure de recepción conserva el detalle técnico
en `auditoria.ErrorProcedimiento` mediante el registrador interno y devuelve al
backend únicamente el código y mensaje seguro `INTERNAL_ERROR`.

## Instancia hija de UO

| Schema | Tabla | Propósito e integridad principal |
|---|---|---|
| `organizacion` | `ConfiguracionUnidadOrganizativa` | Una sola fila (`Id... = 1`) que identifica la UO propietaria. |
| `organizacion` | `EmpresaReferencia` | Proyección de una empresa CO; su UO debe coincidir con la configuración local. |
| `organizacion` | `Sede`, `Area`, `Cargo` | Maestros locales, todos pertenecientes a una empresa proyectada. |
| `organizacion` | `CargoSAP` | Código SAP y cargo GTM de la misma empresa. |
| `organizacion` | `CargoJefatura` | Jerarquía de cargos de una misma empresa; un jefe abierto por subordinado. |
| `organizacion` | `vw_SedeConsulta` | Sedes de la UO con la empresa propietaria, su UUID público, código, nombre y estados. |
| `organizacion` | `vw_EstructuraOrganizacionalConsulta` | Catálogo normalizado de sedes, áreas, cargos y cargos SAP; evita productos cartesianos entre esos maestros. |
| `organizacion` | `vw_JerarquiaCargoConsulta` | Relaciones de jefatura de cargos con empresa, códigos, nombres y periodo de vigencia. |
| `rrhh` | `RelacionLaboral` | Vínculo colaborador corporativo–empresa local. Es único por colaborador y empresa y se reactiva al reingreso. |
| `rrhh` | `AsignacionOrganizacional` | Contexto operativo: relación corporativa, empleador, empresa local, sede y área. |
| `rrhh` | `HorarioLaboral`, `VigenciaHorario` | Horarios por empresa y, como máximo, una vigencia por relación y fecha. |
| `rrhh` | `vw_ContextoOrganizacionalColaborador` | Contexto operativo por UUID corporativo: asignación, empresa, sede, área y, si la relación existe localmente, cargo y datos laborales. |
| `seleccion` | `Postulante`, `ArchivoPostulante`, `HistorialEstadoPostulante` | Prefiltro local, adjuntos y estados informados; no son aún persona ni colaborador. |

`AsignacionOrganizacional.IdEmpresaReferencia` tiene FK local directa hacia
`EmpresaReferencia`; sus FKs compuestas obligan a que sede y área sean de esa
misma empresa. No tiene FK a `RelacionLaboral`, porque puede representar una
relación procedente de otra hija. `IdRelacionLaboralCorporativa`,
`IdColaboradorCorporativo`, `IdUnidadOrganizativaOrigenCorporativa` e
`IdEmpresaEmpleadoraCorporativa` son vínculos lógicos distribuidos.

Una hija garantiza una sola asignación por relación corporativa. La garantía de
que esa sea la única asignación activa entre todas las hijas corresponde a la
operación backend coordinadora, pues no existe una restricción distribuida.

Las vistas de la hija se limitan a la UO configurada y no exponen nombres,
documentos ni usuarios corporativos. El horario vigente no se publica como
vista, porque requiere una fecha de consulta; ese caso debe resolverse mediante
un contrato con parámetro de fecha.

## Semilla, limpieza y reversión

`db/data_prueba/nucleo/001_semilla_datos_prueba_nucleo_corp.sql` se ejecuta en
la instancia CORP. Usa GUID deterministas, es repetible y crea los catálogos
corporativos, las UO `GI` y `NC`, y las empresas `Golden Palace` y `Newport
Capital`.

`db/data_prueba/nucleo/002_semilla_datos_prueba_nucleo_corp_personas_colaboradores.sql`
carga las personas y sus documentos DNI desde `db/csv_data/colaborador.csv`,
y crea el colaborador corporativo asociado. La semilla de la instancia UO GI se
entregará en un archivo separado.

`db/data_prueba/nucleo/003_semilla_datos_prueba_nucleo_uo_gi_organizacion.sql`
se ejecuta en `@GSBEDEV01/GI` y carga la configuración de la UO GI, la empresa
referencia `GI`, sus áreas y la sede `01` Golden Palace. Requiere colocar los
UUID corporativos en las variables del script.

`db/data_prueba/nucleo/004_semilla_datos_prueba_nucleo_uo_gi_cargos.sql` carga
los 101 cargos de Golden desde `db/csv_data/posiciones.csv`. Conserva
`id_posicion_reporta` en la carga temporal y crea 100 relaciones directas en
`CargoJefatura`, vigentes desde `2026-01-01`; la posición raíz no crea una
relación de jefatura.

`db/data_prueba/nucleo/005_semilla_datos_prueba_nucleo_uo_gi_cargos_sap.sql`
carga los 309 códigos SAP de `db/csv_data/posicionesSAP.csv` y los relaciona
con sus cargos GI mediante `IdCargo`, usando `IdEmpresaReferencia = 1`.

`db/data_prueba/nucleo/006_semilla_datos_prueba_nucleo_uo_gi_relaciones_laborales.sql`
carga las relaciones laborales desde `db/csv_data/colaborador.csv`, enlazando
el documento y colaborador corporativo de la instancia CO con el cargo SAP
local de Golden.

| Contexto | Limpieza de datos | Reversión completa |
|---|---|---|
| CO | `db/data_prueba/limpieza/limpiar_datos_nucleo_corporativo.sql` | `db/reversiones/revertir_nucleo_corporativo_completo.sql` |
| UO | `db/data_prueba/limpieza/limpiar_datos_nucleo_unidad_organizativa.sql` | `db/reversiones/revertir_nucleo_unidad_organizativa_completo.sql` |

No se ejecutaron estos scripts contra una instancia real como parte de esta
consolidación.

## Alcance pendiente

- No existe aún promoción desde staging hacia maestros del núcleo.
- No se conserva historial de reingresos ni de asignaciones organizacionales.
- La coordinación global de asignaciones y la sincronización de
  `EmpresaReferencia` pertenecen al backend de integración.
