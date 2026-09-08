# Requerimientos — núcleo general de datos GTM

## 1. Control del documento

- Etapa: Analyst, previa al diseño físico de base de datos.
- Versión: conceptual v1.
- Fecha de análisis: 2026-09-04.
- Zona de negocio confirmada: `America/Lima`.
- Estado: modelo conceptual v1 aprobado por el usuario el 2026-09-04; preguntas
  materiales diferidas y DB Agent no autorizado.
- Centro funcional: `Colaborador` como sujeto de los procesos GTM.

## 2. Alcance

Esta versión define el núcleo transversal que identifica a una persona, mantiene
su identidad estable como colaborador y conserva sus relaciones laborales,
asignaciones organizacionales, jefaturas, horarios y referencias SAP con
historia de vigencia.

Alimentación y Evaluaciones se consideran consumidores futuros de este núcleo.
Sus entidades internas, reglas transaccionales y modelos físicos no forman parte
de esta versión.

## 3. Fuentes analizadas

Se leyeron completos los trece archivos presentes bajo `lineamiento/` antes de
producir estos artefactos:

1. `00_DECISIONES_NUCLEO_RRHH.md`.
2. `01_PROPUESTA_REESTRUCTURACION_BD_RRHH.md`.
3. `referencias-modulos/Alimentacion/00_INDICE_Y_GOBIERNO.md`.
4. `referencias-modulos/Alimentacion/01_CONTEXTO_Y_ALCANCE.md`.
5. `referencias-modulos/Alimentacion/02_ROLES_Y_PERMISOS.md`.
6. `referencias-modulos/Alimentacion/referencias-tecnicas/SQL_SERVER_BASELINE.md`.
7. `referencias-modulos/Evaluaciones/00_INDICE_Y_GOBIERNO.md`.
8. `referencias-modulos/Evaluaciones/01_CONTEXTO_Y_ALCANCE.md`.
9. `referencias-modulos/Evaluaciones/02_ROLES_Y_PERMISOS.md`.
10. `referencias-modulos/Evaluaciones/funcionalidades/02_FORMATOS_DE_EVALUACION.md`.
11. `referencias-modulos/Evaluaciones/funcionalidades/03_PERIODOS.md`.
12. `referencias-modulos/Evaluaciones/funcionalidades/04_MIS_EVALUACIONES.md`.
13. `referencias-modulos/Evaluaciones/referencias-tecnicas/SQL_SERVER_BASELINE.md`.

Para el núcleo prevalece `00_DECISIONES_NUCLEO_RRHH.md`. La propuesta aporta
candidatos y preguntas, mientras que las referencias de módulos solo aportan
dependencias hacia el núcleo y no autorizan trasladar sus entidades internas.

## 4. Entidades conceptuales

### 4.1 Identidad

- **Persona**: identidad natural o civil única. No contiene cargo, área, planilla
  ni usuario de aplicaciones.
- **Tipo de documento**: catálogo conceptual para clasificar los documentos de
  identidad.
- **Documento de persona**: documento asociado a una persona, con posibilidad
  de distinguir el principal, país de emisión, vigencia y estado. La
  obligatoriedad y unicidad exactas están pendientes de decisión.
- **Cuenta Microsoft corporativa**: cuenta digital externa obligatoria para todo
  Colaborador. GTM conserva la referencia conceptual necesaria mediante correo
  corporativo, UPN u Object ID, todavía sin decidir cuál será autoritativo ni
  cómo se historizará. No representa un usuario GTM, no concede acceso y no
  almacena credenciales, sesiones o tokens.
- **Colaborador**: identidad laboral estable de una persona dentro de GTM. Posee
  un código funcional estable y es la referencia central de los módulos.

### 4.2 Vida laboral y organización

- **Empresa**: empresa legal u operativa de la corporación. Todas comparten una
  base GTM, pero cada relación laboral identifica expresamente su empresa.
- **Relación laboral**: vínculo histórico de un colaborador con una empresa o
  planilla. Admite coexistencia con otras relaciones activas y constituye una
  nueva ocurrencia ante un reingreso.
- **Sede**: contexto físico u operativo utilizado por la asignación laboral y
  por alcances autorizados cuando corresponda.
- **Área**: maestro organizacional propio de GTM, independiente del modelo
  insuficiente de SAP.
- **Cargo**: maestro funcional propio de GTM. Varias personas con el mismo cargo
  GTM pueden tener códigos de cargo o posición SAP diferentes.
- **Asignación organizacional**: tramo histórico de una relación laboral que
  resuelve una empresa, sede, área, cargo y centro de costo vigentes. En un
  instante, una relación laboral tiene un solo valor vigente de cada concepto.
- **Centro de costo SAP**: referencia proveniente de SAP asociada a la
  asignación vigente; no identifica conceptualmente al área ni al cargo GTM.
- **Jefatura de relación laboral**: relación histórica entre una relación
  laboral subordinada y otra relación laboral que actúa como jefatura. Admite
  tipo, vigencia y distinción principal/secundaria o funcional.

### 4.3 Horarios e integración SAP

- **Horario laboral**: maestro local de códigos de horario necesario para operar
  sin consulta SAP en tiempo real; clasifica cada horario como mañana, tarde,
  noche o madrugada.
- **Vigencia de horario**: asignación de un código de horario a una relación
  laboral y fecha. Cada relación admite como máximo un código por día; el mismo
  código puede repetirse todos los días del mes que corresponda.
- **Referencia SAP de relación laboral**: conserva el código SAP de empleado y
  su contexto histórico por relación laboral o reingreso.
- **Referencia SAP de asignación**: conserva el código SAP de cargo o posición
  correspondiente a una asignación, sin convertirlo en el cargo maestro GTM.
- **Referencia SAP de horario**: conserva el código SAP del horario vinculado a
  la definición local.

Estos nombres son conceptos de dominio, no nombres aprobados de tablas, schemas
o columnas.

## 5. Flujos del núcleo

### F-01 — Identificar persona y colaborador

1. Se identifica o registra una Persona sin duplicarla por empresa, planilla o
   código SAP.
2. Si participa laboralmente en GTM, se vincula con un único Colaborador.
3. El Colaborador conserva su código GTM estable durante ceses y reingresos.
4. Todo Colaborador queda conceptualmente asociado con su cuenta Microsoft
   corporativa básica, sin habilitar por ello acceso a aplicaciones.

### F-02 — Incorporar una relación laboral

1. Se selecciona el Colaborador estable.
2. Se abre una relación laboral para la empresa o planilla correspondiente.
3. Se registra su código SAP de empleado como referencia de esa relación.
4. Se abre la asignación organizacional y el horario aplicables con su vigencia.
5. La nueva relación puede coexistir con relaciones activas de otras empresas.

### F-03 — Registrar un reingreso

1. Se conserva Persona y Colaborador.
2. La relación laboral anterior permanece cerrada e histórica.
3. Se crea una nueva relación laboral.
4. Se registra el nuevo código SAP aunque SAP lo considere un registro distinto.

### F-04 — Cambiar contexto organizacional

1. Se cierra la vigencia de la asignación anterior.
2. Se crea una nueva asignación para la misma relación laboral.
3. Se conserva sin sobrescritura el cargo, área, sede, centro de costo y
   referencia de posición SAP anteriores.

### F-05 — Cambiar horario

1. Se conserva la definición local y el código SAP del horario aplicable.
2. Se registra o actualiza exclusivamente la fecha afectada, sin alterar los
   demás días ni los horarios de otras planillas del colaborador.

### F-06 — Mantener jefaturas

1. Se identifica la relación laboral subordinada.
2. Se vincula una relación laboral de jefatura con tipo, prioridad y vigencia.
3. Excepcionalmente puede coexistir una segunda jefatura vigente.
4. Cada módulo decide cuál jefatura aplicará a su proceso; el núcleo no impone
   una elección transversal.

### F-07 — Resolver contexto para un módulo consumidor

1. El módulo solicita el contexto mediante el backend y un identificador estable
   de Colaborador.
2. El backend resuelve la relación laboral pertinente según el contexto del
   proceso; esa regla exacta debe ser definida por cada módulo.
3. El módulo recibe solo los datos necesarios y no crea maestros paralelos.

### F-08 — Vincular identidad y autorización externas

1. Todo Colaborador posee una cuenta Microsoft corporativa básica.
2. Microsoft/Entra acredita identidad, pero no concede roles GTM.
3. El sistema externo de Seguridad vincula su usuario con el código estable del
   Colaborador.
4. La integración recomendada y confirmada es mediante API, sin claves foráneas
   entre bases ni acceso funcional directo a tablas GTM.
5. El backend revalida cada acción con denegación por defecto.

## 6. Reglas de negocio

- **RN-01 — Persona única**: un cese, reingreso, cambio de empresa o doble
  planilla no crea otra Persona para el mismo individuo.
- **RN-02 — Colaborador estable**: el mismo individuo conserva su Colaborador y
  código GTM a través de su historia laboral.
- **RN-03 — Sin usuario interno**: GTM no contiene `IdUsuario`, contraseñas,
  sesiones, tokens, roles, permisos ni claves foráneas a Seguridad.
- **RN-04 — Múltiples planillas**: un Colaborador puede tener más de una relación
  laboral activa simultáneamente, con contexto independiente por empresa o
  planilla.
- **RN-05 — Reingreso histórico**: un reingreso crea una nueva relación laboral;
  no reactiva ni sobrescribe la anterior.
- **RN-06 — Empresa explícita**: toda relación laboral pertenece a una empresa.
- **RN-07 — Asignación única vigente**: cada relación laboral tiene, en un
  instante, un único cargo, área, sede y centro de costo vigentes. Los cambios
  cierran vigencias y abren nuevas asignaciones.
- **RN-08 — Maestro GTM**: Cargo y Área son maestros propios de GTM. Un código
  SAP de posición no reemplaza su identidad funcional.
- **RN-09 — Referencias SAP por contexto**: códigos SAP de empleado, posición,
  centro de costo y horario se conservan en el contexto laboral al que
  corresponden y con historia.
- **RN-10 — Sin dependencia SAP en tiempo real**: GTM conserva localmente la
  definición de horario necesaria para operar.
- **RN-11 — Horario por relación**: dos relaciones laborales simultáneas del
  mismo Colaborador pueden tener horarios diferentes.
- **RN-12 — Hasta dos jefaturas**: una relación laboral admite como máximo dos
  jefaturas vigentes; deben poder distinguirse por tipo y prioridad.
- **RN-13 — Selección modular de jefatura**: el núcleo no decide una jefatura
  universal para Alimentación, Evaluaciones u otros módulos.
- **RN-14 — Historial por vigencia**: relaciones, asignaciones, horarios y
  jefaturas no se corrigen sobrescribiendo períodos históricos.
- **RN-15 — Cuenta Microsoft obligatoria sin autorización implícita**: todo
  Colaborador tiene una cuenta Microsoft corporativa básica, pero esa cuenta no
  implica tener usuario habilitado en una aplicación ni permisos efectivos.
- **RN-16 — Autorización externa por acciones**: los roles externos agrupan
  acciones o permisos y admiten alcances por aplicación, módulo, empresa o sede.
- **RN-17 — Módulos referencian Colaborador**: Alimentación, Evaluaciones y
  futuros módulos operan con Colaborador, no con un usuario de Seguridad.
- **RN-18 — No duplicar marcaciones**: el núcleo no copia las marcaciones ni los
  cálculos de asistencia existentes en otra base.
- **RN-19 — No duplicar A&B**: el núcleo no guarda compras, inventarios, recetas,
  costos ni otros datos operativos de la base externa de A&B.
- **RN-20 — Snapshots del consumidor**: un módulo puede conservar un snapshot
  mínimo justificado para procesos publicados; ese snapshot no sustituye a los
  maestros del núcleo. Evaluaciones conserva esta necesidad al publicar
  períodos.
- **RN-21 — Base común**: las empresas de la corporación comparten la base GTM,
  con separación lógica de dominios y empresa explícita en la vida laboral.

## 7. Roles, actores y permisos

El núcleo no administra roles ni permisos. Los siguientes son actores de
interacción, no tablas ni roles internos de la base GTM:

- **Colaborador**: sujeto de los procesos y de sus propias relaciones laborales;
  posee una cuenta Microsoft corporativa básica, pero no obtiene acceso solo por
  existir en el núcleo o por tener esa cuenta.
- **RRHH autorizado**: actor candidato para mantener información del núcleo. El
  alcance manual frente a importaciones continúa pendiente.
- **Sistema SAP**: fuente externa de códigos y datos de referencia acordados; no
  es la fuente conceptual de Persona, Colaborador, Cargo o Área.
- **Sistema externo de Seguridad**: autentica/asigna usuarios, roles, acciones y
  alcances; enlaza al Colaborador por su código estable y consume GTM por API.
- **Backend GTM**: única autoridad aplicativa para exponer el núcleo a clientes,
  revalidar acciones y aplicar denegación por defecto.
- **Módulos consumidores**: Alimentación, Evaluaciones y futuras capacidades
  acceden al núcleo por el backend y no duplican identidad laboral.

Recomendación de autorización confirmada: RBAC basado en acciones, con roles
como agrupadores y asignaciones acotables por aplicación, módulo, empresa y
sede. La posesión de un rol homónimo en otra aplicación no hereda autoridad.

## 8. Estados y vigencias

- **Persona**: el catálogo de estados y sus transiciones no está definido.
- **Colaborador**: la propuesta menciona `PREINGRESO`, `ACTIVO`, `SUSPENDIDO`,
  `LICENCIA` y `CESADO`, pero debe decidirse si este estado es propio o derivado
  de las relaciones laborales antes de aprobarlo.
- **Relación laboral**: debe expresar inicio, término, motivo y vigencia. El
  catálogo exacto de estados no está aprobado.
- **Asignación organizacional**: vigente durante un intervalo; un cambio cierra
  el intervalo anterior y abre uno nuevo.
- **Jefatura**: vigente durante un intervalo y distinguida como principal,
  secundaria o funcional según la decisión final de catálogo.
- **Vigencia de horario**: conserva los cambios por intervalo sin alterar los
  períodos anteriores.

No se fijan enumeraciones físicas ni transiciones adicionales en esta etapa.

## 9. Fronteras e integraciones

- **SAP**: aporta códigos externos de empleado, posición/cargo, centro de costo
  y horario. El mecanismo de sincronización y la autoridad por atributo están
  pendientes.
- **Seguridad**: sistema y persistencia externos. Se integra por API y referencia
  el código estable del Colaborador.
- **Microsoft/Entra**: proveedor de la cuenta corporativa básica obligatoria de
  cada Colaborador; acredita identidad, pero no es fuente de autorización
  funcional GTM.
- **Marcaciones/Asistencia**: módulo y base separados. No se duplican
  marcaciones; solo se prevé un límite de integración futura.
- **Base de A&B**: fuente externa para insumos, inventarios, compras, recetas y
  costos; estos datos no ingresan al núcleo.
- **Notificaciones**: capacidad transversal separada que recibe destinatarios
  Colaborador; canales, plantillas y preferencias se diseñarán aparte.
- **Declaraciones Juradas**: módulo independiente y diferido.
- **Alimentación**: consumidor futuro de Colaborador, horario, sede y contexto
  autorizado; no se diseñan aquí reservas, menús, QR o entregas.
- **Evaluaciones**: consumidor futuro de Colaborador, cargo, área y jefaturas;
  mantiene snapshots al publicar, sin diseñar aquí sus tablas.

## 10. Criterios de aceptación del análisis

- **CA-01**: una Persona y un Colaborador pueden mostrar dos relaciones laborales
  activas en empresas diferentes, cada una con asignación, código SAP y horario
  propios.
- **CA-02**: un reingreso conserva Persona, Colaborador y código GTM, mantiene
  cerrada la relación anterior y crea otra referencia de empleado SAP.
- **CA-03**: un cambio de cargo, área, sede o centro de costo deja visible la
  asignación histórica y una sola asignación vigente para la relación.
- **CA-04**: el modelo permite una jefatura habitual y una segunda jefatura
  excepcional vigentes, sin imponer cuál consume Evaluaciones.
- **CA-05**: el horario se resuelve por relación laboral y conserva tanto la
  definición local como su referencia SAP e historia.
- **CA-06**: todo Colaborador tiene una referencia conceptual obligatoria a su
  cuenta Microsoft corporativa, sin que ninguna entidad del núcleo represente
  usuarios habilitados, roles, permisos, sesiones, tokens o contraseñas.
- **CA-07**: Alimentación y Evaluaciones aparecen únicamente como consumidores o
  fronteras, sin entidades internas en el ER conceptual.
- **CA-08**: marcaciones y datos operativos A&B permanecen fuera de la base GTM
  y sin copias conceptuales en el núcleo.
- **CA-09**: las decisiones no confirmadas están identificadas en la sección de
  preguntas materiales y no se presentan como definitivas.
- **CA-10**: no existen scripts, DDL, migraciones, stored procedures ni
  conexiones a motores como resultado de esta etapa.

## 11. Plataformas de frontend requeridas

- **Ninguna para la etapa Analyst actual**: el alcance solicitado es
  documentación y modelo conceptual de datos; no se entregaron prototipos para
  esta etapa ni se autoriza implementación de interfaz.
- **Web existente — Angular**: consumidor futuro confirmado mediante
  `front-gtm`; no se instancia Frontend Agent ahora.
- **Móvil Android existente — Kotlin/Jetpack Compose**: consumidor futuro
  confirmado mediante `AppMovilGoldenGtm`; no se instancia Frontend Agent ahora.
- **Desktop**: no requerido por los lineamientos analizados.
- **iOS**: solo aparece como evolución planificada del módulo Alimentación; no
  forma parte del núcleo v1 ni autoriza una plataforma en esta ejecución.

## 12. Fuera de alcance

- Diseño físico, schemas, tablas, columnas, tipos, índices o particiones.
- SQL, DDL, DML, stored procedures, migraciones o conexiones a bases.
- Implementación o modificación de backend, web o móvil.
- Migración efectiva de `PersonalSap.*` o de cualquier estructura existente.
- Diseño interno de Alimentación, Evaluaciones, Asistencia, Notificaciones o
  Declaraciones Juradas.
- Administración de usuarios, roles, permisos o credenciales.
- Copia de marcaciones, datos productivos o información operativa de A&B.

## 13. Preguntas materiales pendientes

Estas decisiones deben resolverse o aceptar explícitamente su diferimiento antes
de que un DB Agent refine el modelo físico:

1. **Código SAP del colaborador**: ¿qué formato, longitud, reglas de cambio,
   unicidad y regla de no reutilización debe cumplir?
2. **Unicidad de Persona**: ¿qué combinación de tipo, número y país de documento
   identifica duplicados? ¿Cómo se registra una persona sin documento o con un
   documento todavía no validado?
3. **Documento principal**: ¿todo Colaborador con relación activa debe tener
   exactamente un documento principal y qué tipos documentales se aceptan?
4. **Estado de Colaborador**: ¿es un estado administrado o se deriva de sus
   relaciones laborales? ¿Cómo se refleja que una relación esté cesada y otra
   permanezca activa?
5. **Empresa frente a planilla**: ¿una planilla requiere un concepto propio?
   ¿Se permite más de una relación laboral simultánea del mismo Colaborador en
   una misma empresa?
6. **Catálogos organizacionales**: ¿Área y Cargo son corporativos reutilizables
   entre empresas o pertenecen a una empresa? ¿Un Cargo pertenece a una sola
   Área o puede utilizarse en varias?
7. **Jerarquía de cargos y áreas**: ¿se conserva `hierarchyid` en el futuro
   diseño físico? ¿La jerarquía oficial se mantiene en áreas, cargos, ambas, o
   se calcula desde las asignaciones?
8. **Centro de costo SAP**: ¿GTM conserva solo código y vigencia o también nombre,
   empresa y otros datos descriptivos sincronizados? ¿Cuál es su regla de
   unicidad en SAP?
9. **Identificadores SAP**: ¿los códigos de empleado, posición y horario son
   únicos globalmente o solo dentro de sociedad/empresa/mandante SAP?
10. **Sincronización SAP**: ¿la carga será por API, lote, archivo o proceso
    manual? ¿Qué sistema es autoridad para cada atributo y cómo se tratan
    correcciones retroactivas?
11. **Horarios diarios**: el alcance actual registra un código y su tipo de
    turno por relación y fecha; ciclos, calendarios y excepciones quedan fuera
    del modelo.
12. **Jefaturas**: ¿una jefatura puede cruzar empresas? ¿El límite de dos incluye
    todos los tipos y es obligatorio distinguir exactamente una principal
    cuando exista alguna?
13. **Sede base frente a sedes autorizadas**: ¿la asignación tiene una sola sede
    laboral vigente y los alcances adicionales se resuelven exclusivamente en
    Seguridad, o el núcleo debe conservar relaciones con varias sedes?
14. **Identidad Microsoft**: ¿cuál de UPN, correo u Object ID será el
    identificador externo autoritativo y cómo se historizarán sus cambios?
15. **Administración del núcleo**: ¿RRHH podrá crear y corregir datos manualmente,
    se alimentarán solo mediante integraciones, o se permitirán ambos caminos?
16. **Compatibilidad con Evaluaciones**: ¿la siguiente etapa deberá coexistir
    temporalmente con `PersonalSap.*` o planificará sustitución/migración directa?
17. **Auditoría y retención**: ¿qué cambios del núcleo deben generar auditoría
    funcional, por cuánto tiempo se conservan datos personales y qué política
    aplica tras el cese?
