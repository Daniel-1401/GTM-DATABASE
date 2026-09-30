# Requerimientos — reestructuración del núcleo GTM

Fecha de consolidación: 2026-09-25
Estado: alcance aprobado para modificación de scripts del núcleo y fase aditiva de compatibilidad de `USERMANAGEMENTCORP`

## Alcance

Esta fase comprende el núcleo de base de datos de GTM y sus artefactos
asociados, más una extensión aditiva de `USERMANAGEMENTCORP` para vincular sus
usuarios legacy con referencias de colaborador corporativo. Incluye las migraciones de la instancia
corporativa CO, las migraciones reutilizables de una instancia hija de unidad
organizativa (UO), la recepción inicial de eventos SAP, la semilla de prueba,
los scripts de limpieza, las reversiones y la documentación correspondiente.

Quedan fuera de esta fase:

- la modificación del módulo Alimentación, que comenzará únicamente después de
  validar el núcleo;
- reemplazar la autenticación actual contra Active Directory (AD), los
  usuarios, roles, permisos, sesiones o procedures legacy de
  `USERMANAGEMENTCORP`;
- persistir access tokens, refresh tokens, contraseñas, secretos de aplicación
  o sesiones de Entra ID;
- la promoción de datos desde SAP staging hacia las tablas maestras del núcleo;
- backend, frontend y contrato de API de los módulos funcionales;
- ejecución de DDL o DML contra una instancia real sin autorización expresa;
- nuevas restricciones de tratamiento de datos sensibles no aprobadas por el
  usuario.

## Arquitectura de despliegue aprobada

- **REQ-ARQ-001 — Modelo B:** existe una instancia corporativa CO y una
  instancia hija por cada UO.
- **REQ-ARQ-002 — Varias empresas por UO:** cada UO puede contener una o más
  empresas; una instancia hija no equivale a una empresa.
- **REQ-ARQ-003 — Separación física:** no se crean claves foráneas entre CO y
  una instancia hija, ni entre instancias hijas.
- **REQ-ARQ-004 — Identificadores corporativos:** los GUID corporativos enlazan
  lógicamente registros distribuidos y deben ser validados por operaciones de
  integración controladas.
- **REQ-ARQ-005 — Idioma:** los objetos propios de SQL Server se nombran en
  español, excepto nombres externos o nombres ya aprobados expresamente como
  `PersonalSAPStaging`.

## Entidades

### Instancia corporativa CO

- **REQ-ENT-CO-001 — TipoDocumento:** catálogo de tipos de documento.
- **REQ-ENT-CO-002 — EstadoCivil:** catálogo corporativo de estados civiles.
- **REQ-ENT-CO-003 — Genero:** catálogo corporativo de géneros.
- **REQ-ENT-CO-004 — Pais:** catálogo corporativo de países.
- **REQ-ENT-CO-005 — UnidadOrganizativa:** maestro de las UO desplegadas en
  instancias hijas; expone un identificador corporativo estable.
- **REQ-ENT-CO-006 — Empresa:** maestro corporativo de empresas; cada empresa
  pertenece a una UO y expone `IdEmpresaCorporativa`.
- **REQ-ENT-CO-007 — Persona:** identidad civil única de una persona dentro de
  GTM.
- **REQ-ENT-CO-008 — DocumentoPersona:** documentos históricos de una persona,
  incluido el documento principal vigente.
- **REQ-ENT-CO-009 — Colaborador:** identidad laboral estable y única por
  persona; expone `IdColaboradorCorporativo` y no contiene `IdUsuario`.
- **REQ-ENT-CO-010 — PersonalSAPStaging:** bandeja append-only que conserva cada
  evento de personal recibido desde Kafka con metadatos de transporte, payload
  original y los 63 campos de `FROMSAP.xlsx` como texto o `NULL`.

### USERMANAGEMENTCORP: referencia al núcleo

- **REQ-ENT-UMC-001 — Usuario (existente):** el usuario legacy continúa siendo
  la autoridad de roles, permisos, sistemas y locales. Su clave
  `dbo.Usuario.UsuarioId` no se reemplaza ni se renombra.
- **REQ-ENT-UMC-002 — UsuarioReferenciaColaborador:** vínculo de un
  `UsuarioId` legacy con `IdUsuarioCorporativo` estable y, opcionalmente, con
  `IdColaboradorCorporativo` del núcleo CO. Los GUID corporativos son
  referencias lógicas, no claves foráneas entre bases.

### Instancia hija de UO

- **REQ-ENT-UO-001 — ConfiguracionUnidadOrganizativa:** fila única que identifica
  la UO propietaria de la instancia.
- **REQ-ENT-UO-002 — EmpresaReferencia:** proyección local de una empresa del
  maestro CO; conserva el identificador corporativo y solo admite empresas de la
  UO configurada.
- **REQ-ENT-UO-003 — Sede:** sede local perteneciente a una empresa proyectada.
- **REQ-ENT-UO-004 — Area:** área operativa local perteneciente a una empresa
  proyectada.
- **REQ-ENT-UO-005 — Cargo:** cargo maestro funcional local perteneciente a una
  empresa proyectada.
- **REQ-ENT-UO-006 — CargoSAP:** referencia de un código de cargo o posición SAP
  hacia un cargo GTM.
- **REQ-ENT-UO-007 — CargoJefatura:** jerarquía vigente entre cargos de la misma
  empresa.
- **REQ-ENT-UO-008 — RelacionLaboral:** relación de un colaborador corporativo
  con una empresa y planilla locales; conserva código de colaborador SAP, cargo
  SAP, ingreso y cese.
- **REQ-ENT-UO-009 — AsignacionOrganizacional:** contexto donde opera una
  relación laboral, aunque la relación tenga origen en otra instancia hija;
  conserva relación laboral corporativa, colaborador, UO de origen, empresa
  empleadora, empresa local de operación, sede y área.
- **REQ-ENT-UO-010 — HorarioLaboral:** maestro local de horarios por empresa con
  código GTM y referencia SAP.
- **REQ-ENT-UO-011 — VigenciaHorario:** asignación de un horario a una relación
  laboral para una fecha.
- **REQ-ENT-UO-012 — Postulante:** identidad de una persona que todavía no es
  `Persona` ni `Colaborador` del núcleo.
- **REQ-ENT-UO-013 — ArchivoPostulante:** metadatos y referencia de almacenamiento
  de archivos del postulante.
- **REQ-ENT-UO-014 — HistorialEstadoPostulante:** historial append-only de los
  estados informados para el postulante.

## Flujos

### FLU-001 — Aprovisionar CO desde cero

1. Crear los schemas corporativos requeridos.
2. Crear catálogos, organización corporativa, identidad civil y colaborador.
3. Crear el schema y objetos de integración SAP.
4. Verificar todas las claves, relaciones e índices del modelo corporativo.

### FLU-002 — Aprovisionar una instancia hija de UO

1. Crear los schemas locales.
2. Registrar exactamente una configuración de UO.
3. Sincronizar las empresas pertenecientes a esa UO en `EmpresaReferencia`.
4. Crear organización, relaciones laborales, asignaciones, horarios y selección.
5. Verificar que la misma secuencia sea reutilizable para cualquier UO.

### FLU-003 — Sincronizar EmpresaReferencia

1. Un proceso backend obtiene desde CO las empresas de la UO destino.
2. El proceso crea o actualiza la proyección local conservando
   `IdEmpresaCorporativa` e `IdUnidadOrganizativaCorporativa`.
3. La base hija rechaza una empresa cuya UO corporativa no coincida con su fila
   de configuración.
4. CO continúa siendo la fuente maestra; la proyección local no crea una segunda
   autoridad de empresa.

### FLU-004 — Registrar o reactivar una relación laboral

1. Resolver el colaborador mediante `IdColaboradorCorporativo`.
2. Resolver la empresa local mediante `EmpresaReferencia`.
3. Si no existe la combinación colaborador–empresa, crearla.
4. Si existe y fue cesada, reactivarla y actualizar sus datos laborales.
5. Si la persona opera, mantener exactamente una asignación organizacional
   activa en la instancia donde opera.

### FLU-005 — Recibir eventos de personal SAP

1. SAP publica en Kafka una fotografía completa de un colaborador.
2. La clave del mensaje es `companyCode:employeeCode`, para conservar el orden
   por empresa y colaborador dentro de una partición.
3. El consumidor backend deserializa y valida el mensaje.
4. El consumidor construye un TVP con una o varias filas y conserva el payload
   JSON original como evidencia.
5. Un stored procedure inserta en `integracion.PersonalSAPStaging` las filas que
   todavía no existen.
6. Un reenvío con el mismo `topic + partition + offset` o el mismo
   `IdEventoOrigen` no crea una segunda fila y se considera atendido.
7. El backend confirma el offset de Kafka únicamente después del `COMMIT` de SQL
   Server.
8. Esta fase termina en staging; no transforma ni promueve datos hacia Persona,
   Colaborador, Empresa o RelacionLaboral.

### FLU-006 — Preparar datos de prueba

1. La semilla se ejecuta explícitamente para CO o para una instancia hija de UO.
2. Los GUID deterministas vinculan el escenario sintético entre ambas
   ejecuciones sin depender del nombre físico de la base.
3. La semilla puede repetirse sin duplicar registros y debe cubrir las
   relaciones e invariantes esenciales del schema vigente.

### FLU-007 — Limpiar y revertir

1. Cada contexto dispone de un script de limpieza propio que elimina datos de
   prueba respetando el orden de dependencias y conserva el schema.
2. Cada contexto dispone de una reversión completa propia que elimina primero
   los objetos dependientes y finalmente sus schemas.
3. Limpieza y reversión deben mantenerse alineadas con todas las migraciones del
   núcleo, incluido el staging SAP de CO.

### FLU-008 — Vincular usuario legacy con núcleo

1. El backend autentica y autoriza al operador mediante su mecanismo externo y
   obtiene su `UsuarioAcceso` legacy o `UsuarioId` por el flujo vigente.
2. `dbo.usp_ResolverContextoUsuarioNucleoPorAcceso` resuelve por igualdad
   exacta de `UsuarioAcceso` o por `UsuarioId` el usuario legacy y su referencia
   corporativa, sin recibir datos de identidad externa.
3. Un proceso administrativo controlado crea o actualiza la referencia
   `UsuarioId` → `IdUsuarioCorporativo` y, si aplica,
   `IdColaboradorCorporativo`.
4. Antes de asociar un colaborador, el backend concilia la identidad civil con
   el núcleo por tipo y número de documento; no usa correo, nombres ni código
   SAP como clave.
5. Las cuentas técnicas, administradores externos u otros usuarios sin
   colaborador conservan el vínculo con `IdColaboradorCorporativo` nulo.

## Reglas de negocio e integridad

- **REQ-RN-001 — Persona única:** una persona se registra una sola vez aunque
  cese, reingrese o mantenga varias relaciones laborales.
- **REQ-RN-002 — Colaborador único:** existe como máximo un colaborador por
  persona y su GUID corporativo es estable.
- **REQ-RN-003 — Documento único:** no se repite la combinación de tipo, país de
  emisión y número de documento; existe como máximo un documento principal
  abierto por persona.
- **REQ-RN-004 — Empresa por UO:** toda empresa CO pertenece a una UO y toda
  `EmpresaReferencia` pertenece a la UO configurada en la hija.
- **REQ-RN-005 — Relación colaborador–empresa:** la combinación
  `IdColaboradorCorporativo + IdEmpresaReferencia` es única. El cese desactiva
  la fila; el reingreso en la misma empresa la reactiva y actualiza.
- **REQ-RN-006 — Varias empresas:** una persona puede tener relaciones en varias
  empresas de la misma UO o cambiar de empresa sin reutilizar la fila de otra
  empresa.
- **REQ-RN-007 — Cargo laboral:** la relación laboral referencia un cargo SAP de
  la misma empresa local.
- **REQ-RN-008 — Asignación en destino:** la asignación organizacional se guarda
  solo en la instancia donde la persona opera, incluso cuando la relación
  laboral procede de otra hija.
- **REQ-RN-009 — Asignación global:** toda relación laboral activa que opera debe
  tener exactamente una asignación organizacional activa en el conjunto de
  instancias. Cada hija garantiza la unicidad local por
  `IdRelacionLaboralCorporativa`; la coordinación backend debe impedir una
  segunda asignación en otra hija porque SQL Server no puede imponer una FK o
  restricción distribuida entre bases independientes.
- **REQ-RN-010 — Empresa operativa local:**
  `AsignacionOrganizacional.IdEmpresaReferencia` debe tener FK local hacia
  `EmpresaReferencia`; sede y área deben pertenecer a esa misma empresa.
- **REQ-RN-011 — Empresa empleadora:**
  `IdEmpresaEmpleadoraCorporativa` identifica globalmente a la empresa de la
  relación laboral; `IdEmpresaReferencia` identifica la empresa local donde se
  realiza la operación organizacional.
- **REQ-RN-012 — Horario diario único:** existe como máximo una vigencia de
  horario por relación laboral y fecha.
- **REQ-RN-013 — Sin FK distribuida:** los GUID de colaborador, relación, UO y
  empresa externos a la instancia se conservan sin FK física fuera de la base.
- **REQ-RN-014 — Staging único:** no se crea una tabla separada
  `EventoIntegracion` ni `CargaSAP`; cada fila de `PersonalSAPStaging` es el
  evento recibido y su historial bruto.
- **REQ-RN-015 — Evento completo:** cada mensaje SAP v1 contiene todas las 63
  propiedades dentro de `data`; cada propiedad es texto o `null`, nunca un
  parche implícito por ausencia.
- **REQ-RN-016 — Identidad del evento:** `eventId` es UUID, estable durante los
  reintentos y único en origen.
- **REQ-RN-017 — Contrato del evento:** la versión inicial usa
  `eventType = sap.personal.actualizado`, `schemaVersion = 1`, `source = SAP`,
  `occurredAt` en ISO-8601 UTC, `sourceSequence`, `companyCode`, `employeeCode`
  y `data`.
- **REQ-RN-018 — Idempotencia Kafka:** se impide la duplicación por
  `KafkaTopic + KafkaPartition + KafkaOffset` y, de manera independiente, por
  `IdEventoOrigen`.
- **REQ-RN-019 — Payload original:** el payload JSON completo se conserva junto
  con las columnas deserializadas, pero el stored procedure recibe el lote
  estructurado mediante TVP y no depende de `OPENJSON` para mapear los 63
  campos.
- **REQ-RN-020 — Append-only SAP:** staging no actualiza una fotografía anterior;
  cada evento nuevo genera una fila nueva.
- **REQ-RN-021 — Stored procedure backend:** el procedimiento de recepción debe
  seguir el contrato común de resultados y errores del repositorio, terminar
  con `@Codigo NVARCHAR(50) OUTPUT` y `@Mensaje NVARCHAR(500) OUTPUT`, y tratar
  duplicados idempotentes como recepción exitosa.
- **REQ-RN-UMC-001 — Extensión aditiva:** no se elimina, renombra ni cambia el
  comportamiento de `dbo.Usuario`, tablas de roles/permisos/locales, ni
  procedures legacy de `USERMANAGEMENTCORP`.
- **REQ-RN-UMC-002 — Referencia corporativa estable:** cada `UsuarioId` tiene
  como máximo una referencia corporativa vigente y cada
  `IdUsuarioCorporativo` es único. `IdColaboradorCorporativo` puede ser nulo;
  cuando exista una referencia vigente, no puede estar asociado a otro usuario
  vigente sin una decisión aprobada que cambie esta regla.
- **REQ-RN-UMC-003 — Sin FK distribuida:** `IdColaboradorCorporativo` se
  conserva como `UNIQUEIDENTIFIER` sin FK hacia CO. El backend valida la
  existencia del colaborador antes de crear o modificar el vínculo.
- **REQ-RN-UMC-004 — Conciliación de colaborador:** la carga inicial y cualquier
  asociación de colaborador se concilian por documento de identidad, usando un
  mapeo controlado del tipo documental entre `USERMANAGEMENTCORP` y CO; correo,
  nombre y código SAP no son claves de conciliación.
- **REQ-RN-UMC-005 — Autenticación externa:** Entra ID, AD u otro proveedor se
  validan y resuelven exclusivamente en backend. UMC no persiste ni resuelve
  datos de identidad externa, tokens o una equivalencia hacia `UsuarioAcceso`;
  el procedure nuevo recibe solamente el `UsuarioAcceso` legacy ya obtenido.
- **REQ-RN-UMC-006 — AD actual compatible:** las aplicaciones que hoy se
  autentican contra AD continúan resolviendo `UsuarioAcceso` y sus permisos por
  el mecanismo actual, sin cambios en sus procedures legacy.
- **REQ-RN-UMC-007 — Resolución exacta de contexto:** el procedure nuevo busca
  `UsuarioAcceso` mediante igualdad exacta, rechaza entrada vacía, ausencia,
  inactividad o multiplicidad anómala sin devolver datos ambiguos, y admite un
  usuario activo sin `IdColaboradorCorporativo`.
- **REQ-RN-UMC-008 — Auditoría acotada:** solo el `CATCH` del procedure nuevo
  registra fallos inesperados en la auditoría local UMC; ningún procedure legacy
  se modifica ni instrumenta.

## Campos de origen SAP v1

`PersonalSAPStaging` debe conservar, con nombres SQL normalizados, los siguientes
63 campos del origen y sus valores exactos como texto o `NULL`:

1. Sociedad
2. Codigo
3. Tipo Documento Identidad
4. Nº Documento Identidad
5. Apellido Paterno
6. Apellido Materno
7. Apellido Solter@
8. Nombres
9. Fecha de Ingreso
10. Fecha de Cese
11. Motivo Cese
12. Posicion (cargo)
13. Descripcion Posicion
14. Lugar Nacimiento
15. Fecha Nacimiento
16. Profesion
17. Codigo Area
18. Descripcion Area
19. Codigo Jefe
20. Codigo Evaluador
21. Fecha Fin de Contrato
22. Codigo Fotocheck
23. Correo Electronico
24. Evento
25. Codigo Via
26. Calle
27. Calle y Nro
28. Nro
29. Interior
30. Dpto
31. Manzana
32. Lote
33. Kilometro
34. Bloque
35. Etapa
36. Codigo Zona
37. Nombre Zona
38. Departamento
39. Provincia
40. Distrito
41. Telefono Fijo
42. Telefono Celular
43. Telefono Referencia
44. Grupo Personal
45. Descripcion Grupo Personal
46. Codigo Area Personal
47. Descripcion Area Personal
48. Codigo SubDivision
49. Descripcion SubDivision
50. Codigo Division Personal
51. Descripcion Division Personal
52. Codigo Centro Costo
53. Descripcion Centro Costo
54. Ubigeo
55. Pais
56. Nacionalidad
57. Codigo Estado civil
58. Descripcion Estado Civil
59. Campo Adicional de Direccion
60. Tratamiento
61. Cuenta Bancaria
62. Dest. Utilización
63. Clave banco

## Actores y permisos

- **Backend de integración:** único componente autorizado a sincronizar
  `EmpresaReferencia` y registrar eventos SAP mediante el contrato SQL
  aprobado. No se define su tecnología en esta fase.
- **Consumidor Kafka:** proceso backend que recibe el evento, crea el TVP,
  ejecuta la persistencia y confirma el offset después del `COMMIT`.
- **Módulos GTM:** consumen colaboradores, relaciones, asignaciones y horarios;
  no administran usuarios dentro del núcleo.
- **Operador técnico autorizado:** ejecuta migraciones, semillas, limpieza o
  reversión solamente en el contexto y ambiente expresamente autorizados.
- **Backend autenticado:** valida la identidad externa y obtiene el
  `UsuarioAcceso` legacy antes de invocar la resolución de contexto UMC. Ningún
  cliente se conecta directamente a SQL Server.
- **Administrador autorizado:** aprovisiona y mantiene los vínculos de usuario
  con el núcleo mediante el proceso backend controlado.

La extensión UMC agrega únicamente la referencia de usuario aprobada; no crea
roles SQL, tablas de identidad externa ni sustitutos de usuarios, roles o
permisos legacy. CO y UO continúan sin tablas de seguridad.

## Estados

- **RelacionLaboral:** activa; cesada/inactiva con fecha de cese. El reingreso
  reactiva la misma combinación colaborador–empresa.
- **AsignacionOrganizacional:** activa o inactiva; la versión actual no define
  historial de asignaciones.
- **Maestros y catálogos:** activos o inactivos según su indicador local.
- **PersonalSAPStaging:** no tiene ciclo de procesamiento aprobado; es un
  registro append-only de recepción.
- **Postulante:** conserva el texto de estado y su historial, pero esta fase no
  inventa un catálogo ni transiciones no definidas.

## Criterios de aceptación

- **CA-001:** las migraciones CO aplican desde cero sobre SQL Server 2017 y solo
  crean objetos corporativos e integración SAP.
- **CA-002:** las migraciones UO aplican desde cero sobre SQL Server 2017 y la
  misma secuencia sirve para una UO con una o varias empresas.
- **CA-003:** no existen FKs físicas entre bases. CO y UO no dependen de
  objetos de `USERMANAGEMENTCORP`; los GUID de la extensión UMC hacia CO son
  referencias lógicas documentadas.
- **CA-004:** el diagrama, las migraciones y `TABLAS_NUCLEO.md` describen una
  instancia hija por UO, nunca una instancia hija por empresa.
- **CA-005:** las restricciones verifican pertenencia de sede, área, cargo,
  horario y asignación a su empresa local.
- **CA-006:** la unicidad colaborador–empresa permite cesar y reactivar una fila
  sin duplicarla.
- **CA-007:** una asignación puede representar una relación procedente de otra
  hija sin crear una FK distribuida, y queda documentado el límite de garantía
  global.
- **CA-008:** `PersonalSAPStaging` contiene metadatos Kafka, payload original y
  las 63 columnas del origen.
- **CA-009:** un lote TVP admite una o varias filas; reintentar el mismo offset o
  `eventId` no duplica datos ni provoca un ciclo de error.
- **CA-010:** no existe una segunda tabla persistente de evento/carga SAP y no
  existe lógica staging → núcleo.
- **CA-011:** las semillas CO/UO son repetibles y compatibles con el schema
  final.
- **CA-012:** cada limpieza y reversión cubre todos los objetos de su contexto en
  orden de dependencias.
- **CA-013:** la documentación del núcleo, el diagrama ER, la semilla, limpieza y
  reversiones quedan alineados con las migraciones.
- **CA-014:** ningún archivo del módulo Alimentación se modifica durante esta
  fase.
- **CA-UMC-001:** una migración incremental de `USERMANAGEMENTCORP` crea
  `dbo.UsuarioReferenciaColaborador` sin modificar ni eliminar objetos legacy.
- **CA-UMC-002:** `UsuarioReferenciaColaborador` entrega una identidad de operador
  corporativa estable y admite usuarios sin colaborador; no define FK física
  hacia CO.
- **CA-UMC-003:** el backend valida la identidad externa y resuelve el usuario
  legacy fuera de UMC; la base no persiste ni mapea datos de identidad externa
  o tokens.
- **CA-UMC-004:** existe semilla controlada, limpieza y reversión de los objetos
  UMC nuevos, sin borrar datos legacy de `Usuario`, roles, permisos o locales.
- **CA-UMC-005:** las asociaciones iniciales de usuario con colaborador se
  documentan como conciliación por documento de identidad y registran las
  excepciones ambiguas para revisión, sin asociación automática por correo,
  nombre o código SAP.
- **CA-UMC-006:** `dbo.usp_ResolverContextoUsuarioNucleoPorAcceso` devuelve el
  contexto de un usuario activo único por `UsuarioAcceso` exacto o `UsuarioId` y
  emplea el contrato estándar de códigos, mensajes y auditoría de errores
  inesperados.

## Decisiones confirmadas para implementación

- No se crean tablas, procedures ni auditoría para Microsoft Entra ID; la
  resolución de identidad externa queda fuera de la base de datos. UMC agrega
  únicamente `dbo.UsuarioReferenciaColaborador`, la auditoría local acotada y
  `dbo.usp_ResolverContextoUsuarioNucleoPorAcceso` para leer un
  `UsuarioAcceso` legacy exacto o un `UsuarioId`.

## Plataformas de frontend requeridas

- **Ninguna en esta fase.** El alcance actual es exclusivamente el núcleo de
  base de datos y no incluye flujos de interfaz ni prototipos a implementar.

## Fuentes de trazabilidad

- `lineamiento/00_DECISIONES_NUCLEO_RRHH.md`
- `lineamiento/01_PROPUESTA_REESTRUCTURACION_BD_RRHH.md`
- `docs-proyecto/nucleo/TABLAS_NUCLEO.md`
- `db/migrations/nucleo/corporativo/`
- `db/migrations/nucleo/unidad_organizativa/`
- `db/data_prueba/nucleo/001_semilla_datos_prueba_nucleo_corp.sql`
- `db/data_prueba/limpieza/`
- `db/reversiones/`
- `db/migrations/usermanagementcorp/ScriptCreacion_v1.sql`
- `docs-proyecto/usermanagementcorp/TABLAS_REFERENCIA_COLABORADOR.md`
- `C:/Users/cavalos/Documents/FROMSAP.xlsx`
