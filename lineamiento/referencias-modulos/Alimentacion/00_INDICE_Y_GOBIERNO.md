# Alimentación — índice y gobierno funcional

Estado: Oficial  
Responsable de aprobación: Usuario propietario de la documentación  
Fecha de oficialización: 2026-09-03
Fecha de auditoría final: 2026-09-04

## Propósito

Esta carpeta es la fuente oficial de lineamientos generales del módulo
Alimentación de GTM. Su contenido reúne el comportamiento integral del módulo y
las responsabilidades coordinadas de la web, la aplicación móvil, el backend,
SQL Server y las integraciones relacionadas.

La separación por documentos facilita el mantenimiento, pero no divide el
módulo en fuentes de verdad independientes. Cada funcionalidad debe describirse
de extremo a extremo y señalar qué presenta cada cliente, qué valida el backend,
qué información necesita y cómo se acepta su resultado.

## Alcance documental general

El conjunto documental comprende:

- Administración web de menús, reservas, entrega presencial, consultas y
  reportes que resulten aprobados.
- Experiencia móvil del colaborador para autenticación, consulta, reserva,
  cancelación, proximidad BLE y presentación protegida del QR.
- Servicios y reglas de backend compartidos por los consumidores autorizados.
- Contrato REST canónico del módulo bajo el namespace aprobado.
- Necesidades conceptuales, invariantes y reglas temporales cuya autoridad
  corresponda a SQL Server.
- Identidad, autorización, seguridad e integraciones externas necesarias para
  el funcionamiento del módulo.
- UX/UI, estados, errores, criterios de aceptación, pruebas y trazabilidad.

Android es la plataforma móvil de la primera etapa. iOS permanece como evolución
planificada con paridad funcional y sin crear reglas de negocio o contratos
paralelos. Esta secuencia no convierte el lineamiento general en documentación
exclusiva de Android.

## Catálogo documental y estado

| Documento | Responsabilidad | Estado |
|---|---|---|
| `00_INDICE_Y_GOBIERNO.md` | Alcance documental, autoridad, catálogo y método de promoción. | Oficial |
| [Contexto y alcance](01_CONTEXTO_Y_ALCANCE.md) | Problema, objetivos, alcance del producto, actores y exclusiones. | Oficial |
| [Roles y permisos](02_ROLES_Y_PERMISOS.md) | Roles, permisos, identidad, autorización y denegación por defecto. | Oficial |
| [Menús y publicación](funcionalidades/01_MENUS_Y_PUBLICACION.md) | Gestión, publicación y consulta de menús por fecha, sede y tipo de servicio. | Oficial |
| [Reservas](funcionalidades/02_RESERVAS.md) | Creación, cancelación, consulta, unicidad y estados de reserva. | Oficial |
| [QR y BLE](funcionalidades/03_QR_Y_BLE.md) | Proximidad BLE, emisión, vigencia, ocultamiento y revocación del QR. | Oficial |
| [Entrega presencial](funcionalidades/04_ENTREGA_PRESENCIAL.md) | Validación y confirmación de la entrega presencial normal. | Oficial |
| [Auditoría y reportes](funcionalidades/05_AUDITORIA_Y_REPORTES.md) | Auditoría operativa, consultas, exportación y reportes aprobados. | Oficial |
| [UX/UI y referencias visuales](ux/UX_UI_Y_MOCKS.md) | Flujos, pantallas, estados, accesibilidad, mocks móviles y espacio de diseños web. | Oficial |
| [Contrato REST](contratos/API_REST.md) | Operaciones, seguridad, solicitudes, respuestas, errores e idempotencia. | Oficial |
| [OpenAPI Alimentación v1](contratos/alimentacion-v1.openapi.yaml) | Especificación legible por máquina del contrato REST aprobado. | Oficial |
| [Baseline frontend y backend](referencias-tecnicas/FRONTEND_BACKEND_BASELINE.md) | Asignación de proyectos, límites de autoridad, contrato compartido y relación con el Orquestador. | Oficial |
| [Baseline móvil, BLE y beacon](referencias-tecnicas/MOVIL_BLE_BASELINE.md) | Plataforma inicial, proximidad, configuración, privacidad y validación física futura. | Oficial |
| [Baseline conceptual SQL Server](referencias-tecnicas/SQL_SERVER_BASELINE.md) | Organización lógica, propiedad de datos e invariantes para el futuro diseño SQL Server. | Oficial |
| [Criterios de aceptación y pruebas](calidad/CRITERIOS_ACEPTACION_Y_PRUEBAS.md) | Casos funcionales, técnicos, físicos, E2E y UAT, con evidencias y umbrales pendientes identificados. | Oficial |
| [Historial de decisiones](gobierno/HISTORIAL_DECISIONES.md) | Decisiones vigentes, sustituidas, excluidas y diferidas, con autoridad temática. | Oficial |
| [Matriz de trazabilidad](gobierno/MATRIZ_TRAZABILIDAD.md) | Relación individual entre fuentes, clasificación, autoridades oficiales, faltantes y evidencia. | Oficial |
| [Auditoría final](gobierno/AUDITORIA_FINAL.md) | Cobertura, consistencia, enlaces, pendientes y cierre documental. | Oficial — cierre aprobado |

## Responsabilidad transversal de las funcionalidades

Cada documento de `funcionalidades/` debe identificar, cuando corresponda:

1. Actores, precondiciones y disparador.
2. Flujo principal, alternativas permitidas y errores.
3. Estados y reglas temporales.
4. Acciones y presentación de la aplicación web.
5. Acciones y presentación de la aplicación móvil.
6. Validaciones y garantías del backend.
7. Datos conceptuales e invariantes de persistencia.
8. Operaciones del contrato REST afectadas.
9. Reglas de seguridad, autorización y privacidad.
10. Criterios de aceptación, pruebas y evidencia.

Una aplicación puede implementar una responsabilidad distinta, pero no definir
unilateralmente una regla general ni mantener una versión paralela del contrato.

## Reglas de autoridad y promoción

1. Solo un documento de esta carpeta con estado **Oficial** es fuente de verdad
   para el tema que declara gobernar.
2. La documentación histórica es evidencia; su estado anterior no se hereda.
3. Cada unidad se analiza y clasifica antes de promoverse.
4. Una promoción exige informe, resolución de preguntas materiales y aprobación
   explícita del responsable de la documentación.
5. Un documento oficial no contiene alternativas funcionales abiertas,
   contradicciones sin resolver ni requisitos presentados como hechos pendientes.
6. Toda decisión aprobada actualiza las referencias afectadas de funcionalidades,
   UX, contrato, datos, pruebas, trazabilidad e historial.
7. Las fuentes originales no se modifican, archivan ni eliminan durante esta
   migración.
8. La auditoría final no autoriza implementación; cualquier ciclo de desarrollo,
   arquitectura, schema, DDL o despliegue mantiene sus propios checkpoints.

## Evidencia histórica preexistente en el destino

Los cinco archivos que precedían a esta estructura fueron analizados, absorbidos
y trazados. Con autorización del usuario, el 2026-09-04 se reubicaron sin cambiar
su contenido en `evidencia-historica/entradas-destino/`:

- `01_ALCANCE_Y_DECISIONES_GENERALES.md`.
- `02_MAPA_DE_RESPONSABILIDADES.md`.
- `03_CONTRATO_COMPARTIDO.md`.
- `04_CRITERIOS_TRANSVERSALES.md`.
- `05_PENDIENTES_Y_TRAZABILIDAD.md`.

No son fuentes oficiales paralelas. Sus hashes SHA-256 se conservaron y la
[matriz de trazabilidad](gobierno/MATRIZ_TRAZABILIDAD.md) registra su receptor.

## Fuentes históricas

- `C:\Users\cavalos\Desktop\Todo Documentaicon\Documentacion Alimentacion\Documentacion General de Alimentacioin`.
- `C:\Users\cavalos\Desktop\Todo Documentaicon\Documentacion Alimentacion\GoldenGtm Movil`.
- Los cinco archivos de entrada controlada identificados en la sección anterior.

Las fuentes históricas permanecen sin modificaciones. La trazabilidad detallada
por archivo se encuentra en la
[matriz oficial](gobierno/MATRIZ_TRAZABILIDAD.md).

## Contenido excluido de esta etapa

- Implementación o modificación de código.
- Creación o modificación de schemas, tablas, índices, stored procedures o DDL.
- Ejecución de SQL o conexión a bases de datos.
- Preparación de repositorios, ambientes, despliegues o secretos.
- Adopción automática de arquitecturas, contratos, roles o estados históricos.
- Documentación y decisiones del módulo Evaluaciones.

## Criterio de cierre documental

La migración solo podrá declararse cerrada cuando:

- todas las fuentes estén clasificadas y trazadas;
- cada tema tenga una única fuente oficial;
- no existan contradicciones ni preguntas materiales abiertas dentro de los
  documentos oficiales;
- los contratos y referencias internas sean coherentes;
- las reglas funcionales tengan criterios de aceptación y pruebas trazables;
- los enlaces internos hayan sido validados; y
- `gobierno/AUDITORIA_FINAL.md` registre el resultado y sus limitaciones.

## Historial de cambios

| Fecha | Cambio | Aprobado por |
|---|---|---|
| 2026-09-03 | Creación del índice oficial y adopción de una estructura alineada con Evaluaciones. | Usuario propietario de la documentación |
| 2026-09-03 | Se confirma que Alimentación es un lineamiento general transversal para web, móvil, backend, SQL Server e integraciones. | Usuario propietario de la documentación |
| 2026-09-03 | Se oficializan los roles y permisos separados por proyecto, incluido un `ROOT_ADMIN` propio para cada contexto. | Usuario propietario de la documentación |
| 2026-09-03 | Se oficializa la planificación mensual, publicación, copia de menús, notificación de cambios y consolidación irreversible. | Usuario propietario de la documentación |
| 2026-09-03 | Se oficializa la reserva individual por card, la unicidad por colaborador y fecha, la cancelación controlada y sus estados. | Usuario propietario de la documentación |
| 2026-09-03 | Se incorporan desayuno, almuerzo y cena según el horario central del colaborador y se oficializa el ciclo seguro de QR y proximidad BLE. | Usuario propietario de la documentación |
| 2026-09-03 | Se oficializa la entrega presencial en dos pasos, mediante cámara o lector HID, sin excepciones ni operación offline. | Usuario propietario de la documentación |
| 2026-09-03 | Se oficializan los reportes operativos agregados, la exportación XLSX temporal y la auditoría inmutable con retención indefinida. | Usuario propietario de la documentación |
| 2026-09-03 | Se oficializa la UX/UI transversal, se incorpora la referencia móvil trazable y se reserva el espacio controlado para los diseños web A&B. | Usuario propietario de la documentación |
| 2026-09-03 | Se oficializan el contrato REST canónico bajo `/api/v1/alimentacion` y su especificación OpenAPI v1, sin rutas paralelas por consumidor. | Usuario propietario de la documentación |
| 2026-09-04 | Se oficializa el baseline conceptual de una base SQL Server GTM con núcleo común y límites lógicos por módulo, sin aprobar aún modelo físico ni DDL. | Usuario propietario de la documentación |
| 2026-09-04 | Se oficializa la asignación de `hub-gtm`, `front-gtm` y `AppMovilGoldenGtm`, con backend como autoridad aplicativa y stack concreto sujeto a `STACK.md`. | Usuario propietario de la documentación |
| 2026-09-04 | Se oficializa el baseline Android y BLE con MOKO M2/iBeacon como referencia inicial, parámetros configurables y validación física posterior. | Usuario propietario de la documentación |
| 2026-09-04 | Se oficializa el catálogo consolidado de criterios y pruebas, sin atribuir ejecuciones ni inventar umbrales técnicos. | Usuario propietario de la documentación |
| 2026-09-04 | Se oficializa el historial central de decisiones vigentes, sustituidas, excluidas y diferidas. | Usuario propietario de la documentación |
| 2026-09-04 | Se oficializa la matriz de trazabilidad de fuentes históricas, entradas controladas, recursos visuales y evidencia estática. | Usuario propietario de la documentación |
| 2026-09-04 | Se reubican las cinco entradas preexistentes de la raíz como evidencia histórica no normativa, conservando sus hashes. | Usuario propietario de la documentación |
| 2026-09-04 | Se aprueba la auditoría final y se cierra la migración documental con pendientes técnicos declarados. | Usuario propietario de la documentación |
