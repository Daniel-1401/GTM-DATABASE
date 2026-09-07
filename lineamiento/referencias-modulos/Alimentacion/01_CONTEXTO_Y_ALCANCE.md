# Alimentación — contexto y alcance

Estado: Oficial  
Responsable de aprobación: Usuario propietario de la documentación  
Fecha de oficialización: 2026-09-03

## Objetivo

El módulo Alimentación integra la publicación de la planificación alimentaria,
la reserva de los colaboradores y el control de la entrega presencial. Su
objetivo es que el área de Alimentos y Bebidas (A&B) conozca cuántas personas han
reservado y utilice esa cantidad como insumo para su planificación operativa por
el canal correspondiente.

El módulo no administra las compras, el inventario de insumos, las recetas ni
los costos. Entrega a A&B la información consolidable de reservas necesaria para
que esas actividades se realicen fuera de esta aplicación.

## Problema que resuelve

A&B necesita publicar una planificación disponible para reserva y conocer la
cantidad vigente de colaboradores que participarán. El colaborador necesita
consultar la planificación publicada, registrar o cancelar su reserva mientras
la publicación lo permita y acreditar su reserva durante el retiro presencial.

El sistema debe mantener una única interpretación de las reglas entre web,
móvil, backend y persistencia, y debe conservar trazabilidad de las acciones que
cambian reservas, publicaciones, QR y entregas.

## Alcance general

El módulo comprende:

- Publicación de la planificación alimentaria por un usuario autorizado de A&B.
- Publicación diferenciada de desayuno, almuerzo y cena por fecha y sede.
- Apertura, cierre y reapertura del período de reservas asociado con una
  publicación.
- Consulta de publicaciones habilitadas por parte del colaborador.
- Creación, cancelación y consulta de las reservas propias.
- Obtención por A&B de la cantidad de personas reservadas para su planificación
  externa.
- Experiencia móvil del colaborador, incluida la proximidad BLE y la presentación
  protegida del QR para el retiro.
- Operación web para las tareas administrativas y de entrega presencial que se
  definan en los documentos funcionales.
- Backend compartido como autoridad de autorización, reglas, estados y
  consistencia transaccional.
- Persistencia futura en SQL Server para la información funcional, configuración
  operativa y auditoría aprobadas.
- Identidad corporativa, autorización, seguridad, reportes, pruebas y
  trazabilidad del módulo.

## Colaborador y tipo de servicio

El colaborador es una entidad central de GTM compartida por Alimentación,
Evaluaciones y otros módulos. Los datos personales y el horario laboral se
gobiernan en ese núcleo común; Alimentación los consume mediante el backend y no
mantiene una identidad, perfil u horario paralelos.

Los servicios alimentarios oficiales son `DESAYUNO`, `ALMUERZO` y `CENA`. Para
cada fecha, el backend determina un único servicio habilitado según el horario
del colaborador y la configuración vigente. El colaborador no elige libremente
entre los tres servicios.

Los límites exactos que relacionan horarios laborales con tipos de servicio se
administran manualmente en base de datos y fuera de las aplicaciones. Su modelo
físico se definirá en el ciclo específico de diseño de datos.

## Ciclo funcional de publicación y reservas

1. Un usuario autorizado de A&B prepara y publica la planificación.
2. A&B habilita la publicación para recibir reservas.
3. Mientras la publicación se encuentre abierta, los colaboradores pueden crear
   o cancelar sus reservas.
4. A&B cierra la publicación cuando necesita consolidar la cantidad de personas
   reservadas.
5. Mientras la publicación permanezca cerrada, no se aceptan nuevas reservas ni
   cancelaciones.
6. A&B puede reabrir la publicación; al hacerlo, vuelven a habilitarse las
   reservas y cancelaciones.
7. Un cierre posterior permite obtener nuevamente la cantidad vigente de
   personas reservadas.

No existe un número máximo de reservas ni una competencia por cupos. El estado
abierto o cerrado de la publicación, y no la disponibilidad de capacidad,
determina si se puede reservar o cancelar.

El control manual de apertura y cierre sustituye completamente el corte fijo de
las `23:59:59` del día anterior que aparecía en documentación histórica. No se
mantiene un corte horario paralelo. La fecha y hora oficial obtenida desde SQL
Server se conserva para registrar y auditar las transiciones, no para aplicar
ese límite eliminado.

## Canales y responsabilidades generales

| Canal o componente | Responsabilidad dentro del alcance |
|---|---|
| Web | Permitir al personal autorizado de A&B publicar, abrir, cerrar, reabrir y consultar la planificación y sus reservas; soportar la operación presencial aprobada. |
| Aplicación móvil | Permitir al colaborador autenticado consultar el servicio que corresponda a su horario, reservar, cancelar, revisar sus estados y presentar el QR bajo las reglas aprobadas. |
| Backend | Autorizar actores, consumir el contexto central del colaborador, determinar el servicio aplicable, validar reservas, administrar QR y entrega, coordinar persistencia y exponer el contrato común. |
| SQL Server | Conservar el estado y la trazabilidad del módulo y proporcionar el instante oficial para los registros y reglas temporales que permanezcan vigentes. |
| Integraciones | Acreditar identidad, aportar la señal física BLE o participar en otros límites expresamente aprobados. |

Android es la plataforma móvil de la primera etapa. iOS es una evolución
planificada con paridad funcional y debe consumir las mismas reglas y el mismo
contrato general cuando se autorice su implementación.

## Actores conceptuales

| Actor | Participación |
|---|---|
| Colaborador | Consulta publicaciones y gestiona únicamente sus propias reservas; presenta el QR para el retiro. |
| Usuario de A&B | Prepara y publica la planificación, controla la apertura y cierre de reservas y consulta la cantidad consolidable. |
| Operador de entrega | Valida el retiro presencial normal mediante el flujo aprobado. |
| Responsable del producto | Aprueba alcance, reglas, contrato y cambios materiales. |
| Sistemas e integraciones | Proporcionan capacidades externas sin convertirse por ello en autoridad funcional del módulo. |

Los nombres técnicos de roles y su matriz de permisos se definen exclusivamente
en `02_ROLES_Y_PERMISOS.md` después de su análisis y aprobación.

## Configuración operativa fuera de la aplicación

La configuración de sedes, ventanas de retiro, beacons y otros valores
operativos no tendrá un gestor web en el alcance actual. Será gestionada fuera de
la aplicación, con una propuesta inicial de administración manual desde la base
de datos.

Esta definición confirma la ausencia de una interfaz funcional para mantener
esos valores. No aprueba tablas, columnas, procedimientos, accesos ni un método
físico de actualización; esos elementos requieren diseño y aprobación técnica
posterior.

## Fuera de alcance

Las siguientes capacidades son atendidas por otros canales y no forman parte del
módulo Alimentación:

- Compras y abastecimiento.
- Inventario de insumos.
- Recetas y producción de cocina.
- Costos, pagos y facturación.
- Nutrición, dietas y alergias.
- Invitados y múltiples raciones por persona.
- Analítica avanzada y pronóstico de demanda.
- Lista de espera o asignación por cupos.
- Administración del tenant, usuarios o credenciales de Microsoft Entra.
- Integración con SAP.
- Seguimiento continuo de personas o cálculo de distancia exacta mediante BLE.
- Entrega fuera del flujo presencial normal y entrega excepcional.
- Confirmación de entrega sin conexión al backend.
- Módulos de GTM distintos de Alimentación, incluido Evaluaciones.

El uso externo del conteo de reservas para compras, inventario, recetas o costos
no incorpora esas funciones al módulo ni establece por sí mismo una integración
automática con sus canales.

## Límites documentales y técnicos

Este documento define alcance funcional general. No define:

- rutas, métodos ni esquemas definitivos de API;
- nombres físicos de tablas, columnas, índices o stored procedures;
- arquitectura interna de las aplicaciones;
- credenciales, conexiones o procedimientos de despliegue;
- valores operativos reales de beacons; ni
- autorización para implementar, ejecutar SQL o promover ambientes.

Esos elementos solo podrán incorporarse en sus documentos especializados y
mediante sus checkpoints correspondientes.

## Origen y tratamiento

Este documento absorbe y transforma contenido de:

- `01_ALCANCE_Y_DECISIONES_GENERALES.md` del destino, conservado como evidencia
  histórica después de completar su distribución.
- `Documentacion General de Alimentacioin/Lineamiento/01_analisis_proyecto.md`.
- `Documentacion General de Alimentacioin/Lineamiento/02_documento_funcional_tobe.md`.
- `Documentacion General de Alimentacioin/decisiones/REGISTRO_DECISIONES_APROBADAS.md`.
- `GoldenGtm Movil/01 - Visión y alcance del módulo Almuerzo.md`.

Las fuentes históricas permanecen sin modificaciones. Las reglas de cupo y corte
fijo que resultan contradictorias con las decisiones actuales no se promueven.

## Historial de cambios

| Fecha | Cambio | Aprobado por |
|---|---|---|
| 2026-09-03 | Creación y oficialización del contexto y alcance general de Alimentación. | Usuario propietario de la documentación |
| 2026-09-03 | Se confirma que no existe cupo máximo y que la cantidad reservada sirve como insumo para la planificación externa de A&B. | Usuario propietario de la documentación |
| 2026-09-03 | A&B controla apertura, cierre y reapertura; se elimina completamente el corte fijo de `23:59:59`. | Usuario propietario de la documentación |
| 2026-09-03 | La configuración operativa se gestiona fuera de la aplicación y las capacidades de compras, inventario, recetas y costos permanecen en otros canales. | Usuario propietario de la documentación |
| 2026-09-03 | El colaborador se reconoce como entidad central de GTM y su horario determina un único servicio entre desayuno, almuerzo y cena mediante configuración externa. | Usuario propietario de la documentación |
