# Alimentación — baseline conceptual de SQL Server

Estado: Oficial  
Responsable de aprobación: Usuario propietario de la documentación  
Fecha de oficialización: 2026-09-04

## Propósito

Este documento establece la primera referencia conceptual para persistir
Alimentación en SQL Server dentro del modelo general de GTM. Define propiedad de
datos, grupos conceptuales, invariantes, transacciones y límites que deberán
respetarse cuando se diseñe el diagrama ER.

No define nombres físicos de base de datos, schemas, tablas, columnas, índices,
vistas, funciones o stored procedures. Tampoco contiene ni autoriza DDL.

## Decisión de primera versión

La primera versión se plantea sobre una sola base SQL Server de GTM, organizada
mediante límites lógicos claramente diferenciados:

```text
SQL Server GTM
├── Núcleo común GTM
│   ├── Colaborador
│   ├── Horarios laborales
│   ├── Sedes y contexto autorizado
│   └── Identidad organizacional
├── Alimentación
│   ├── Planificaciones y menús
│   ├── Reservas
│   ├── QR y entregas
│   ├── Configuración operativa
│   ├── Idempotencia
│   └── Auditoría
└── Otros módulos
    └── Evaluaciones y futuras extensiones
```

Esta separación es conceptual. El futuro diagrama ER y el DB Agent propondrán
cómo materializarla y presentarán esa propuesta para aprobación antes de crear
objetos físicos.

Una separación posterior en bases independientes requerirá una nueva decisión
de arquitectura, contratos de integración, estrategia de migración y aprobación
humana. No se considera implícita en este baseline.

## Responsabilidades de SQL Server y backend

SQL Server es la fuente persistente de verdad para el estado del módulo, sus
restricciones de integridad, su configuración aprobada, la auditoría y la hora
oficial de las transiciones.

El backend continúa siendo la única autoridad accesible por las aplicaciones
para autenticar y autorizar actores, coordinar casos de uso, aplicar el contrato
REST y ejecutar transacciones. Web y móvil nunca se conectan directamente a SQL
Server ni deciden el resultado final usando datos locales.

## Núcleo común GTM

El núcleo común gobierna al colaborador como entidad central de GTM. Como
mínimo, comprende conceptualmente:

- identificador estable del colaborador;
- estado activo o autorizado;
- horario laboral vigente y su historial cuando corresponda;
- sedes o contextos autorizados; y
- identidad organizacional necesaria para resolver el actor.

Alimentación consume este contexto y no crea un colaborador paralelo. No duplica
como maestro el nombre, documento, correo, cargo, horario completo u otros datos
personales.

Las referencias desde Alimentación utilizan identificadores estables. Los datos
de presentación necesarios para una operación se obtienen por el backend desde
el núcleo común. Cualquier snapshot mínimo requerido por auditoría o evidencia
de entrega deberá justificarse en el futuro modelo y aplicar minimización.

## Área lógica de Alimentación

### Planificación y menú

El modelo deberá representar:

- una planificación mensual por sede;
- estado `BORRADOR`, `PUBLICADA_ABIERTA`, `PUBLICADA_CERRADA` o `CONSOLIDADA`;
- versión para control de concurrencia;
- una combinación de fecha, sede y tipo de servicio;
- menú o marca explícita de día sin servicio;
- nombre, descripción, componentes informativos e imagen opcional;
- copia de contenido sin compartir identidad transaccional; y
- instante y actor de publicación, cierre, reapertura y consolidación.

La planificación consolidada es inmutable desde las aplicaciones. El modelo
debe impedir su reapertura y cualquier modificación posterior de menús o días de
servicio.

### Reserva

Cada reserva vincula conceptualmente:

- colaborador central;
- planificación y menú aplicables;
- fecha;
- sede;
- servicio asignado: `DESAYUNO`, `ALMUERZO` o `CENA`;
- estado `RESERVADA`, `CANCELADA`, `ENTREGADA` o `NO_RECOGIDA`; y
- instantes y actores de sus transiciones.

El servicio registrado es la fotografía de la asignación determinada desde el
horario del colaborador al reservar. Un cambio posterior de horario no modifica
silenciosamente una reserva.

Una cancelación conserva el registro. Si el colaborador vuelve a reservar la
misma fecha mientras la planificación continúa abierta, se crea una reserva
nueva y trazable; no se reactiva la cancelada.

### QR

El modelo conceptual conserva:

- identificador interno del QR;
- reserva propietaria;
- estado `VIGENTE`, `VENCIDO`, `UTILIZADO` o `REVOCADO`;
- emisión y vencimiento;
- uso o revocación, cuando corresponda; y
- correlación necesaria para auditoría e idempotencia.

El valor presentado en el QR es opaco. No se almacena en claro como dato
reutilizable, no contiene PII legible y no se registra en logs o auditoría. La
estrategia criptográfica o de hash se decidirá durante el diseño técnico.

### Entrega

La entrega representa únicamente el retiro presencial normal confirmado. Debe
vincular reserva, QR utilizado, operador, sede, servicio y hora oficial.

No existe persistencia para entrega excepcional, catálogo de motivos de
excepción, entrega manual ni entrega offline dentro del módulo.

### Configuración operativa

La configuración se administra fuera de las aplicaciones por personal técnico
autorizado. Conceptualmente comprende:

- relación entre rangos de horario laboral y desayuno, almuerzo o cena;
- ventanas de retiro por servicio y sede;
- beacons autorizados y su relación con la sede;
- parámetros de muestreo, permanencia y salida de rango; y
- vigencia o versión de cada configuración cuando resulte aplicable.

No existirá gestor web ni endpoints de mantenimiento para estos valores en la
primera versión. El mecanismo físico de modificación —scripts controlados,
procedimientos u otra alternativa— se decidirá con el diseño de datos. Toda
modificación deberá ser atribuible, validada y auditable, sin almacenar
contraseñas de beacons.

### Idempotencia

Las mutaciones definidas en el
[contrato REST](../contratos/API_REST.md) deberán poder reconocer una intención
repetida sin duplicar efectos. El diseño futuro definirá el registro de claves,
hash o huella de solicitud, resultado, expiración técnica y correlación.

No se conserva una clave reutilizable en respuestas, logs o reportes. La
retención del soporte de idempotencia puede ser técnica y acotada; no modifica
la retención indefinida de los registros funcionales y de auditoría.

### Auditoría

La auditoría es lógica y físicamente distinguible de los logs técnicos. Sus
eventos son de solo anexado y conservan los campos mínimos aprobados en
[Auditoría y reportes](../funcionalidades/05_AUDITORIA_Y_REPORTES.md).

Las aplicaciones no editan ni eliminan eventos. El futuro diseño debe impedir
que los permisos operativos ordinarios alteren el historial.

## Invariantes obligatorias

El diagrama ER y las migraciones futuras deberán proponer mecanismos verificables
para garantizar:

1. una planificación mensual por sede dentro del alcance definido;
2. un único menú por `fecha + sede + tipo de servicio`;
3. exclusión mutua entre menú reservable y día sin servicio;
4. una sola reserva activa por `colaborador + fecha`, sin importar sede o
   servicio;
5. ninguna capacidad máxima, cupo o lista de espera;
6. una sola transición de consolidación y ausencia de reapertura posterior;
7. como máximo un QR `VIGENTE` por reserva;
8. imposibilidad de reactivar QR vencidos, utilizados o revocados;
9. como máximo una entrega confirmada por reserva;
10. consumo del QR y entrega de la reserva dentro de una única transacción;
11. estados terminales de reserva y QR sin transiciones inválidas; y
12. ausencia de efectos duplicados ante reintentos idempotentes.

La técnica concreta puede usar restricciones, índices filtrados, transacciones,
control de versión u otros mecanismos aprobados. Este documento fija el
resultado, no selecciona todavía el objeto SQL.

## Límites transaccionales

Deberán tratarse como operaciones consistentes, entre otras:

- creación individual de una reserva y validación de unicidad;
- cancelación y actualización del conteo vigente;
- edición o copia de menú con control de versión;
- cierre, reapertura y consolidación de planificación;
- emisión de un QR nuevo y revocación del anterior vigente;
- revocación por salida de rango o segundo plano;
- confirmación de entrega, consumo del QR y transición de la reserva; y
- registro de auditoría asociado con cada mutación crítica.

La indisponibilidad de una notificación no revierte un cambio de menú ya
confirmado. El diseño posterior definirá cómo registrar y reintentar el intento
sin introducir una cola o tecnología no aprobada en este baseline.

## Tiempo oficial

SQL Server proporciona el instante oficial usado para registrar y evaluar las
transiciones del módulo. Los clientes y el proceso backend no sustituyen esa
autoridad con el reloj local del dispositivo o servidor de aplicación.

La zona de negocio es `America/Lima`. La función SQL, tipo de dato y estrategia
para manejar offset o cambios temporales se decidirán según la versión real del
motor durante el diseño físico.

No se recupera el corte histórico de las `23:59:59`. La creación y cancelación
dependen del estado manual de la planificación; las ventanas temporales vigentes
corresponden al retiro y emisión/validación del QR por servicio.

## Retención

Planificaciones, menús, reservas, entregas normales y auditoría se conservan
indefinidamente en esta primera versión. No existe archivado, anonimización,
eliminación programada ni borrado desde las aplicaciones.

La retención indefinida no permite conservar contraseñas, secretos, tokens
externos, contenido claro del QR, muestras BLE innecesarias ni una copia completa
del perfil del colaborador.

El diseño futuro deberá considerar crecimiento, respaldo, restauración,
integridad y acceso restringido. No se heredan jobs o políticas de purga de las
fuentes históricas.

## Seguridad y acceso

- Las credenciales y cadenas de conexión permanecen fuera del repositorio y de
  la documentación funcional.
- Backend usa una identidad técnica de mínimo privilegio.
- Web y móvil no reciben acceso SQL.
- La administración manual de configuración requiere un actor técnico
  autorizado y trazabilidad.
- Ningún agente recibe `sysadmin` ni acceso transversal por defecto.
- Datos de Producción no se copian a Local sin un proceso de anonimización y
  autorización independiente.
- Una conexión o cambio fuera del alcance aprobado requiere un checkpoint
  estricto adicional.

## Flujo futuro con el Orquestador

Cuando el usuario autorice iniciar diseño y desarrollo:

1. Analyst convertirá este baseline y los requisitos oficiales en un primer
   diagrama ER y registrará SQL Server en `STACK.md`.
2. El usuario confirmará el stack.
3. DB Agent inspeccionará en solo lectura la estructura real autorizada, si ya
   existe, y presentará diferencias.
4. DB Agent propondrá el modelo físico, diagrama ER final y migraciones
   versionadas con trazabilidad.
5. El usuario aprobará el schema antes de que Backend trabaje sobre él.
6. Una aprobación separada será obligatoria antes de ejecutar el DDL inicial en
   un motor real.
7. Tocar otra base, schema compartido u objeto fuera del alcance requerirá una
   autorización estricta adicional.

La aprobación de este documento no inicia ninguno de esos pasos.

## Criterios para el futuro diagrama ER

El diagrama deberá:

- distinguir núcleo común y propiedad de Alimentación;
- representar cardinalidades y estados sin capacidad ni excepciones;
- mostrar cómo se referencia al colaborador central;
- identificar entidades maestras, transaccionales, de configuración y auditoría;
- soportar los 20 casos contractuales sin duplicar datos de presentación;
- explicar cada restricción de unicidad y cada límite transaccional;
- indicar qué decisiones permanecen conceptuales hasta conocer versión y
  estructura real de SQL Server; y
- recibir aprobación antes de traducirse a migraciones.

## Reconciliación documental

| Contenido encontrado | Clasificación | Tratamiento oficial |
|---|---|---|
| SQL Server como única persistencia de la versión | Absorbible | Se mantiene; no se incorpora MongoDB ni doble escritura. |
| Colaborador local duplicado desde claims | Contradictorio | Se sustituye por referencia al colaborador central de GTM. |
| Una base relacional para reservas y entrega | Transformable | Se adopta una base GTM con límites lógicos para núcleo y módulos. |
| Unicidad por colaborador, fecha, servicio y sala | Transformable | Se reemplaza por una reserva activa por colaborador y fecha entre todas las sedes y servicios. |
| Capacidad y último cupo | Contradictorio | Se eliminan por completo. |
| Corte fijo de `23:59:59` | Contradictorio | Se reemplaza por estados manuales de planificación. |
| Ventana global `08:00–23:00` | Transformable | Se sustituye por ventanas configurables por sede y servicio. |
| Tres emisiones y diez segundos BLE | Transformable | Se conservan como parámetros configurables, no como constantes oficiales. |
| `inafecto` y entrega excepcional | Contradictorio | No se modelan. |
| Configuración directa en SQL Server | Absorbible con control | Se mantiene fuera de las aplicaciones, exigiendo autorización, validación y auditoría. |
| Retención indefinida | Absorbible | Se mantiene para registros funcionales y auditoría, con minimización de datos. |
| Tablas, procedures, índices y jobs históricos | Excluido | No se heredan; el futuro modelo parte del lineamiento vigente y de la inspección autorizada. |

## Fuentes trazadas

- `Documentacion General de Alimentacioin/Lineamiento/02_documento_funcional_tobe.md`.
- `Documentacion General de Alimentacioin/Lineamiento/03_arquitectura_software.md`.
- `Documentacion General de Alimentacioin/decisiones/REGISTRO_DECISIONES_APROBADAS.md`.
- `GoldenGtm Movil/08 - BLE MOKO M2 y QR.md`.
- `GoldenGtm Movil/18 - Seguridad y privacidad.md`.
- `GoldenGtm Movil/Handoff - Acceso a base de datos Desarrollo.md`.
- `01_ALCANCE_Y_DECISIONES_GENERALES.md`, evidencia histórica del destino.
- `02_MAPA_DE_RESPONSABILIDADES.md`, evidencia histórica del destino.
- `03_CONTRATO_COMPARTIDO.md`, evidencia histórica del destino.
- `04_CRITERIOS_TRANSVERSALES.md`, evidencia histórica del destino.
- Documentos funcionales, de roles y contrato REST oficiales de esta carpeta.

Las fuentes históricas parten de
`C:\Users\cavalos\Desktop\Todo Documentaicon\Documentacion Alimentacion` y
permanecen intactas.

## Decisiones aprobadas

| Fecha | Decisión | Autoridad |
|---|---|---|
| 2026-09-04 | La primera versión utilizará una base SQL Server de GTM con separación lógica entre núcleo común, Alimentación y otros módulos. | Usuario propietario de la documentación |
| 2026-09-04 | Colaborador, horario y contexto autorizado pertenecen al núcleo común; Alimentación los referencia sin crear maestros paralelos. | Usuario propietario de la documentación |
| 2026-09-04 | El baseline es conceptual; nombres físicos y diagrama ER se definirán posteriormente mediante el Analyst y DB Agent con checkpoints humanos. | Usuario propietario de la documentación |

## Límites de esta oficialización

No se inspeccionó ni conectó una instancia SQL Server. No se validaron versión,
compatibilidad, esquema existente, volúmenes, rendimiento, backups o restauración.
No se generaron ni ejecutaron scripts, migraciones, DDL o DML.
