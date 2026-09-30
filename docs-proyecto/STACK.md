# Stack confirmado — núcleo GTM y compatibilidad USERMANAGEMENTCORP

Fecha: 2026-09-25
Fase: reestructuración de scripts del núcleo y extensión aditiva de USERMANAGEMENTCORP

## Alcance tecnológico de esta fase

| Componente | Decisión | Estado |
|---|---|---|
| Motor de base de datos | Microsoft SQL Server 2017 | Confirmado |
| Lenguaje de scripts | T-SQL compatible con SQL Server 2017 | Confirmado |
| Distribución | Modelo B: una instancia CO y una instancia hija por UO | Confirmado |
| Empresas | Una UO y su instancia hija pueden contener varias empresas | Confirmado |
| Integración SAP | Kafka → consumidor backend → TVP → stored procedure → `CO.integracion.PersonalSAPStaging` | Confirmado conceptualmente |
| Identidad Entra | Token validado y resuelto por backend fuera de `USERMANAGEMENTCORP` | Confirmado conceptualmente |
| Referencia al núcleo | `dbo.Usuario` → procedure de resolución exacta → `USERMANAGEMENTCORP.dbo.UsuarioReferenciaColaborador` → GUID lógico de `CO.rrhh.Colaborador` | Confirmado conceptualmente |
| Backend | Fuera de alcance de implementación de esta fase | No seleccionado para ejecución |
| Frontend web | Fuera de alcance de esta fase | No aplica |
| Frontend móvil | Fuera de alcance de esta fase | No aplica |
| Frontend desktop | Fuera de alcance de esta fase | No aplica |
| Paradigma/contrato API | Fuera de alcance de esta fase | No seleccionado |

El lineamiento registra aplicaciones existentes en NestJS, Angular y Kotlin,
así como REST/OpenAPI, pero esta tarea no implementa ni modifica esas capas y no
las usa para seleccionar agentes de ejecución.

## Convenciones de base de datos

- Objetos propios nombrados en español, con las excepciones externas o nombres
  aprobados expresamente.
- Migraciones versionadas separadas en:
  - `db/migrations/nucleo/corporativo/`
  - `db/migrations/nucleo/unidad_organizativa/`
- La extensión de `USERMANAGEMENTCORP` se entrega mediante migración
  incremental; `ScriptCreacion_v1.sql` debe quedar alineado para instalaciones
  nuevas sin eliminar ni renombrar objetos legacy.
- Una misma secuencia de scripts UO se reutiliza para todas las instancias
  hijas.
- No se crean bases de datos desde las migraciones del núcleo.
- No existen FKs entre instancias; los vínculos distribuidos usan GUID
  corporativos.
- La hora de persistencia se obtiene desde SQL Server.
- Web, móvil y otros clientes no se conectan directamente a SQL Server.
- El backend es responsable de autenticación, autorización y coordinación
  entre instancias; el núcleo no contiene tablas de seguridad.
- Entra ID autentica y el backend obtiene el `UsuarioAcceso` legacy o el
  `UsuarioId` antes de acceder a SQL Server. `USERMANAGEMENTCORP` no recibe ni
  persiste datos de identidad externa, tokens, refresh tokens, contraseñas ni
  secretos nuevos.
- `dbo.usp_ResolverContextoUsuarioNucleoPorAcceso` resuelve un usuario legacy
  por `UsuarioAcceso` mediante igualdad exacta o por `UsuarioId`. Su auditoría
  local se usa exclusivamente en el `CATCH` de ese procedure nuevo.
- `USERMANAGEMENTCORP` conserva la autoridad de usuarios, roles y permisos.
  Los GUID hacia CO son referencias lógicas sin FK entre bases y se validan por
  el backend durante el aprovisionamiento.

## Objetos de integración SAP previstos

- Schema CO `integracion`.
- Tabla persistente `integracion.PersonalSAPStaging`.
- Tipo TVP para recibir lotes estructurados de eventos completos.
- Stored procedure de recepción idempotente consumido por el backend.
- Índice único por `KafkaTopic + KafkaPartition + KafkaOffset`.
- Índice único por `IdEventoOrigen`.
- Payload JSON original y 63 campos SAP deserializados como texto.

No se incorpora una segunda tabla de eventos/cargas, lógica de promoción hacia
el núcleo, Schema Registry, librería Kafka ni stack backend en esta fase.

## Ambientes y ejecución

Los artefactos se preparan como scripts. Aplicar DDL/DML sobre una instancia
real requiere autorización humana expresa y un contexto de base de datos
acotado. Las verificaciones de aplicación desde cero se realizarán en una base
desechable o entorno autorizado durante la etapa del DB Agent.

### Topología de desarrollo vigente

Esta topología describe exclusivamente el ambiente de desarrollo actual. No es
una configuración de producción ni contiene credenciales, cadenas de conexión,
puertos o secretos.

| Instancia | Base de datos | Responsabilidad canónica |
|---|---|---|
| `GSBEDEV01\CO` | `PERSONALMANEGEMENTCORP` | Datos corporativos de persona y colaborador. |
| `GSBEDEV01\CO` | `USERMANAGEMENTCORP` | Usuario, identidad y autorización de aplicación. |
| `GSBEDEV01\GI` | `PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA` | Empresa de la UO, sede, relación laboral, cargo, jefatura y área. |
| `GSBEDEV01\GI` | `GTM` | Estado propio de los módulos GTM, incluido Alimentación. |

`GTM` consulta las sedes de su propia UO mediante
`PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA.organizacion.Sede`; los permisos de
lectura requeridos ya existen en este ambiente. Los datos de CO se resuelven
desde backend o mediante un mecanismo de integración explícitamente aprobado.
La excepción aprobada para el historial de retiros es el linked server de solo
lectura `GSBEDEV01\CO`, limitado a
`PERSONALMANEGEMENTCORP.rrhh.vw_ColaboradorConsulta` para filtrar por nombre;
ningún store debe consultar tablas corporativas directamente.
