# Evaluaciones — índice y gobierno funcional

Estado: Oficial  
Responsable de aprobación: Usuario propietario de la documentación  
Fecha de oficialización: 2026-09-03

## Propósito

Esta carpeta es la fuente oficial de lineamientos funcionales del módulo Evaluaciones de GTM. Su contenido describe comportamientos, reglas de negocio, actores, permisos y resultados esperados del módulo, sin fijar decisiones de implementación.

## Alcance funcional

El módulo comprende:

- Banco de preguntas.
- Gestión de períodos de evaluación.
- Reportes y seguimiento.
- Flujo Mis Evaluaciones para el evaluador.
- Reglas de acceso asociadas con las funciones del módulo.
- Servicios REST y contratos de integración aprobados para el módulo.
- Mocks aprobados como referencia del diseño y comportamiento esperado.
- Línea base técnica de SQL Server, conservada para su evolución manual.

## Documentos oficiales

- [Contexto y alcance](01_CONTEXTO_Y_ALCANCE.md)
- [Roles y permisos](02_ROLES_Y_PERMISOS.md)
- [Banco de preguntas](funcionalidades/01_BANCO_DE_PREGUNTAS.md)
- [Formatos de evaluación](funcionalidades/02_FORMATOS_DE_EVALUACION.md)
- [Períodos](funcionalidades/03_PERIODOS.md)
- [Mis Evaluaciones](funcionalidades/04_MIS_EVALUACIONES.md)
- [Reportes](funcionalidades/05_REPORTES.md)
- [UX/UI y mocks](ux/UX_UI_Y_MOCKS.md)
- [Servicios REST](contratos/API_REST.md)
- [Línea base SQL Server](referencias-tecnicas/SQL_SERVER_BASELINE.md)
- [Línea base frontend y backend](referencias-tecnicas/FRONTEND_BACKEND_BASELINE.md)
- [Plan técnico histórico de períodos](referencias-tecnicas/PLAN_TECNICO_PERIODOS_HISTORICO.md)
- [Criterios de aceptación y pruebas](calidad/CRITERIOS_ACEPTACION_Y_PRUEBAS.md)
- [Matriz de trazabilidad](gobierno/MATRIZ_TRAZABILIDAD.md)
- [Historial de decisiones](gobierno/HISTORIAL_DECISIONES.md)
- [Auditoría final del traslado](gobierno/AUDITORIA_FINAL.md)

## Reglas funcionales confirmadas

- Crear un período no lo publica.
- Todo período recién creado queda en estado `STAGE`.
- Publicar un período genera su snapshot.
- Generar un PDF bajo demanda no publica el período.
- En estado `STAGE`, el PDF utiliza la configuración vigente.
- En estado `PUBLICADO`, el PDF utiliza el snapshot.
- Un período publicado no puede publicarse nuevamente.
- Un período publicado solo puede anularse cuando sus reglas de estado lo permitan.
- El estado `FINALIZADO` se alcanza automáticamente cuando todas las asignaciones activas han sido completadas.
- El acceso al módulo requiere una sesión autenticada.
- Las funciones internas de Evaluaciones están restringidas por roles y permisos.

## Contenido excluido

No forman parte de estos lineamientos funcionales:

- Frameworks, librerías o estructura física del frontend y backend.
- Rutas de archivos, comandos de compilación y procedimientos Git.
- Clases, componentes, interceptores, DTO internos y otros detalles de implementación.
- Configuraciones locales y riesgos exclusivos de una implementación anterior.

La estructura SQL heredada se conserva en una referencia técnica separada para que pueda evolucionar de forma controlada sin mezclarla con las reglas funcionales.

## Trazabilidad de origen

Este documento absorbe y transforma únicamente el contenido funcional de:

- `C:\Users\cavalos\Desktop\Todo Documentaicon\Documentacion Evaluaciones\00_INDICE_Y_SECUENCIA_AGENTE.md`

La fuente original permanece sin modificaciones como evidencia histórica.

## Historial de cambios

| Fecha | Cambio | Aprobado por |
|---|---|---|
| 2026-09-03 | Creación del índice oficial del módulo y separación entre lineamiento funcional y decisiones técnicas históricas. | Usuario propietario de la documentación |
| 2026-09-03 | Se reconocen como oficiales los servicios REST y los mocks aprobados del diseño del módulo. | Usuario propietario de la documentación |
| 2026-09-03 | Reorganización por alcance, funcionalidades, UX, contratos, calidad y gobierno documental. | Usuario propietario de la documentación |
| 2026-09-03 | Oficialización de los endpoints REST sin requerir autenticación o autorización mediante tokens. | Usuario propietario de la documentación |
| 2026-09-03 | Incorporación de la línea base SQL Server y precisión de la reasignación de personal sin modificar el snapshot. | Usuario propietario de la documentación |
| 2026-09-03 | Incorporación de reglas detalladas de formatos, Mis Evaluaciones y línea base técnica frontend/backend. | Usuario propietario de la documentación |
| 2026-09-03 | Incorporación del plan de períodos, contrato detallado, 31 casos de validación y cierre de auditoría documental. | Usuario propietario de la documentación |
