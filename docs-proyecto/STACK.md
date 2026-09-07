# Stack confirmado — núcleo general de datos GTM

## Estado del checkpoint

- Fuente: decisión expresa del usuario incorporada en
  `lineamiento/00_DECISIONES_NUCLEO_RRHH.md`.
- Estado del artefacto: **aprobado por el usuario el 2026-09-04**, conjuntamente
  con el modelo conceptual v1.
- Preguntas materiales: diferidas expresamente antes de cualquier futuro diseño
  físico.
- Límite de la aprobación: el usuario indicó **no iniciar el DB Agent**. Tampoco
  autoriza SQL, DDL, migraciones ni ejecución contra un motor real.

## Componentes confirmados

| Componente | Decisión confirmada | Alcance en esta etapa |
|---|---|---|
| Base de datos | Microsoft SQL Server 2017 | Solo registro del motor; sin conexión ni diseño físico. |
| Backend existente | NestJS con TypeScript en `hub-gtm` | Consumidor futuro; no se diseña ni modifica. |
| Web existente | Angular en `front-gtm` | Consumidor futuro; no se instancia Frontend Agent. |
| Móvil existente | Kotlin y Jetpack Compose en `AppMovilGoldenGtm` | Consumidor futuro; no se instancia Frontend Agent. |
| Contrato de API | REST documentado mediante OpenAPI | Paradigma confirmado; no se publica ni modifica contrato ahora. |
| Arquitectura | Monolito modular | El núcleo y los módulos mantienen límites lógicos dentro de la plataforma. |
| Zona de negocio | `America/Lima` | Referencia funcional para vigencias y reglas temporales. |

## Topología conceptual confirmada

- Una base GTM común para las empresas de la corporación.
- Empresa explícita en cada relación laboral.
- Límites lógicos diferenciados para núcleo común, Alimentación, Evaluaciones y
  módulos futuros.
- Una eventual separación como microservicio o base independiente requiere una
  decisión posterior expresa; no se infiere del uso de una base nueva.
- SQL Server será la autoridad temporal persistente cuando se implemente, sin
  que esta definición seleccione todavía funciones, tipos o estrategia física.

## Integraciones y límites

- **Seguridad externa**: enlace mediante API con el código estable de
  Colaborador; sin tablas de usuario, roles o permisos en GTM y sin claves
  foráneas entre bases.
- **Microsoft/Entra**: provee la cuenta corporativa básica obligatoria de cada
  Colaborador y acredita identidad; no concede autorización funcional.
- **SAP**: sistema externo de referencia para códigos de empleado,
  cargo/posición, centro de costo y horario. GTM conserva maestros propios de
  Cargo y Área.
- **Marcaciones**: permanecen en otra base y no se duplican en el núcleo.
- **Datos operativos de A&B**: permanecen en su base externa y no ingresan al
  núcleo.
- **Clientes web y móvil**: acceden únicamente por el backend y nunca de forma
  directa a SQL Server.

## Plataformas aplicables

La etapa actual no requiere frontend. Web Angular y móvil Android con
Kotlin/Compose quedan registrados porque el usuario confirmó los consumidores
existentes de la plataforma general. Desktop no fue requerido. iOS permanece
como evolución planificada exclusiva del contexto de Alimentación y no forma
parte de esta ejecución.

## Decisiones deliberadamente no tomadas

Este `STACK.md` no selecciona:

- nombre físico de base de datos o schemas;
- ORM, driver o patrón físico de persistencia;
- herramienta de migraciones;
- tipos de datos, claves, índices, particiones o `hierarchyid`;
- estrategia de alta disponibilidad, respaldo o despliegue;
- mecanismo de sincronización con SAP;
- estructura interna de backend o frontend; ni
- tecnología de notificaciones o integración con marcaciones.

Las decisiones materiales de dominio pendientes se encuentran en
`requirements.md`, sección 13.
