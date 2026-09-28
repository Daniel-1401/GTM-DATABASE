# Registro de scripts de base de datos

Fecha de consolidación: 2026-09-24
Alcance: reestructuración del núcleo GTM; SQL Server 2017.

| Orden | Ruta | Objetos o alcance | Motivo |
|---:|---|---|---|
| 1 | `db/migrations/nucleo/corporativo/001_crear_esquemas_corporativos.sql` | Schemas CO | Preparar namespaces corporativos. |
| 2 | `db/migrations/nucleo/corporativo/002_crear_catalogos_corporativos.sql` | Catálogos | Crear catálogos corporativos. |
| 3 | `db/migrations/nucleo/corporativo/003_crear_empresas_personas_y_documentos.sql` | UO, empresa, persona, documento, colaborador | Separar maestros CO de las instancias UO. |
| 4 | `db/migrations/nucleo/corporativo/004_crear_integracion_sap_kafka.sql` | Staging SAP, TVP y procedure | Recibir eventos Kafka de forma estructurada e idempotente. |
| 5 | `db/migrations/nucleo/corporativo/005_crear_auditoria_errores_sp.sql` | Bitácora y logger de auditoría | Registrar detalles internos de errores inesperados sin exponerlos en API. |
| 6 | `db/migrations/nucleo/unidad_organizativa/001_crear_esquemas_unidad_organizativa.sql` | Schemas UO | Preparar namespaces de una hija reutilizable. |
| 7 | `db/migrations/nucleo/unidad_organizativa/002_crear_referencias_y_organizacion.sql` | Configuración UO, empresa referencia y organización | Permitir una UO con varias empresas locales. |
| 8 | `db/migrations/nucleo/unidad_organizativa/003_crear_relaciones_asignaciones_y_horarios.sql` | Relación laboral, asignación y horarios | Modelar empleo y operación local sin FKs distribuidas. |
| 9 | `db/migrations/nucleo/unidad_organizativa/004_crear_postulantes_y_archivos.sql` | Selección | Mantener el prefiltro local independiente del núcleo oficial. |
| 10 | `db/data_prueba/nucleo/001_semilla_datos_prueba_nucleo_corp.sql` | Semilla de instancia CORP | Catálogos, UO `GI`/`NC` y empresas `Golden Palace`/`Newport Capital`. |
| 11 | `db/data_prueba/limpieza/limpiar_datos_nucleo_corporativo.sql` | Datos de prueba CO y staging | Limpiar CO respetando dependencias. |
| 12 | `db/data_prueba/limpieza/limpiar_datos_nucleo_unidad_organizativa.sql` | Datos de prueba UO | Limpiar una hija respetando dependencias. |
| 13 | `db/reversiones/revertir_nucleo_corporativo_completo.sql` | Objetos CO, incluida auditoría | Revertir el núcleo corporativo en orden dependiente. |
| 14 | `db/reversiones/revertir_nucleo_unidad_organizativa_completo.sql` | Objetos UO | Revertir una hija en orden dependiente. |
| 15 | `db/migrations/usermanagementcorp/001_crear_usuario_referencia_colaborador.sql` | Referencia de usuario al núcleo | Vincular aditivamente `dbo.Usuario` con GUID corporativos del núcleo. |
| 16 | `db/migrations/usermanagementcorp/ScriptCreacion_v1.sql` | Instalación nueva UMC | Mantener el script base alineado con la única tabla de referencia. |
| 17 | `db/data_prueba/usermanagementcorp/001_semilla_usuario_referencia_colaborador.sql` | Escenario UMC/CO | Probar una referencia controlada sin crear ni alterar usuarios legacy. |
| 18 | `db/data_prueba/limpieza/limpiar_datos_usermanagementcorp_referencia_colaborador.sql` | Datos de prueba UMC | Eliminar exclusivamente la referencia creada por la semilla. |
| 19 | `db/reversiones/revertir_usermanagementcorp_referencia_colaborador.sql` | Objeto nuevo UMC | Revertir en forma protegida la referencia sin tocar objetos legacy. |
| 20 | `db/pruebas/usermanagementcorp/001_probar_usuario_referencia_colaborador.sql` | Pruebas SQL UMC | Verificar FK, unicidad, vigencia, semilla y limpieza en una base desechable. |
| 21 | `db/migrations/usermanagementcorp/002_crear_resolucion_contexto_usuario_nucleo.sql` | Auditoría UMC y procedure de resolución | Resolver por acceso legacy exacto y registrar solo sus errores inesperados. |
| 22 | `docs-proyecto/alimentacion/Stores Procedures/umc_usp_ResolverContextoUsuarioNucleoPorAcceso.md` | Contrato del SP UMC | Definir firma, resultado, códigos seguros y alcance de auditoría. |
| 23 | `db/pruebas/usermanagementcorp/002_probar_instalacion_auditoria_preexistente.sql` | Instalación UMC con schema existente | Verificar creación de 002 sin recrear ni eliminar `auditoria`. |

Las migraciones se aplican por contexto y en el orden mostrado. Las semillas,
limpiezas y reversiones no se ejecutan automáticamente ni se aplicaron contra
una instancia real durante esta fase.
