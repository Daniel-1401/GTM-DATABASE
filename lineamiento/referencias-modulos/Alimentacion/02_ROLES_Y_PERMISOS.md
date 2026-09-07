# Alimentación — roles y permisos

Estado: Oficial  
Responsable de aprobación: Usuario propietario de la documentación  
Fecha de oficialización: 2026-09-03

## Propósito

Este documento define los actores, roles y límites de autorización del módulo
Alimentación para sus diferentes aplicaciones. La identidad de una persona puede
ser común, pero sus roles y permisos se asignan dentro del contexto de cada
proyecto o aplicación.

La aplicación cliente puede ocultar o deshabilitar acciones según el contexto
autorizado, pero el backend vuelve a validar cada operación y es la autoridad
final de acceso.

## Principios de autorización

1. Cada proyecto mantiene su propio catálogo de roles y puede tener su propio
   rol `ROOT_ADMIN`.
2. Un `ROOT_ADMIN` solo tiene autoridad dentro del proyecto o contexto para el
   que fue asignado. El nombre coincidente no concede acceso a otros proyectos.
3. Los roles de la aplicación operativa de A&B no se heredan en GoldenGtm móvil
   ni en otras aplicaciones GTM, y viceversa.
4. Una misma persona puede tener asignaciones independientes en varias
   aplicaciones.
5. Dentro de una aplicación, una persona puede acumular más de un rol; sus
   permisos efectivos son la unión de los permisos válidos para ese contexto.
6. Los niveles numéricos históricos no constituyen una jerarquía transversal ni
   permiten inferir permisos entre aplicaciones.
7. Toda operación se autoriza por identidad autenticada, aplicación o audiencia,
   permiso requerido y alcance de sede cuando corresponda.
8. La ausencia de una asignación válida produce denegación por defecto.
9. Los clientes no asignan roles ni son fuente de verdad de autorización.
10. La administración de roles se realiza fuera de las aplicaciones de esta
    versión; no se incorpora un gestor web de roles.

## Contextos de aplicación

### Aplicación operativa de A&B

Es utilizada por el personal encargado de la planificación, publicación,
consolidación y entrega presencial. Sus roles son propios de este proyecto.

| Rol | Capacidades autorizadas | Límites |
|---|---|---|
| `ROOT_ADMIN` | Acceso total a las funcionalidades aprobadas de Alimentación dentro de la aplicación A&B. Incluye las capacidades de planificación, entrega y consulta. | No obtiene autoridad sobre GoldenGtm móvil ni otros proyectos. No habilita funcionalidades excluidas ni administración web de roles o configuración operativa. |
| `GESTOR_ALIMENTACION` | Crear y modificar la planificación; publicar; abrir, cerrar y reabrir la recepción de reservas; consultar cantidades y consolidar reservas para la planificación de A&B. | No confirma entregas por el solo hecho de poseer este rol ni accede libremente al perfil del colaborador. |
| `OPERADOR_ENTREGA` | Escanear y validar el QR; consultar el detalle mínimo autorizado como resultado del escaneo; confirmar una entrega presencial normal. | No modifica publicaciones ni confirma entregas excepcionales. No dispone de búsqueda general de colaboradores. |
| `CONSULTA_AUDITORIA` | Consultar reportes, historial y auditoría que se definan para Alimentación. | No crea, modifica, publica, abre, cierra, reabre ni confirma operaciones. |

### GoldenGtm móvil

El actor funcional es el `COLABORADOR`. La aplicación móvil autentica su
identidad corporativa y consume únicamente las capacidades que el backend le
autoriza para Alimentación.

| Actor | Capacidades autorizadas | Límites |
|---|---|---|
| `COLABORADOR` | Consultar publicaciones y menús disponibles; crear y cancelar sus propias reservas mientras la publicación esté abierta; consultar sus propias reservas; generar y mostrar su propio QR cuando cumpla las reglas aprobadas. | Solo actúa sobre información propia y sedes autorizadas. No recibe roles operativos de A&B ni permisos administrativos por autenticarse. |

`COLABORADOR` describe el perfil funcional del canal móvil. Su acceso efectivo
requiere que el backend confirme que la persona está registrada, activa y
autorizada para el módulo y las sedes correspondientes.

### Otros proyectos GTM

Cada proyecto define y administra sus propios roles, incluido su propio
`ROOT_ADMIN` cuando corresponda. Un rol de otro proyecto no concede permisos en
Alimentación. Si una persona participa en más de un proyecto, conserva una
asignación separada por contexto.

## Permisos funcionales canónicos

Los nombres de roles sirven para administración y experiencia de usuario. Las
operaciones del módulo deben protegerse con capacidades concretas equivalentes a
las siguientes:

| Permiso funcional | `ROOT_ADMIN` A&B | `GESTOR_ALIMENTACION` | `OPERADOR_ENTREGA` | `CONSULTA_AUDITORIA` | `COLABORADOR` |
|---|:---:|:---:|:---:|:---:|:---:|
| Gestionar planificación y publicación | Sí | Sí | No | No | No |
| Abrir, cerrar y reabrir reservas | Sí | Sí | No | No | No |
| Consultar cantidades consolidadas | Sí | Sí | No | Sí, si el reporte lo contempla | No |
| Gestionar una reserva propia | No | No | No | No | Sí |
| Consultar reservas propias | No | No | No | No | Sí |
| Generar y visualizar QR propio | No | No | No | No | Sí |
| Escanear y validar QR para entrega | Sí | No | Sí | No | No |
| Consultar detalle mínimo tras el escaneo | Sí | No | Sí | No | No |
| Confirmar entrega presencial normal | Sí | No | Sí | No | No |
| Consultar auditoría y reportes | Sí | No | No | Sí | No |

La matriz expresa el alcance funcional aprobado. Los identificadores técnicos de
permisos y su representación en contratos o persistencia se definirán en las
unidades técnicas correspondientes, sin cambiar estas capacidades.

## Consulta del colaborador durante el retiro

El detalle del colaborador solo se presenta al `OPERADOR_ENTREGA` o al
`ROOT_ADMIN` de la aplicación A&B como resultado de escanear un QR dentro del
flujo de entrega. No se habilita una consulta general o búsqueda de perfiles para
esta finalidad.

Cuando el QR sea válido para ser procesado, la respuesta puede mostrar
únicamente:

- nombre completo;
- fotografía, si está disponible;
- sede;
- tipo de servicio: desayuno, almuerzo o cena;
- fecha y menú reservado;
- estado de la reserva; y
- resultado de la validación del QR.

No se muestran correo, documento de identidad, cargo u otros datos personales
que no sean necesarios para verificar la entrega. El QR es opaco y no contiene
estos datos en texto legible.

El backend valida antes de devolver el detalle:

1. la identidad y sesión del operador;
2. el contexto de la aplicación A&B;
3. el permiso de validación o entrega;
4. el alcance de sede aplicable;
5. la validez y estado del QR; y
6. la reserva asociada.

La consulta y la posterior confirmación de entrega son operaciones distintas y
deben quedar auditadas según corresponda.

## Autenticación y fuentes de autorización

- La autenticación acredita quién es la persona; no concede por sí sola un rol
  funcional.
- Microsoft Entra en GoldenGtm móvil no convierte al colaborador en
  `ROOT_ADMIN` ni en operador de A&B.
- La aplicación A&B puede consumir los mecanismos corporativos que se aprueben
  para su proyecto, pero las opciones o roles recibidos deben mapearse dentro de
  su propio contexto.
- El backend no acepta como autoridad los roles construidos o enviados
  libremente por un cliente.
- Las validaciones visuales y guards del frontend complementan la experiencia,
  pero no reemplazan la autorización del backend.

## Respuestas de acceso

- Una identidad ausente, inválida o expirada se rechaza como no autenticada.
- Una identidad válida sin el permiso, contexto o sede requeridos se rechaza como
  no autorizada.
- Una respuesta de rechazo no revela roles internos, datos del colaborador,
  contenido del QR ni información sensible.
- Los eventos relevantes registran actor, aplicación, operación, resultado,
  fecha y correlación, sin registrar credenciales ni el contenido reutilizable
  del QR.

## Reconciliación de las fuentes

| Contenido histórico | Clasificación | Tratamiento oficial |
|---|---|---|
| Roles `ROOT_ADMIN`, `GESTOR_MENU`, `OPERADOR_ENTREGAS` y `CONSULTA` | Transformable | Se conservan las responsabilidades útiles, se renombran y delimitan por aplicación y capacidades. |
| `ROOT_ADMIN` como máxima autoridad | Transformable | Cada proyecto puede tener su propio `ROOT_ADMIN`; ninguno adquiere alcance transversal por compartir el nombre. |
| `GESTOR_MENU` limitado al menú diario | Transformable | Se reemplaza por `GESTOR_ALIMENTACION`, responsable del ciclo aprobado de planificación, publicación y apertura o cierre de reservas. |
| `OPERADOR_ENTREGAS` con entrega excepcional | Contradictorio | Se excluye la entrega excepcional. El rol solo valida QR y confirma entrega presencial normal. |
| Cualquier cuenta Android válida recibe `ROOT_ADMIN` | Contradictorio | Se excluye. Entra autentica la identidad móvil y el backend autoriza al colaborador. |
| Niveles numéricos `100`, `70`, `30` y `10` | Excluido como jerarquía transversal | No se utilizan para heredar autoridad entre proyectos. |
| Consulta de información del colaborador | Transformable | Se limita al resultado del escaneo de QR durante el retiro y a los campos mínimos aprobados. |
| Mapa de responsabilidades existente en el destino | Absorbible | Se conserva la separación entre web, móvil y backend, precisando los contextos de autorización. |

## Fuentes trazadas

- `Documentacion General de Alimentacioin/decisiones/REGISTRO_DECISIONES_APROBADAS.md`.
- `Documentacion General de Alimentacioin/Lineamiento/02_documento_funcional_tobe.md`.
- `Documentacion General de Alimentacioin/Lineamiento/03_arquitectura_software.md`.
- `GoldenGtm Movil/07 - Autenticación corporativa.md`.
- `GoldenGtm Movil/14 - Integración Microsoft Entra ID.md`.
- `GoldenGtm Movil/15 - Contrato mínimo backend autenticación.md`.
- `02_MAPA_DE_RESPONSABILIDADES.md`, evidencia histórica del destino.

Las rutas relativas de las dos primeras colecciones parten de
`C:\Users\cavalos\Desktop\Todo Documentaicon\Documentacion Alimentacion`.
Las fuentes permanecen intactas y no recuperan vigencia normativa por estar
citadas.

## Decisiones aprobadas

| Fecha | Decisión | Autoridad |
|---|---|---|
| 2026-09-03 | Se conserva `ROOT_ADMIN` y cada proyecto puede tener su propio rol con ese nombre, limitado a su contexto. | Usuario propietario de la documentación |
| 2026-09-03 | Se aprueban los roles de A&B y la separación de roles entre aplicaciones. | Usuario propietario de la documentación |
| 2026-09-03 | El detalle mínimo del colaborador solo se consulta durante el retiro como resultado del escaneo de QR. | Usuario propietario de la documentación |
| 2026-09-03 | Se aprueba la clasificación y tratamiento documental de esta unidad. | Usuario propietario de la documentación |
| 2026-09-03 | El detalle posterior al escaneo incorpora el tipo de servicio reservado, sin ampliar el acceso a otros datos del colaborador. | Usuario propietario de la documentación |

## Límites de esta oficialización

Este documento no crea roles en una base de datos, no define tablas o claims, no
modifica LoginAD o Microsoft Entra, no establece identificadores técnicos
definitivos y no autoriza implementación. Esos detalles deberán respetar este
lineamiento cuando sean revisados en contratos, referencias técnicas y diseño de
datos.
