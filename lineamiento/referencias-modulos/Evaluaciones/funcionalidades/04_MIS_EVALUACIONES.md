# Funcionalidad — Mis Evaluaciones

Estado: Oficial  
Fecha de oficialización: 2026-09-03

## Flujo

1. Mostrar los períodos en los que participa el evaluador autenticado.
2. Mostrar para cada período el título del formato, título del período, estado y fecha de vencimiento.
3. Mostrar el personal asignado, agrupado por cargo, dentro del período seleccionado.
4. Permitir expandir o contraer cada grupo de cargo.
5. Abrir la evaluación de una persona asignada.
6. Mostrar las preguntas agrupadas por competencia.
7. Mostrar la descripción de la competencia y opciones Likert con nombres descriptivos.
8. Permitir responder y guardar el avance de cada competencia.
9. Registrar la actividad necesaria para la trazabilidad de tiempos.
10. Mostrar al evaluador el tiempo empleado en la persona y en cada competencia.

## Reglas

- El flujo opera sobre el snapshot del período publicado.
- El progreso se calcula como `PreguntasRespondidas / TotalPreguntas`.
- Una competencia guardada queda bloqueada.
- Todas las preguntas de la competencia actual deben responderse antes de avanzar a la siguiente.
- Al avanzar de competencia se guarda el progreso y se limpia la selección temporal de la competencia anterior.
- El estado de navegación permite recuperar el flujo al recargar o regresar a la pantalla anterior.
- Una persona nunca se agrega ni se elimina del snapshot después de la publicación.
- Retirar una persona deshabilita su asignación para el evaluador actual y deja de mostrarla en su lista.
- La persona deshabilitada permanece en el snapshot y puede asignarse a otro evaluador.
- Cada relación evaluador/evaluado constituye una evaluación separada.
- Distintas personas pueden ocupar el mismo cargo evaluador.
- Los estados de asignación o progreso son `PENDIENTE`, `EN_PROGRESO` y `COMPLETADO`.
- La medición de tiempo soporta evaluaciones continuadas en días distintos.

## Operaciones REST confirmadas

- Listar períodos del evaluador.
- Listar el personal asignado.
- Consultar personas disponibles.
- Asignar a un evaluador una persona que ya existe en el snapshot.
- Deshabilitar la asignación de una persona para el evaluador actual.
- Obtener la evaluación de una persona.
- Registrar actividad.
- Guardar el avance por competencia.

Las operaciones de asignación modifican la relación con el evaluador, no la composición del snapshot publicado.

## Origen

- `01_FRONTEND.md`, sección “Mis Evaluaciones”.
- `02_BACKEND.md`, secciones “Endpoints actuales” y “Mis Evaluaciones”.
- `FUENTE_HISTORICA/CONTEXTO_PROYECTO_GTM.md`, sección “Mis Evaluaciones”.
