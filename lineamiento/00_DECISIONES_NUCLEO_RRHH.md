# Lineamiento aprobado para el núcleo general de GTM

Fecha de decisión: 2026-09-04  
Zona de negocio: America/Lima  
Estado: entrada aprobada para la etapa Analyst

## Objetivo de esta ejecución

Producir únicamente la primera definición conceptual del núcleo general de datos
de GTM, previa al diseño físico de base de datos.

Entregables esperados:

- `docs-proyecto/requirements.md`;
- `docs-proyecto/STACK.md`;
- `docs-proyecto/DEFINITION_OF_DONE.md`;
- `docs-proyecto/er-diagram-v1.md`;
- preguntas materiales pendientes; y
- checkpoint humano para aprobar stack y modelo conceptual.

No se generará ni ejecutará SQL, DDL, DML, migraciones o conexiones a motores.
No se iniciará el DB Agent, Backend Agent ni agentes Frontend.

## Límite funcional de la versión conceptual v1

- El alcance principal es el núcleo transversal de GTM.
- Alimentación y Evaluaciones se usan únicamente como referencias para detectar
  dependencias hacia el núcleo.
- Esta versión no diseña las entidades internas de Alimentación ni de
  Evaluaciones.
- No se administran en GTM insumos, inventario, compras, recetas o costos de
  Alimentos y Bebidas. Esos datos existen en otra base de datos.
- Declaraciones Juradas se considera un módulo independiente y no forma parte
  del núcleo inicial.
- Marcaciones y cálculos de asistencia pertenecerán a un módulo separado. Las
  marcaciones ya existen en otra base de datos; el núcleo solo debe prever una
  referencia o frontera de integración, sin duplicarlas en esta versión.

## Identidad y vida laboral

- `Colaborador` es el centro funcional de los procesos de GTM.
- Una persona existe una sola vez en GTM aunque cese, reingrese, cambie de
  empresa o mantenga varias planillas simultáneas.
- Se separará la identidad civil de la identidad laboral mediante los conceptos
  `Persona` y `Colaborador`.
- El colaborador conserva un código estable propio de GTM.
- Un reingreso abre una nueva relación laboral. Aunque SAP lo registre como una
  persona o registro nuevo, GTM lo vincula con la misma persona y colaborador.
- Los códigos SAP son referencias externas históricas y pueden cambiar entre
  relaciones laborales o reingresos.

## Empresas, planillas y relación laboral

- GTM utilizará una base común para las empresas de la corporación.
- La empresa debe quedar explícita en cada relación laboral.
- La autorización podrá tener alcance por empresa cuando corresponda.
- Un colaborador puede tener múltiples relaciones laborales activas al mismo
  tiempo, una por empresa o planilla.
- Cada relación laboral tiene un único cargo, una única área y un único centro
  de costo vigentes en un momento determinado.
- Si una persona tiene varias planillas, cada relación laboral posee de manera
  independiente empresa, cargo, área, centro de costo, código SAP y horario.
- Los cambios históricos no sobrescriben la información anterior: se cierran
  vigencias y se crean nuevas asignaciones o relaciones cuando corresponda.

## Organización y SAP

- GTM administra maestros propios de cargos y áreas porque el modelo de SAP no
  representa completamente el requerimiento funcional.
- SAP actúa como sistema externo de referencia, no como modelo conceptual del
  núcleo GTM.
- Deben poder conservarse, como referencias externas, al menos:
  - código SAP del empleado;
  - código SAP relacionado con el cargo o posición; y
  - código SAP del horario.
- En SAP varias personas que funcionalmente comparten el mismo cargo de GTM
  pueden poseer códigos de cargo o posición SAP diferentes.
- El centro de costo proviene de SAP y se asocia a la relación laboral o a su
  asignación vigente, sin convertirlo en el identificador conceptual del área o
  cargo GTM.

## Jerarquía

- Una relación laboral puede tener hasta dos jefaturas simultáneas en casos
  excepcionales.
- La jerarquía debe apoyarse en cargos y áreas propios de GTM.
- La relación de jefatura debe admitir tipo, vigencia y una forma de distinguir
  la jefatura principal de una secundaria o funcional.
- La selección de qué jefatura usa cada módulo se decidirá en el diseño del
  módulo correspondiente; el núcleo no debe fijar una regla única para todos.

## Horarios

- SAP posee códigos de horario.
- GTM debe guardar tanto el código SAP del horario como la definición de horario
  necesaria para operar sin depender de una consulta SAP en tiempo real.
- El horario se asocia a la relación laboral, de modo que dos planillas activas
  puedan tener horarios distintos.
- El modelo conceptual debe permitir horarios rotativos, vigencias y cambios
  históricos. El detalle físico de ciclos, calendarios y excepciones queda para
  la etapa DB posterior.

## Identidad digital, seguridad y autorización

- Un colaborador no necesariamente tiene un usuario habilitado para las
  aplicaciones corporativas.
- Todo Colaborador tendrá una cuenta Microsoft corporativa básica, sin que eso
  conceda por sí mismo acceso a una aplicación GTM.
- Seguridad y autorización se administran fuera de la base GTM.
- GTM no almacena contraseñas, sesiones, tokens ni tablas internas de usuarios,
  roles o permisos.
- El sistema externo de seguridad enlaza al usuario con el código estable del
  colaborador.
- Una cuenta Microsoft o Microsoft Entra acredita identidad, pero no concede
  roles automáticamente.
- Los roles agrupan acciones o permisos.
- Los permisos pueden tener alcance por aplicación, módulo, empresa o sede.
- El backend revalida cada acción y aplica denegación por defecto.
- La cuenta Microsoft corporativa es obligatoria para el Colaborador. Correo
  corporativo, UPN u Object ID se tratan como contacto o identificador externo,
  no como clave funcional del colaborador; cuál de ellos es autoritativo y cómo
  se historiza sigue siendo una decisión de diseño pendiente.
- La integración recomendada entre Seguridad y GTM es mediante API, sin claves
  foráneas entre bases ni acceso funcional directo a tablas GTM.

## Notificaciones

- Las notificaciones se consideran una capacidad transversal separada del
  núcleo de identidad laboral.
- Los módulos podrán solicitar notificaciones dirigidas a un colaborador sin
  duplicar su identidad ni administrar autorización.
- Canales, plantillas, preferencias y tecnología de entrega se definirán en su
  etapa específica.

## Stack confirmado para documentar

- Base de datos: Microsoft SQL Server 2017.
- Backend existente: NestJS con TypeScript en `hub-gtm`.
- Web existente: Angular en `front-gtm`.
- Móvil existente: Kotlin y Jetpack Compose en `AppMovilGoldenGtm`.
- Contrato de API: REST documentado mediante OpenAPI.
- Arquitectura actual: monolito modular; una separación como microservicio
  requerirá una decisión posterior explícita.

La confirmación de este stack autoriza únicamente su registro por el Analyst.
No autoriza diseño físico, SQL ni implementación.

## Restricciones del análisis

- No inventar campos físicos, índices, stored procedures o estrategia de
  migración.
- No copiar datos de producción ni conectarse a las bases existentes.
- No diseñar tablas de seguridad.
- No duplicar marcaciones existentes ni datos operativos de A&B.
- Mantener historial por vigencia y separar datos maestros, transaccionales,
  integraciones y snapshots.
- Las ambigüedades materiales deben quedar en preguntas abiertas y no resolverse
  por supuesto del Analyst.

## Convención de idioma para el diseño físico

- Todos los objetos propios de SQL Server deben nombrarse en español.
- La regla comprende schemas, tablas, columnas, vistas, procedimientos
  almacenados, funciones, restricciones, índices, secuencias y archivos de
  migración.
- Los nombres propios o identificadores de sistemas externos, como SAP y
  Microsoft, pueden conservar su denominación reconocible dentro de nombres
  compuestos en español.
- No se crearán objetos duplicados o alias en inglés para representar el mismo
  concepto.
