# Evaluaciones — contexto y alcance

Estado: Oficial  
Fecha de oficialización: 2026-09-03

## Objetivo

El módulo Evaluaciones permite configurar el contenido de las evaluaciones, administrar sus períodos, consultar reportes y ejecutar las evaluaciones asignadas.

## Capacidades incluidas

- Banco de competencias, criterios y preguntas.
- Formatos o evaluaciones que utilizan el banco de preguntas.
- Períodos de evaluación y sus estados.
- Reportes y seguimiento de progreso.
- Flujo Mis Evaluaciones.
- Autorización por roles y permisos.
- Integración mediante servicios REST oficiales.
- Diseño e interacciones representados por mocks aprobados.

## Actores

- Administrador de Recursos Humanos: administra preguntas, períodos y reportes.
- Evaluador de Recursos Humanos: ejecuta las evaluaciones asignadas.
- Superadministrador y superusuario: acceden según la matriz oficial del módulo.

## Límite documental

Este lineamiento define qué debe hacer el módulo. La arquitectura Angular, sus librerías y su estructura general pertenecen al estándar del agente frontend. La implementación futura debe consumir el contrato REST y respetar el diseño aprobados sin redefinir las reglas funcionales.

## Origen

- `00_INDICE_Y_SECUENCIA_AGENTE.md`
- `01_FRONTEND.md`

Ambas fuentes permanecen intactas en la documentación histórica de Evaluaciones.
